// Extract original driver+tone+song blocks from Kohakuiro no Yuigon disk 1.
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

var tracks = []int{44, 45, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59}

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
func extract(b []byte) ([][]byte, error) {
	image, err := diskImage(b)
	if err != nil {
		return nil, err
	}
	var files [][]byte
	for _, track := range tracks {
		block := image[track*8192 : (track+1)*8192]
		if !bytes.Equal(block[:11], []byte{0x1e, 0x06, 0xfc, 0x8c, 0xc8, 0x8e, 0xd8, 0x8e, 0xc0, 0xc6, 0x06}) || !bytes.Equal(block[0x18:0x1b], []byte{0xbe, 0xe4, 0x14}) || u16(block[0x14e4:]) != 14 {
			return nil, fmt.Errorf("track %d is not a supported Kohaku sound block (use disk 1)", track)
		}
		for ch := 0; ch < 6; ch++ {
			off := u16(block[0x14e4+ch*2:])
			if off < 14 || off >= 8192-0x14e4 {
				return nil, fmt.Errorf("invalid song offset")
			}
		}
		files = append(files, block)
	}
	return files, nil
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: extract_kohaku disk1.d88-or-hdm output-directory")
	}
	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		return err
	}
	files, err := extract(b)
	if err != nil {
		return err
	}
	if err = os.MkdirAll(os.Args[2], 0755); err != nil {
		return err
	}
	for i, data := range files {
		name := fmt.Sprintf("SND%02d.BIN", i+1)
		if err = os.WriteFile(filepath.Join(os.Args[2], name), data, 0644); err != nil {
			return err
		}
		fmt.Printf("%s: track %d, offset %#x, %d bytes\n", name, tracks[i], tracks[i]*8192, len(data))
	}
	return nil
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
