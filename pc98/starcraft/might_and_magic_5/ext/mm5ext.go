// mm5ext extracts original PC-98 Might and Magic V CC members.
package main

import (
	"encoding/binary"
	"fmt"
	"math/bits"
	"os"
	"path/filepath"
)

var names = []string{"bank.m", "bigtheme.m", "castle.m", "cavern.m", "cavern1.m", "cavern2.m", "cavern3a.m", "cstl1rev.m", "cstl2rev.m", "cstl3rev.m", "daydesrt.m", "dngon1.m", "dngon2.m", "dngon3.m", "dungeon.m", "dungeon2.m", "endgame.m", "grounds.m", "guild.m", "h.m", "inn.m", "mm4theme.m", "newbrigh.m", "nwblksmt.m", "outday1.m", "outday2.m", "outday3.m", "outday4.m", "outdoors.m", "outnght1.m", "outnght2.m", "outnght4.m", "sf05.m", "sf09.m", "sf17.m", "smith.m", "tavern.m", "temple.m", "town.m", "townday1.m", "twnnitea.m", "twnniteb.m", "twnwlk.m"}

func hash(s string) uint16 {
	var v uint16
	for _, c := range []byte(s) {
		if c >= 'a' && c <= 'z' {
			c -= 32
		}
		v = bits.RotateLeft16(v, 9) + uint16(c)
	}
	return v
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: mm5ext input.cc output-directory")
	}
	b, e := os.ReadFile(os.Args[1])
	if e != nil {
		return e
	}
	if len(b) < 2 {
		return fmt.Errorf("missing CC header")
	}
	n := int(binary.LittleEndian.Uint16(b))
	end := 2 + n*8
	if end > len(b) {
		return fmt.Errorf("truncated CC directory")
	}
	a := append([]byte(nil), b[2:end]...)
	key := byte(0xac)
	for i, v := range a {
		a[i] = bits.RotateLeft8(v, 2) + key
		key += 0x67
	}
	lookup := map[uint16]string{}
	for _, name := range names {
		lookup[hash(name)] = name
	}
	seen := map[uint16]bool{}
	if e = os.MkdirAll(os.Args[2], 0755); e != nil {
		return e
	}
	for i := 0; i < n; i++ {
		x := a[i*8:]
		id := binary.LittleEndian.Uint16(x)
		off := int(x[2]) | int(x[3])<<8 | int(x[4])<<16
		size := int(binary.LittleEndian.Uint16(x[5:]))
		if seen[id] {
			return fmt.Errorf("duplicate hash %04x", id)
		}
		seen[id] = true
		if off < end || off > len(b)-size {
			return fmt.Errorf("invalid member %04x bounds", id)
		}
		out := append([]byte(nil), b[off:off+size]...)
		for j := range out {
			out[j] ^= 0x35
		}
		name := lookup[id]
		if name == "" {
			name = fmt.Sprintf("%04x.bin", id)
		}
		dest := filepath.Join(os.Args[2], name)
		if e = os.WriteFile(dest, out, 0644); e != nil {
			return fmt.Errorf("write %s: %w", dest, e)
		}
	}
	fmt.Printf("Extracted %d files\n", n)
	return nil
}
func main() {
	if e := run(); e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}
}
