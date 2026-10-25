// Extract Manhattan Requiem / Kiss of Murder original driver and song blocks.
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

func u16(b []byte) int { return int(binary.LittleEndian.Uint16(b)) }
func u32(b []byte) int { return int(binary.LittleEndian.Uint32(b)) }

func diskImage(b []byte) ([]byte, error) {
	if len(b) == 1261568 {
		return b, nil
	}
	if len(b) < 0x2b0 || u32(b[0x1c:]) != len(b) {
		return nil, fmt.Errorf("expected a single D88 disk or 1261568-byte HDM image")
	}
	out := make([]byte, 1261568)
	for track := 0; track < 154; track++ {
		p := u32(b[0x20+track*4:])
		if p < 0x2b0 || p+16 > len(b) {
			return nil, fmt.Errorf("missing track %d", track)
		}
		n := u16(b[p+4:])
		if n != 8 {
			return nil, fmt.Errorf("unsupported track geometry")
		}
		seen := 0
		for i := 0; i < n; i++ {
			if p+16 > len(b) {
				return nil, fmt.Errorf("truncated sector header")
			}
			id, size := int(b[p+2]), u16(b[p+14:])
			if id < 1 || id > 8 || size != 1024 || p+16+size > len(b) || seen&(1<<uint(id-1)) != 0 {
				return nil, fmt.Errorf("invalid sector")
			}
			seen |= 1 << uint(id-1)
			copy(out[track*8192+(id-1)*1024:], b[p+16:p+16+size])
			p += 16 + size
		}
	}
	return out, nil
}
func extract(image []byte, prefix string, offsets, sizes []int) ([][]byte, error) {
	var files [][]byte
	for i, off := range offsets {
		b := image[off : off+sizes[i]]
		start := 0
		if b[0] == 0xeb && b[1] == 2 {
			start = 4
		}
		if !bytes.Equal(b[start:start+11], []byte{0x1e, 0x06, 0xfc, 0x8c, 0xc8, 0x8e, 0xd8, 0x8e, 0xc0, 0xc6, 0x06}) || u16(b[start+25:]) != 0x1500 {
			return nil, fmt.Errorf("invalid %s sound block at %#x", prefix, off)
		}
		for ch := 0; ch < 6; ch++ {
			v := u16(b[0x1500+ch*2:])
			if v < 12 || v >= len(b)-0x1500 {
				return nil, fmt.Errorf("invalid track offset")
			}
		}
		files = append(files, b)
	}
	return files, nil
}

type game struct {
	prefix         string
	offsets, sizes []int
}

var games = []game{
	{"MR", []int{0x36000, 0x38000, 0x3a000, 0x3c000, 0x3e000, 0x40000}, []int{8192, 8192, 8192, 8192, 8192, 8192}},
	{"KM", []int{0x38000, 0x3a000, 0x3c000, 0x3e000, 0x40000, 0xa0000, 0xa4000, 0xa6000}, []int{8192, 8192, 8192, 8192, 8192, 12288, 8192, 8192}},
}

func readGame(path string) (map[string][]byte, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	image, err := diskImage(raw)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	result := make(map[string][]byte)
	matches := 0
	for _, g := range games {
		files, e := extract(image, g.prefix, g.offsets, g.sizes)
		if e != nil {
			continue
		}
		matches++
		for n, b := range files {
			result[fmt.Sprintf("%s%02d.BIN", g.prefix, n+1)] = b
		}
	}
	if matches != 1 {
		return nil, fmt.Errorf("%s: cannot uniquely identify a supported game image (matches: %d)", path, matches)
	}
	return result, nil
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: extract_mreq game-image output-directory (D88 or HDM; game detected automatically)")
	}
	all, err := readGame(os.Args[1])
	if err != nil {
		return err
	}
	output := os.Args[2]
	if err := os.MkdirAll(output, 0755); err != nil {
		return err
	}
	// Keep output order stable.
	for _, g := range games {
		for n := range g.offsets {
			name := fmt.Sprintf("%s%02d.BIN", g.prefix, n+1)
			b, ok := all[name]
			if !ok {
				continue
			}
			if err := os.WriteFile(filepath.Join(output, name), b, 0644); err != nil {
				return err
			}
			fmt.Printf("%s: %d bytes\n", name, len(b))
		}
	}
	return nil
}
func main() {
	if e := run(); e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}
}
