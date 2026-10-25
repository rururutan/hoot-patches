// Extract Black Thorn (PC-9801) compressed music. Standard library only.
package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// BT256.EXE load-image offset 0464h: zero-filled 4KB ring, LSB-first flags,
// absolute 12-bit ring index and 4-bit length minus 3. No end marker.
func decompress(data []byte) ([]byte, error) {
	if len(data) < 4 {
		return nil, fmt.Errorf("truncated header")
	}
	header := binary.LittleEndian.Uint32(data)
	if header&0x40000000 == 0 {
		return nil, fmt.Errorf("missing compression flag")
	}
	size := header & 0xbfffffff
	if size == 0 || size > 16*1024*1024 {
		return nil, fmt.Errorf("unsupported output size: %d", size)
	}
	output := make([]byte, 0, int(size))
	var ring [4096]byte
	write, pos := 0, 4
	emit := func(v byte) { output = append(output, v); ring[write] = v; write = (write + 1) & 4095 }
	for len(output) < int(size) {
		if pos >= len(data) {
			return nil, fmt.Errorf("truncated flags")
		}
		flags := data[pos]
		pos++
		for bit := uint(0); bit < 8 && len(output) < int(size); bit++ {
			if flags&(1<<bit) != 0 {
				if pos >= len(data) {
					return nil, fmt.Errorf("truncated literal")
				}
				emit(data[pos])
				pos++
			} else {
				if pos+2 > len(data) {
					return nil, fmt.Errorf("truncated reference")
				}
				token := int(binary.LittleEndian.Uint16(data[pos:]))
				pos += 2
				for j := 0; j < (token>>12)+3 && len(output) < int(size); j++ {
					emit(ring[(token+j)&4095])
				}
			}
		}
	}
	if pos != len(data) {
		return nil, fmt.Errorf("unexpected trailing bytes: %d", len(data)-pos)
	}
	return output, nil
}

type result struct {
	name string
	data []byte
}

func run(input, output string) error {
	info, err := os.Stat(input)
	if err != nil {
		return err
	}
	paths := []string{input}
	if info.IsDir() {
		paths = nil
		entries, err := os.ReadDir(input)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			ext := strings.ToUpper(filepath.Ext(entry.Name()))
			if !entry.IsDir() && (ext == ".MSF" || ext == ".SSG" || ext == ".OPN") {
				paths = append(paths, filepath.Join(input, entry.Name()))
			}
		}
	}
	if len(paths) == 0 {
		return fmt.Errorf("no MSF/SSG/OPN files found")
	}
	var results []result
	// Validate the entire batch before writing. Never overwrite a source file.
	for _, path := range paths {
		destination := filepath.Join(output, filepath.Base(path))
		src, err := os.Stat(path)
		if err != nil {
			return err
		}
		if dst, err := os.Stat(destination); err == nil && os.SameFile(src, dst) {
			return fmt.Errorf("output would overwrite input: %s", path)
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		decoded, err := decompress(data)
		if err != nil {
			return fmt.Errorf("%s: %w", path, err)
		}
		results = append(results, result{destination, decoded})
	}
	if err := os.MkdirAll(output, 0755); err != nil {
		return err
	}
	for _, item := range results {
		if err := os.WriteFile(item.name, item.data, 0644); err != nil {
			return err
		}
		fmt.Printf("%s: %d bytes\n", item.name, len(item.data))
	}
	return nil
}

func main() {
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "Usage: extract_bt INPUT_FILE_OR_DIRECTORY OUTPUT_DIRECTORY\nDirectory mode extracts *.MSF, *.SSG and *.OPN (non-recursive).")
	}
	flag.Parse()
	if flag.NArg() != 2 {
		flag.Usage()
		os.Exit(2)
	}
	if err := run(flag.Arg(0), flag.Arg(1)); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
