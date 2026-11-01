// mm3ext extracts PC-9801 Might and Magic III CC archives.
package main

import (
	"encoding/binary"
	"fmt"
	"math/bits"
	"os"
	"path/filepath"
)

const nc = 314
const tree = 627
const root = 626

var names = []string{"bank.m", "caves.m", "city.m", "combat.m", "cyber.m", "dungeon.m", "eerie.m", "grounds.m", "guild.m", "honky.m", "medieval.m", "mm3theme.m", "nec26k.drv", "roland.drv", "temples.m", "towninn.m", "venture.m"}

type decoder struct {
	data   []byte
	bit    int
	freq   [628]int
	son    [627]int
	parent [941]int
}

func (d *decoder) read(n int) (int, error) {
	v := 0
	for i := 0; i < n; i++ {
		if d.bit >= len(d.data)*8 {
			return 0, fmt.Errorf("truncated compressed stream")
		}
		v = v*2 + int((d.data[d.bit/8]>>uint(7-d.bit%8))&1)
		d.bit++
	}
	return v, nil
}
func (d *decoder) reconstruct() {
	j := 0
	for i := 0; i < tree; i++ {
		if d.son[i] >= tree {
			d.freq[j] = (d.freq[i] + 1) / 2
			d.son[j] = d.son[i]
			j++
		}
	}
	j = 0
	for i := nc; i < tree; i++ {
		f := d.freq[j] + d.freq[j+1]
		k := i - 1
		for k >= 0 && f < d.freq[k] {
			k--
		}
		k++
		copy(d.freq[k+1:i+1], d.freq[k:i])
		copy(d.son[k+1:i+1], d.son[k:i])
		d.freq[k] = f
		d.son[k] = j
		j += 2
	}
	for i := 0; i < tree; i++ {
		k := d.son[i]
		d.parent[k] = i
		if k < tree {
			d.parent[k+1] = i
		}
	}
}
func decompress(b []byte) ([]byte, error) {
	if len(b) < 4 {
		return nil, fmt.Errorf("missing compression header")
	}
	size := int(binary.BigEndian.Uint16(b[2:4]))
	d := decoder{data: b, bit: 32}
	for i := 0; i < nc; i++ {
		d.freq[i] = 1
		d.son[i] = i + tree
		d.parent[i+tree] = i
	}
	for i, j := nc, 0; i < tree; i, j = i+1, j+2 {
		d.freq[i] = d.freq[j] + d.freq[j+1]
		d.son[i] = j
		d.parent[j] = i
		d.parent[j+1] = i
	}
	d.freq[tree] = 65535
	d.parent[root] = 0
	var ring [4096]byte
	for i := range ring {
		ring[i] = b[i&1]
	}
	r := 4096 - 60
	out := make([]byte, 0, size)
	lens := make([]int, 0, 64)
	for length, count := range []int{0, 0, 0, 1, 3, 8, 12, 24, 16} {
		for i := 0; i < count; i++ {
			lens = append(lens, length)
		}
	}
	for len(out) < size {
		c := d.son[root]
		for c < tree {
			v, e := d.read(1)
			if e != nil {
				return nil, e
			}
			c = d.son[c+v]
		}
		c -= tree
		if d.freq[root] >= 32768 {
			d.reconstruct()
		}
		for k := d.parent[c+tree]; ; {
			d.freq[k]++
			v := d.freq[k]
			l := k + 1
			if v > d.freq[l] {
				for v > d.freq[l+1] {
					l++
				}
				d.freq[k] = d.freq[l]
				d.freq[l] = v
				a := d.son[k]
				d.parent[a] = l
				if a < tree {
					d.parent[a+1] = l
				}
				z := d.son[l]
				d.son[l] = a
				d.parent[z] = k
				if z < tree {
					d.parent[z+1] = k
				}
				d.son[k] = z
				k = l
			}
			k = d.parent[k]
			if k == 0 {
				break
			}
		}
		if c < 256 {
			out = append(out, byte(c))
			ring[r] = byte(c)
			r = (r + 1) & 4095
			continue
		}
		code, upper := 0, -1
		for length := 1; length <= 8 && upper < 0; length++ {
			v, e := d.read(1)
			if e != nil {
				return nil, e
			}
			code = code*2 + v
			canonical := 0
			for u, ln := range lens {
				if ln == length && canonical == code {
					upper = u
					break
				}
				if ln <= length {
					canonical += 1 << uint(length-ln)
				}
			}
		}
		if upper < 0 {
			return nil, fmt.Errorf("invalid distance prefix")
		}
		low, e := d.read(6)
		if e != nil {
			return nil, e
		}
		start := (r - (upper<<6 | low) - 1) & 4095
		for j := 0; j < c-253 && len(out) < size; j++ {
			v := ring[(start+j)&4095]
			out = append(out, v)
			ring[r] = v
			r = (r + 1) & 4095
		}
	}
	return out, nil
}
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
		return fmt.Errorf("usage: mm3ext input.cc output-directory")
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
	idx := append([]byte(nil), b[2:end]...)
	key := byte(0xac)
	for i, v := range idx {
		idx[i] = bits.RotateLeft8(v, 2) + key
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
		a := idx[i*8:]
		id := binary.LittleEndian.Uint16(a)
		off := int(a[2]) | int(a[3])<<8 | int(a[4])<<16
		size := int(binary.LittleEndian.Uint16(a[5:]))
		if seen[id] {
			return fmt.Errorf("duplicate member hash %04x", id)
		}
		seen[id] = true
		if off < end || size < 4 || off > len(b)-size {
			return fmt.Errorf("invalid member %04x bounds", id)
		}
		out, e := decompress(b[off : off+size])
		if e != nil {
			return fmt.Errorf("member %04x: %w", id, e)
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
