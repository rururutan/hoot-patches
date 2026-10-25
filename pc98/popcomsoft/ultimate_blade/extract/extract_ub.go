// Ultimate Blade DAT decoder. No external packages are required.
package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

func word(b []byte) int { return int(binary.LittleEndian.Uint16(b)) }
func stage(b []byte, mode byte) (out []byte) {
	n := word(b)
	b = b[2:]
	if mode == 4 {
		weights := make([]int, 256)
		nodes := make([]int, 256)
		tree := make([][2]int, 0)
		for i := range weights {
			weights[i] = int(b[i])
			nodes[i] = 256 + i
		}
		b = b[256:]
		pick := func() int {
			k := -1
			for i, w := range weights {
				if w != 0 && (k < 0 || w <= weights[k]) {
					k = i
				}
			}
			return k
		}
		root := 0
		for {
			a := pick()
			if a < 0 {
				panic("empty Huffman tree")
			}
			w, v := weights[a], nodes[a]
			weights[a] = 0
			c := pick()
			if c < 0 {
				root = v
				break
			}
			tree = append(tree, [2]int{nodes[c], v})
			nodes[c] = len(tree) - 1
			weights[c] += w
		}
		bit := 0
		for len(out) < n {
			v := root
			for v < 256 {
				d := (b[bit/8] >> uint(7-bit%8)) & 1
				bit++
				v = tree[v][d]
			}
			out = append(out, byte(v-256))
		}
	} else {
		marker := b[0]
		b = b[1:]
		shift := 0
		if mode == 2 {
			shift = 12 - int(b[0])
			b = b[1:]
			if shift < 1 || shift > 12 {
				panic("invalid LZ shift")
			}
		}
		for len(out) < n {
			x := b[0]
			b = b[1:]
			if x != marker {
				out = append(out, x)
				continue
			}
			if mode == 1 {
				count := int(b[0])
				b = b[1:]
				if count == 1 {
					out = append(out, marker)
					continue
				}
				if count == 0 {
					count = word(b)
					b = b[2:]
				}
				count += 2
				x = b[0]
				b = b[1:]
				for j := 0; j < count; j++ {
					out = append(out, x)
				}
			} else {
				code := word(b)
				b = b[2:]
				if code == 0 {
					out = append(out, marker)
					continue
				}
				distance := code & ((1 << uint(shift)) - 1)
				count := (code >> uint(shift)) + 4
				if distance == 0 || distance > len(out) {
					panic("invalid LZ distance")
				}
				for j := 0; j < count; j++ {
					out = append(out, out[len(out)-distance])
				}
			}
		}
	}
	if len(out) != n {
		panic("decoded size mismatch")
	}
	return
}
func decode(b []byte) (out []byte) {
	for {
		n := word(b)
		b = b[2:]
		if n == 0 {
			if len(b) != 0 {
				panic("trailing block bytes")
			}
			return
		}
		flags := b[0]
		b = b[1:]
		if flags > 7 {
			panic("invalid compression flags")
		}
		block := b[:n]
		b = b[n:]
		for _, mode := range []byte{4, 2, 1} {
			if flags&mode != 0 {
				block = stage(block, mode)
			}
		}
		out = append(out, block...)
	}
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: extract_ub <game directory> <output directory>")
	}
	if err := os.MkdirAll(os.Args[2], 0755); err != nil {
		return err
	}
	for _, mode := range []string{"FM", "MD"} {
		b, err := os.ReadFile(filepath.Join(os.Args[1], "UBBGM_"+mode+".DAT"))
		if err != nil {
			return err
		}
		index := 0
		for {
			if len(b) < 4 {
				return fmt.Errorf("truncated archive")
			}
			n := int(binary.LittleEndian.Uint32(b))
			if n == 0 {
				if len(b) != 4 {
					return fmt.Errorf("trailing archive bytes")
				}
				break
			}
			if n < 6 || n > len(b) {
				return fmt.Errorf("invalid entry size")
			}
			out := decode(b[4:n])
			if len(out) < 2 || word(out)+2 != len(out) {
				return fmt.Errorf("invalid song size: %s %d", mode, index)
			}
			name := fmt.Sprintf("%s%02d.BIN", mode, index)
			if err := os.WriteFile(filepath.Join(os.Args[2], name), out, 0644); err != nil {
				return err
			}
			fmt.Printf("%s: %d bytes\n", name, len(out))
			index++
			b = b[n:]
		}
	}
	return nil
}
func main() {
	defer func() {
		if e := recover(); e != nil {
			fmt.Fprintln(os.Stderr, "invalid compressed data:", e)
			os.Exit(1)
		}
	}()
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
