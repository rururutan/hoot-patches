// Reconstruct a relocatable DOS MZ EXE from the PC-9801 Starglider 2 executable.
// Both SLR stages are decoded directly; no game code or emulator is executed.
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const limit = 0x100000

func word(b []byte) int   { return int(binary.LittleEndian.Uint16(b)) }
func put(b []byte, v int) { binary.LittleEndian.PutUint16(b, uint16(v)) }

type bits struct {
	data []byte
	pos  int
}

func (r *bits) get(n int) int {
	v := 0
	for i := 0; i < n; i++ {
		v = v*2 + int((r.data[r.pos/8]>>uint(7-r.pos%8))&1)
		r.pos++
	}
	return v
}

type tree struct {
	single int
	codes  map[int]int
}

func makeTree(lengths []int) tree {
	t := tree{single: -1, codes: make(map[int]int)}
	code := 0
	for n := 1; n <= 15; n++ {
		for i, l := range lengths {
			if l == n {
				if code >= 1<<uint(n) {
					panic("oversubscribed Huffman tree")
				}
				t.codes[n<<16|code] = i
				code++
			}
		}
		code *= 2
	}
	return t
}
func readTree(r *bits, n, width int) tree {
	lens := []int{r.get(4), r.get(4), r.get(4)}
	if lens[0] == 1 && lens[1] == 1 && lens[2] == 1 {
		v := r.get(width)
		if v >= n {
			panic("invalid single symbol")
		}
		return tree{single: v}
	}
	for len(lens) < n {
		lens = append(lens, r.get(4))
	}
	return makeTree(lens)
}
func (t tree) symbol(r *bits) int {
	if t.single >= 0 {
		return t.single
	}
	code := 0
	for n := 1; n <= 15; n++ {
		code = code*2 + r.get(1)
		if v, ok := t.codes[n<<16|code]; ok {
			return v
		}
	}
	panic("invalid Huffman code")
}
func stage1(data []byte) []byte {
	r := bits{data: data}
	literal, offset := tree{single: -1}, tree{single: -1}
	var out []byte
	for {
		n := r.get(8)*256 + r.get(8)
		if n == 0 {
			return out
		}
		if r.get(1) != 0 {
			literal = readTree(&r, 286, 9)
		}
		if r.get(1) != 0 {
			offset = readTree(&r, 128, 7)
		} else if r.get(1) != 0 {
			var lens []int
			for i, n := range []int{1, 0, 0, 1, 2, 6, 15, 22, 20, 19, 42} {
				for j := 0; j < n; j++ {
					lens = append(lens, i+1)
				}
			}
			offset = makeTree(lens)
		}
		for i := 0; i < n; i++ {
			v := literal.symbol(&r)
			if v < 256 {
				out = append(out, byte(v))
			} else {
				length, distance := 2, 0
				if v == 256 {
					distance = r.get(7) + 1
				} else {
					if v == 285 {
						v += r.get(8)
					}
					length = v - 254
					distance = offset.symbol(&r)*128 + r.get(7) + 1
				}
				if distance > len(out) {
					panic("invalid LZ distance")
				}
				for j := 0; j < length; j++ {
					out = append(out, out[len(out)-distance])
				}
			}
			if len(out) > limit {
				panic("expanded image too large")
			}
		}
	}
}

type relocation struct{ offset, segment int }

func stage2(data []byte, control int) (out []byte, relocs []relocation) {
	pos := 0
	next := func() int { v := word(data[pos:]); pos += 2; return v }
	for {
		switch {
		case control < 0x8000:
			n := control + 1
			out = append(out, data[pos:pos+n]...)
			pos += n
		case control < 0xffff:
			width, n := 1, control-0x7fff
			if control >= 0xe000 {
				width, n = 4, control-0xdfff
			} else if control >= 0xa000 {
				width, n = 2, control-0x9fff
			}
			for i := 0; i < n; i++ {
				out = append(out, data[pos:pos+width]...)
			}
			pos += width
		default:
			n := next()
			if n == 0 {
				return
			}
			seg := next()
			for i := 0; i < n; i++ {
				off, value := next(), next()
				for j := 0; ; j++ {
					if j > 65536 {
						panic("cyclic relocation chain")
					}
					p := seg*16 + off
					if p+2 > len(out) {
						panic("relocation outside image")
					}
					old := word(out[p:])
					put(out[p:], value)
					relocs = append(relocs, relocation{off, seg})
					if len(relocs) > 65535 {
						panic("too many relocations")
					}
					if old == 0xffff {
						break
					}
					off = old
				}
			}
		}
		if len(out) > limit {
			panic("expanded image too large")
		}
		control = next()
	}
}

