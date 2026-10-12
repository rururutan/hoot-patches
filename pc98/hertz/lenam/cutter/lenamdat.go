package main

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

const entrySize = 18

type entry struct {
	name   string
	offset uint32
}

func readAll(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open %q: %w", path, err)
	}
	info, err := f.Stat()
	if err != nil {
		_ = f.Close()
		return nil, fmt.Errorf("stat %q: %w", path, err)
	}
	if !info.Mode().IsRegular() {
		_ = f.Close()
		return nil, fmt.Errorf("%q is not a regular file", path)
	}
	data, readErr := io.ReadAll(f)
	closeErr := f.Close()
	if readErr != nil {
		return nil, fmt.Errorf("read %q: %w", path, readErr)
	}
	if closeErr != nil {
		return nil, fmt.Errorf("close %q: %w", path, closeErr)
	}
	return data, nil
}

func parse(data []byte) ([]entry, error) {
	if len(data) < entrySize {
		return nil, errors.New("DATA is shorter than one directory entry")
	}
	directorySize := binary.LittleEndian.Uint32(data[14:18])
	if directorySize == 0 || directorySize%entrySize != 0 || uint64(directorySize) > uint64(len(data)) {
		return nil, fmt.Errorf("invalid directory size %#x", directorySize)
	}
	entries := make([]entry, 0, directorySize/entrySize)
	for pos := uint32(0); pos < directorySize; pos += entrySize {
		rawName := data[pos : pos+14]
		if rawName[0] == 0 {
			break
		}
		end := 0
		for end < len(rawName) && rawName[end] != 0 {
			end++
		}
		name := string(rawName[:end])
		if name == "" || name == "." || name == ".." || filepath.Base(name) != name || strings.ContainsAny(name, `/\\`) {
			return nil, fmt.Errorf("unsafe filename %q at directory offset %#x", name, pos)
		}
		offset := binary.LittleEndian.Uint32(data[pos+14 : pos+18])
		if offset < directorySize || uint64(offset) > uint64(len(data)) {
			return nil, fmt.Errorf("invalid offset %#x for %q", offset, name)
		}
		if len(entries) != 0 && offset < entries[len(entries)-1].offset {
			return nil, fmt.Errorf("offset for %q is before the preceding file", name)
		}
		entries = append(entries, entry{name: name, offset: offset})
	}
	if len(entries) == 0 {
		return nil, errors.New("DATA contains no files")
	}
	return entries, nil
}

func writeAll(path string, data []byte) error {
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("open output %q: %w", path, err)
	}
	written := 0
	for written < len(data) {
		n, writeErr := f.Write(data[written:])
		written += n
		if writeErr != nil {
			_ = f.Close()
			return fmt.Errorf("write output %q after %d of %d bytes: %w", path, written, len(data), writeErr)
		}
		if n == 0 {
			_ = f.Close()
			return fmt.Errorf("write output %q stopped after %d of %d bytes", path, written, len(data))
		}
	}
	if err := f.Sync(); err != nil {
		_ = f.Close()
		return fmt.Errorf("flush output %q: %w", path, err)
	}
	if err := f.Close(); err != nil {
		return fmt.Errorf("close output %q: %w", path, err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("verify output %q: %w", path, err)
	}
	if info.Size() != int64(len(data)) {
		return fmt.Errorf("verify output %q: expected %d bytes, got %d", path, len(data), info.Size())
	}
	return nil
}

func run(input, outputDir string) error {
	data, err := readAll(input)
	if err != nil {
		return err
	}
	entries, err := parse(data)
	if err != nil {
		return fmt.Errorf("parse %q: %w", input, err)
	}
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return fmt.Errorf("create output directory %q: %w", outputDir, err)
	}
	for i, item := range entries {
		end := uint32(len(data))
		if i+1 < len(entries) {
			end = entries[i+1].offset
		}
		if end < item.offset {
			return fmt.Errorf("negative size for %q", item.name)
		}
		path := filepath.Join(outputDir, item.name)
		if err := writeAll(path, data[item.offset:end]); err != nil {
			return err
		}
		fmt.Printf("%s (%d bytes)\n", path, end-item.offset)
	}
	return nil
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: lenamdat DATA output_directory")
		os.Exit(2)
	}
	if err := run(os.Args[1], os.Args[2]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
