// Expand X68000 Ultima VI .M files using the _END.X $52aa LZW format.
// Build: go build -trimpath -ldflags="-s -w" -o extract_u6.exe extract_u6.go
package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

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
			if !entry.IsDir() && strings.EqualFold(filepath.Ext(entry.Name()), ".M") {
				files = append(files, filepath.Join(source, entry.Name()))
			}
		}
	}
	if len(files) == 0 {
		return fmt.Errorf("no .M files found in %s", source)
	}
	// Validate all inputs before writing any output.
	type result struct {
		source, target string
		compressed     int
		data           []byte
	}
	var results []result
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			return err
		}
		decoded, err := decompress(data)
		if err != nil {
			return fmt.Errorf("%s: %w", file, err)
		}
		name := strings.TrimSuffix(filepath.Base(file), filepath.Ext(file)) + ".bin"
		target := filepath.Join(destination, name)
		if existing, err := os.Stat(target); err == nil {
			original, err := os.Stat(file)
			if err != nil {
				return err
			}
			if os.SameFile(original, existing) {
				return fmt.Errorf("source and destination must differ: %s", file)
			}
		}
		results = append(results, result{file, target, len(data), decoded})
	}
	if err := os.MkdirAll(destination, 0755); err != nil {
		return err
	}
	for _, result := range results {
		if err := os.WriteFile(result.target, result.data, 0644); err != nil {
			return err
		}
		fmt.Printf("%s: %d -> %d\n", filepath.Base(result.source), result.compressed, len(result.data))
	}
	return nil
}

func main() {
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "Usage: extract_u6 <file.M | directory> <output-directory>\nExpand X68000 Ultima VI music to <name>.bin. Existing outputs are overwritten.")
	}
	flag.Parse()
	if flag.NArg() != 2 {
		flag.Usage()
		os.Exit(2)
	}
	if err := extract(flag.Arg(0), flag.Arg(1)); err != nil {
		fmt.Fprintln(os.Stderr, "extract_u6:", err)
		os.Exit(1)
	}
}
