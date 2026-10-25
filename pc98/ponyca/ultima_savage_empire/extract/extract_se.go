// Extract PC-9801 Ultima: The Savage Empire LZX/LZC archives.
// Build: go build -trimpath -ldflags="-s -w" -o extract_se.exe extract_se.go
package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// LZW payload: identical code packing to Ultima VI, verified against SAVAGE.EXE.
func decompress(data []byte) ([]byte, error) {
	if len(data) < 6 {
		return nil, fmt.Errorf("truncated header/stream")
	}
	size := binary.LittleEndian.Uint32(data)
	if size > 16*1024*1024 {
		return nil, fmt.Errorf("unreasonable output size: %d", size)
	}
	var table [4096][]byte
	for i := 0; i < 256; i++ {
		table[i] = []byte{byte(i)}
	}
	output := make([]byte, 0, int(size))
	var previous []byte
	width, next := uint(9), 258
	var buffer uint32
	var available uint
	position := 4
	for {
		for available < width {
			if position == len(data) {
				return nil, fmt.Errorf("missing end code")
			}
			buffer |= uint32(data[position]) << available
			available += 8
			position++
		}
		code := int(buffer & ((1 << width) - 1))
		buffer >>= width
		available -= width
		switch code {
		case 256:
			width, next, previous = 9, 258, nil
			continue
		case 257:
			if len(output) != int(size) {
				return nil, fmt.Errorf("size mismatch: %d != %d", len(output), size)
			}
			return output, nil
		}
		var entry []byte
		switch {
		case previous == nil:
			if code > 255 {
				return nil, fmt.Errorf("expected literal after reset")
			}
			entry = table[code]
		case code < next:
			entry = table[code]
		case code == next && next < len(table):
			entry = append(append([]byte(nil), previous...), previous[0])
		default:
			return nil, fmt.Errorf("invalid dictionary reference: %d", code)
		}
		if len(entry) == 0 {
			return nil, fmt.Errorf("reserved dictionary code")
		}
		if len(entry) > int(size)-len(output) {
			return nil, fmt.Errorf("output exceeds declared size")
		}
		output = append(output, entry...)
		if previous != nil {
			if next >= len(table) {
				return nil, fmt.Errorf("dictionary overflow without reset")
			}
			table[next] = append(append([]byte(nil), previous...), entry[0])
			next++
			if width < 12 && next == 1<<width {
				width++
			}
		}
		previous = entry
	}
}

type member struct {
	Index int
	Kind  byte
	Data  []byte
}

// Archive table: LE size, then 24-bit offsets with an 8-bit storage type.
func unpack(data []byte) ([]member, error) {
	if len(data) < 8 || uint64(binary.LittleEndian.Uint32(data)) != uint64(len(data)) {
		return nil, fmt.Errorf("invalid archive size")
	}
	first := int(binary.LittleEndian.Uint32(data[4:]) & 0xffffff)
	if first < 8 || first > len(data) || first%4 != 0 {
		return nil, fmt.Errorf("invalid offset table")
	}
	count := first/4 - 1
	result := make([]member, 0, count)
	for i := 0; i < count; i++ {
		value := binary.LittleEndian.Uint32(data[4+i*4:])
		start, end := int(value&0xffffff), len(data)
		kind := byte(value >> 24)
		if i+1 < count {
			end = int(binary.LittleEndian.Uint32(data[8+i*4:]) & 0xffffff)
		}
		if start < first || start > end || end > len(data) {
			return nil, fmt.Errorf("entry %d: invalid range", i)
		}
		payload := data[start:end]
		switch kind {
		case 1:
			var err error
			payload, err = decompress(payload)
			if err != nil {
				return nil, fmt.Errorf("entry %d: %w", i, err)
			}
		case 2:
			// Stored without compression.
		case 255:
			if start != end {
				return nil, fmt.Errorf("entry %d: nonempty absent entry", i)
			}
			continue
		default:
			return nil, fmt.Errorf("entry %d: unknown storage type %02x", i, kind)
		}
		result = append(result, member{i, kind, payload})
	}
	return result, nil
}

func extract(source, destination string) error {
	info, err := os.Stat(source)
	if err != nil {
		return err
	}
	files := []string{source}
	if info.IsDir() {
		entries, err := os.ReadDir(source)
		if err != nil {
			return err
		}
		files = nil
		for _, entry := range entries {
			ext := strings.ToUpper(filepath.Ext(entry.Name()))
			if !entry.IsDir() && (ext == ".LZX" || ext == ".LZC") {
				files = append(files, filepath.Join(source, entry.Name()))
			}
		}
	}
	if len(files) == 0 {
		return fmt.Errorf("no LZX/LZC archives found")
	}
	type archive struct {
		path    string
		members []member
	}
	var archives []archive
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			return err
		}
		members, err := unpack(data)
		if err != nil {
			return fmt.Errorf("%s: %w", file, err)
		}
		archives = append(archives, archive{file, members})
	}
	for _, archive := range archives {
		// Preserve the extension to keep MUSIC.LZX and MUSIC.LZC separate.
		directory := filepath.Join(destination, filepath.Base(archive.path))
		if err := os.MkdirAll(directory, 0755); err != nil {
			return err
		}
		for _, member := range archive.members {
			target := filepath.Join(directory, fmt.Sprintf("%03d.bin", member.Index))
			if err := os.WriteFile(target, member.Data, 0644); err != nil {
				return err
			}
			fmt.Printf("%s/%03d.bin: %d bytes\n", filepath.Base(archive.path), member.Index, len(member.Data))
		}
	}
	return nil
}

func main() {
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "Usage: extract_se <archive.LZX | archive.LZC | directory> <output-directory>\nOutputs <archive-name>/<zero-based-index>.bin; existing outputs are overwritten.")
	}
	flag.Parse()
	if flag.NArg() != 2 {
		flag.Usage()
		os.Exit(2)
	}
	if err := extract(flag.Arg(0), flag.Arg(1)); err != nil {
		fmt.Fprintln(os.Stderr, "extract_se:", err)
		os.Exit(1)
	}
}
