// msf93ext extracts FamilySoft MUSIC.ARC entries with their original names.
package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type bits struct {
	data []byte
	pos  int
}

func (b *bits) get(n int) int {
	if n < 0 || n > 16 || b.pos+n > len(b.data)*8 {
		panic("truncated bit stream")
	}
	v := 0
	for ; n > 0; n-- {
		v = v*2 + int(b.data[b.pos/8]>>uint(7-b.pos%8)&1)
		b.pos++
	}
	return v
}

type huff struct {
	codes  map[int]int
	single int
}

func tree(lengths []int) huff {
	h := huff{codes: map[int]int{}, single: -1}
	var counts, next [17]int
	for _, n := range lengths {
		if n < 0 || n > 16 {
			panic("invalid Huffman length")
		}
		if n > 0 {
			counts[n]++
		}
	}
	code := 0
	for n := 1; n <= 16; n++ {
		code = (code + counts[n-1]) * 2
		next[n] = code
		if code+counts[n] > 1<<n {
			panic("oversubscribed Huffman tree")
		}
	}
	for symbol, n := range lengths {
		if n > 0 {
			h.codes[(1<<n)|next[n]] = symbol
			next[n]++
		}
	}
	if len(h.codes) == 0 {
		panic("empty Huffman tree")
	}
	return h
}
func (h huff) read(b *bits) int {
	if h.single >= 0 {
		return h.single
	}
	code := 1
	for n := 1; n <= 16; n++ {
		code = code*2 + b.get(1)
		if v, ok := h.codes[code]; ok {
			return v
		}
	}
	panic("invalid Huffman code")
}
func readPT(b *bits, nn, nb, special int) huff {
	n := b.get(nb)
	if n == 0 {
		v := b.get(nb)
		if v >= nn {
			panic("invalid constant Huffman symbol")
		}
		return huff{single: v}
	}
	if n > nn {
		panic("too many Huffman lengths")
	}
	ls := make([]int, 0, nn)
	for len(ls) < n {
		c := b.get(3)
		if c == 7 {
			for b.get(1) != 0 {
				c++
				if c > 16 {
					panic("invalid Huffman length")
				}
			}
		}
		ls = append(ls, c)
		if len(ls) == special {
			for z := b.get(2); z > 0; z-- {
				ls = append(ls, 0)
			}
		}
		if len(ls) > nn {
			panic("Huffman length overflow")
		}
	}
	return tree(append(ls, make([]int, nn-len(ls))...))
}
func expand(src []byte, size int) (out []byte, err error) {
	defer func() {
		if e := recover(); e != nil {
			out = nil
			err = fmt.Errorf("%v", e)
		}
	}()
	b := bits{data: src}
	out = make([]byte, 0, size)
	block := 0
	var c, p huff
	for len(out) < size {
		if block == 0 {
			block = b.get(16)
			if block == 0 {
				panic("empty compressed block")
			}
			pt := readPT(&b, 19, 5, 3)
			n := b.get(9)
			if n == 0 {
				v := b.get(9)
				if v >= 510 {
					panic("invalid literal symbol")
				}
				c = huff{single: v}
			} else {
				if n > 510 {
					panic("too many literal lengths")
				}
				ls := make([]int, 0, 510)
				for len(ls) < n {
					v := pt.read(&b)
					if v <= 2 {
						z := 1
						if v == 1 {
							z = b.get(4) + 3
						}
						if v == 2 {
							z = b.get(9) + 20
						}
						if len(ls)+z > 510 {
							panic("literal length overflow")
						}
						ls = append(ls, make([]int, z)...)
					} else {
						ls = append(ls, v-2)
					}
				}
				c = tree(append(ls, make([]int, 510-len(ls))...))
			}
			// Original decoder chooses a 15-bit window: 16 distance symbols.
			p = readPT(&b, 16, 4, -1)
		}
		block--
		v := c.read(&b)
		if v < 256 {
			out = append(out, byte(v))
			continue
		}
		n := v - 253
		d := p.read(&b)
		if d > 0 {
			d = (1 << (d - 1)) + b.get(d-1)
		}
		d++
		if d > 32768 || len(out)+n > size {
			panic("invalid dictionary match")
		}
		for ; n > 0; n-- {
			v := byte(0)
			if d <= len(out) {
				v = out[len(out)-d]
			}
			out = append(out, v)
		}
	}
	return out, nil
}

type entry struct {
	Name                 string
	Size, Packed, Offset int
	data                 []byte
}

func archive(b []byte) ([]entry, error) {
	if len(b) < 26 || b[0] != 255 {
		return nil, fmt.Errorf("not a FamilySoft archive")
	}
	u32 := func(p int) int { return int(binary.LittleEndian.Uint32(b[p : p+4])) }
	end := u32(14)
	if end < 52 || end%26 != 0 || end > len(b) || u32(22) != len(b) {
		return nil, fmt.Errorf("invalid archive header")
	}
	es := []entry{}
	seen := map[string]bool{}
	for i := 26; i < end; i += 26 {
		name := strings.TrimRight(string(b[i:i+14]), "\x00")
		if name == "" || strings.ContainsAny(name, "/\\:\x00") || name == "." || name == ".." {
			return nil, fmt.Errorf("invalid member name")
		}
		key := strings.ToLower(name)
		if seen[key] {
			return nil, fmt.Errorf("duplicate member: %s", name)
		}
		seen[key] = true
		e := entry{Name: name, Size: u32(i + 14), Packed: u32(i + 18), Offset: u32(i + 22)}
		if e.Size <= 0 || e.Size > 16<<20 || e.Packed <= 0 || e.Offset < end || e.Offset > len(b) || e.Packed > len(b)-e.Offset {
			return nil, fmt.Errorf("invalid member bounds: %s", name)
		}
		var err error
		e.data, err = expand(b[e.Offset:e.Offset+e.Packed], e.Size)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", name, err)
		}
		es = append(es, e)
	}
	ordered := append([]entry(nil), es...)
	sort.Slice(ordered, func(i, j int) bool { return ordered[i].Offset < ordered[j].Offset })
	for i := 1; i < len(ordered); i++ {
		if ordered[i-1].Offset+ordered[i-1].Packed > ordered[i].Offset {
			return nil, fmt.Errorf("overlapping archive members")
		}
	}
	return es, nil
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: msf93ext MUSIC.ARC output-directory")
	}
	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		return err
	}
	es, err := archive(b)
	if err != nil {
		return err
	}
	if err = os.MkdirAll(os.Args[2], 0755); err != nil {
		return err
	}
	for _, e := range es {
		path := filepath.Join(os.Args[2], e.Name)
		f, err := os.Create(path)
		if err != nil {
			return err
		}
		n, we := f.Write(e.data)
		ce := f.Close()
		if we != nil {
			return we
		}
		if n != len(e.data) {
			return fmt.Errorf("short write: %s", path)
		}
		if ce != nil {
			return ce
		}
		fmt.Printf("%s: %d -> %d bytes\n", e.Name, e.Packed, e.Size)
	}
	return nil
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