func unpack(data []byte) (exe, music []byte, err error) {
	defer func() {
		if e := recover(); e != nil {
			exe = nil
			music = nil
			err = fmt.Errorf("invalid packed EXE: %v", e)
		}
	}()
	if len(data) < 32 || string(data[:2]) != "MZ" {
		return nil, nil, fmt.Errorf("not an MZ executable")
	}
	header, cs, ip := word(data[8:])*16, word(data[22:]), word(data[20:])
	entry := header + cs*16 + ip
	if word(data[6:]) != 0 || ip != 0 || entry+0x374 > len(data) {
		return nil, nil, fmt.Errorf("unsupported packed EXE header")
	}
	stub := data[entry : entry+0x374]
	if !bytes.Equal(stub[:4], []byte{0x87, 0xc0, 0xeb, 0x0b}) || string(stub[0x344:0x362]) != "Copyright (C) SLR Systems 1990" {
		return nil, nil, fmt.Errorf("unsupported SLR stub")
	}
	first := stage1(data[header:entry])
	secondEntry := word(stub[13:]) * 16
	if word(stub[11:]) != 2 || secondEntry+0x146 > len(first) {
		return nil, nil, fmt.Errorf("unsupported inner entry")
	}
	inner := first[secondEntry : secondEntry+0x146]
	if !bytes.Equal(inner[2:9], []byte{0x87, 0xc0, 0x8c, 0xda, 0x83, 0xc2, 0x10}) {
		return nil, nil, fmt.Errorf("unsupported inner SLR stub")
	}
	body, relocs := stage2(first[:secondEntry], word(inner[0x144:]))
	// Canonical MZ header: preserve original entry/stack and reconstruct relocation records.
	headerSize := (32 + len(relocs)*4 + 15) &^ 15
	exe = make([]byte, headerSize+len(body))
	copy(exe[headerSize:], body)
	put(exe, 0x5a4d)
	put(exe[2:], len(exe)%512)
	put(exe[4:], (len(exe)+511)/512)
	put(exe[6:], len(relocs))
	put(exe[8:], headerSize/16)
	// Keep at least the packed EXE's minimum allocation, avoiding an invented smaller requirement.
	packedSize := (word(data[4:])-1)*512 + word(data[2:])
	if word(data[2:]) == 0 {
		packedSize = word(data[4:]) * 512
	}
	allocation := (packedSize-header+15)/16 + word(data[10:])
	extra := allocation - (len(body)+15)/16
	if extra < 0 {
		extra = 0
	}
	put(exe[10:], extra)
	put(exe[12:], 0xffff)
	put(exe[14:], word(inner[0x13a:]))
	put(exe[16:], word(inner[0x138:]))
	put(exe[20:], word(inner[0x13c:]))
	put(exe[22:], word(inner[0x13e:]))
	put(exe[24:], 32)
	for i, r := range relocs {
		put(exe[32+i*4:], r.offset)
		put(exe[34+i*4:], r.segment)
	}
	// Verified location and length in this PC-9801 SG2 build; independent of memory dumps.
	if len(body) != 0x604b0 || len(relocs) != 618 || word(inner[0x13e:]) != 0x1696 {
		return nil, nil, fmt.Errorf("unsupported SG2 build")
	}
	music = append([]byte(nil), body[0x14dce:0x14dce+7058]...)
	return
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: unpack_sg2 SG2.EXE output-directory")
	}
	input, err := os.ReadFile(os.Args[1])
	if err != nil {
		return err
	}
	exe, music, err := unpack(input)
	if err != nil {
		return err
	}
	out := filepath.Join(os.Args[2], "SG2_UNPACKED.EXE")
	srcAbs, _ := filepath.Abs(os.Args[1])
	dstAbs, _ := filepath.Abs(out)
	if strings.EqualFold(srcAbs, dstAbs) {
		return fmt.Errorf("output must differ from input")
	}
	if err = os.MkdirAll(os.Args[2], 0755); err != nil {
		return err
	}
	if err = os.WriteFile(out, exe, 0644); err != nil {
		return err
	}
	if err = os.WriteFile(filepath.Join(os.Args[2], "sg2.mus"), music, 0644); err != nil {
		return err
	}
	fmt.Printf("SG2_UNPACKED.EXE: %d bytes, 618 relocations\nsg2.mus: %d bytes\n", len(exe), len(music))
	return nil
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
