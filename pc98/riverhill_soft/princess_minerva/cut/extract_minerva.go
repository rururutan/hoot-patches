// Extract Princess Minerva's sound group from the first D88 disk.
package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

func u16(b []byte) int { return int(binary.LittleEndian.Uint16(b)) }
func u32(b []byte) int { return int(binary.LittleEndian.Uint32(b)) }
func extract(b []byte) ([][]byte, error) {
	if len(b) < 0x2b0 || u32(b[0x1c:]) != len(b) {
		return nil, fmt.Errorf("expected one complete D88 disk")
	}
	tracks := make([]map[int][]byte, 164)
	for i := range tracks {
		off := u32(b[0x20+i*4:])
		if off == 0 {
			continue
		}
		if off < 0x2b0 || off+16 > len(b) {
			return nil, fmt.Errorf("invalid track %d", i)
		}
		count := u16(b[off+4:])
		tracks[i] = make(map[int][]byte)
		for j := 0; j < count; j++ {
			if off+16 > len(b) {
				return nil, fmt.Errorf("truncated sector")
			}
			n := u16(b[off+14:])
			id := int(b[off+2])
			if n != 1024 || off+16+n > len(b) {
				return nil, fmt.Errorf("unsupported sector size")
			}
			tracks[i][id] = b[off+16 : off+16+n]
			off += 16 + n
		}
	}
	read := func(track, size, pos int) ([]byte, error) {
		out := make([]byte, 0, size)
		for size > 0 {
			track += pos / 8192
			pos %= 8192
			if track >= len(tracks) {
				return nil, fmt.Errorf("track out of range")
			}
			sector := tracks[track][pos/1024+1]
			if len(sector) != 1024 {
				return nil, fmt.Errorf("missing sector")
			}
			offset := pos % 1024
			n := 1024 - offset
			if n > size {
				n = size
			}
			out = append(out, sector[offset:offset+n]...)
			pos += n
			size -= n
		}
		return out, nil
	}
	table, err := read(10, 0x13c2, 0)
	if err != nil {
		return nil, err
	}
	start, end := u16(table[2:]), u16(table[4:])
	if start != 0x6a || end != 0x310 {
		return nil, fmt.Errorf("not the supported Minerva disk 1 sound table")
	}
	var files [][]byte
	for p := start; p < end; p += 6 {
		data, err := read(u16(table[p:]), u16(table[p+2:]), u16(table[p+4:]))
		if err != nil {
			return nil, err
		}
		files = append(files, data)
	}
	if len(files) != 0x71 || len(files[0]) != 9296 || len(files[0x3f]) < 20 || u16(files[0x3f]) != 20 {
		return nil, fmt.Errorf("unexpected sound group")
	}
	return files, nil
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: extract_minerva MINERVA1.D88 output-directory")
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
	for i, b := range files {
		name := fmt.Sprintf("snd%02x", i)
		if err = os.WriteFile(filepath.Join(os.Args[2], name), b, 0644); err != nil {
			return err
		}
		fmt.Printf("%s: %d bytes\n", name, len(b))
	}
	return nil
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
