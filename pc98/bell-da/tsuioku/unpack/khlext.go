package main

import (
	"encoding/binary"
	"fmt"
	"os"
)

func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: khlext input output")
	}
	b, e := os.ReadFile(os.Args[1])
	if e != nil {
		return e
	}
	if len(b) < 16 || string(b[5:8]) != "KHL" {
		return fmt.Errorf("invalid KHL header")
	}
	size := int(binary.LittleEndian.Uint32(b[1:5]))
	if size > 1048576 {
		return fmt.Errorf("unreasonable output size")
	}
	out := make([]byte, 0, size)
	var ring [4096]byte
	cursor := 0xfee
	p := 16
	flags := 0
	for len(out) < size {
		flags >>= 1
		if flags&0x100 == 0 {
			if p >= len(b) {
				return fmt.Errorf("truncated flags")
			}
			flags = int(b[p]) | 0xff00
			p++
		}
		if flags&1 != 0 {
			if p >= len(b) {
				return fmt.Errorf("truncated literal")
			}
			v := b[p]
			p++
			out = append(out, v)
			ring[cursor] = v
			cursor = (cursor + 1) & 4095
		} else {
			if p+2 > len(b) {
				return fmt.Errorf("truncated match")
			}
			off := int(b[p]) | int(b[p+1]&0xf0)<<4
			n := int(b[p+1]&15) + 3
			p += 2
			for j := 0; j < n && len(out) < size; j++ {
				v := ring[(off+j)&4095]
				out = append(out, v)
				ring[cursor] = v
				cursor = (cursor + 1) & 4095
			}
		}
	}
	return os.WriteFile(os.Args[2], out, 0644)
}
func main() {
	if e := run(); e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}
}
