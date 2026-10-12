// Extract the embedded RTmusic1.8 driver from the supported RTDEMO.EXE.
package main

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

type bitReader struct {
	data []byte
	pos  int
}

func (r *bitReader) read(n int) (int, error) {
	if r.pos+n > len(r.data)*8 {
		return 0, fmt.Errorf("truncated compressed stream")
	}
	v := 0
	for i := 0; i < n; i++ {
		v = v*2 + int((r.data[r.pos/8]>>uint(7-r.pos%8))&1)
		r.pos++
	}
	return v, nil
}
func unpack(data []byte, size int) ([]byte, error) {
	r := bitReader{data: data}
	out := make([]byte, 0, size)
	for len(out) < size {
		flag, err := r.read(1)
		if err != nil {
			return nil, err
		}
		if flag == 0 {
			v, err := r.read(8)
			if err != nil {
				return nil, err
			}
			out = append(out, byte(v))
			continue
		}
		k := 1
		for {
			v, err := r.read(1)
			if err != nil {
				return nil, err
			}
			if v == 0 || k == 8 {
				break
			}
			k++
		}
		count, err := r.read(k)
		if err != nil {
			return nil, err
		}
		count += 3
		distance, err := r.read(13)
		if err != nil {
			return nil, err
		}
		distance++
		if distance > len(out) || len(out)+count > size {
			return nil, fmt.Errorf("invalid back-reference")
		}
		for i := 0; i < count; i++ {
			out = append(out, out[len(out)-distance])
		}
	}
	return out, nil
}
func run() error {
	if len(os.Args) < 2 || len(os.Args) > 3 {
		return fmt.Errorf("usage: extract_f29 RTDEMO.EXE [output-directory]")
	}
	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		return err
	}
	if fmt.Sprintf("%x", sha256.Sum256(b)) != "45baab11365e0ab9891035ac2066c0d82d91c1c23b13bd67c3eec37dda06d6d8" {
		return fmt.Errorf("unsupported RTDEMO.EXE revision (RETAL.EXE is not the sound source)")
	}
	const block = 0x46845
	size := int(binary.LittleEndian.Uint16(b[block+8:]))
	data, err := unpack(b[block+0xf3:], size)
	if err != nil {
		return err
	}
	if fmt.Sprintf("%x", sha256.Sum256(data)) != "9795d68acf374671813c3697ecd066ae2510da140ededbf16e9bdd423e973c14" {
		return fmt.Errorf("decompressed driver checksum mismatch")
	}
	out := "extracted"
	if len(os.Args) == 3 {
		out = os.Args[2]
	}
	if err = os.MkdirAll(out, 0755); err != nil {
		return err
	}
	if err = os.WriteFile(filepath.Join(out, "F29_DAT.BIN"), data, 0644); err != nil {
		return err
	}
	fmt.Printf("F29_DAT.BIN: %d bytes (RTmusic1.8, 7 BGM + 30 effects)\n", len(data))
	return nil
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
