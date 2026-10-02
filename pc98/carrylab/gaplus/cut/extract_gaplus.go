// Extract the original FM/SSG driver and sequences from the supplied 2DD/2HD editions.
package main

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

func run() error {
	if len(os.Args) < 2 || len(os.Args) > 3 {
		return fmt.Errorf("usage: extract_gaplus disk.d88 [output-directory]")
	}
	b, e := os.ReadFile(os.Args[1])
	if e != nil {
		return e
	}
	var driverOffset int
	var songRanges [][2]int
	switch fmt.Sprintf("%x", sha256.Sum256(b)) {
	case "4cce039322bff9da9e2d3c016e5e2bb3dceae430576a84be1fe13e25882a681d":
		driverOffset = 0xc000
		songRanges = [][2]int{{0x1c000, 0x1d800}}
	case "e3b1877ec99a55609caf2feb49fa3745166e57095b6ab10dec4b5083a17af039":
		driverOffset = 0x12e00
		// The song crosses a disk allocation gap in the 2HD edition.
		songRanges = [][2]int{{0x2ce00, 0x2de00}, {0x2e800, 0x2f000}}
	default:
		return fmt.Errorf("unsupported D88 revision (expected supplied Gaplus 2DD or 2HD edition)")
	}
	var flat []byte
	for t := 0; t < 164; t++ {
		p := int(binary.LittleEndian.Uint32(b[0x20+t*4:]))
		if p == 0 {
			continue
		}
		n := int(binary.LittleEndian.Uint16(b[p+4:]))
		for i := 0; i < n; i++ {
			s := int(binary.LittleEndian.Uint16(b[p+14:]))
			flat = append(flat, b[p+16:p+16+s]...)
			p += 16 + s
		}
	}
	out := "extracted"
	if len(os.Args) == 3 {
		out = os.Args[2]
	}
	if e = os.MkdirAll(out, 0755); e != nil {
		return e
	}
	var song []byte
	for _, span := range songRanges {
		song = append(song, flat[span[0]:span[1]]...)
	}
	for _, f := range []struct {
		name string
		data []byte
	}{{"GAP_DRV.BIN", flat[driverOffset : driverOffset+0x900]}, {"GAP_SND.BIN", song}} {
		if e = os.WriteFile(filepath.Join(out, f.name), f.data, 0644); e != nil {
			return e
		}
		fmt.Printf("%s: %d bytes\n", f.name, len(f.data))
	}
	return nil
}
func main() {
	if e := run(); e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}
}
