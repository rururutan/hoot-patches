// Kremlin Twilight (PC-9801) CMB music extractor. Standard library only.
// DCL tables/format reference: Mark Adler's zlib/contrib/blast.
// This Go adaptation is not the original blast. Copyright/license: rel/LICENSE-blast.txt
// (LICENSE-blast.txt alongside this file in the distribution).
package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type bits struct {
	data []byte
	pos  int
	err  error
}

func (b *bits) get(n int) int {
	if b.pos+n > len(b.data)*8 {
		b.err = fmt.Errorf("truncated compressed stream")
		return 0
	}
	v := 0
	for j := 0; j < n; j++ {
		v |= int((b.data[b.pos/8]>>uint(b.pos%8))&1) << uint(j)
		b.pos++
	}
	return v
}

type code struct{ length, value int }
type huffman map[code]int

func table(rep []int) huffman {
	lengths := []int{}
	for _, v := range rep {
		for i := 0; i <= v>>4; i++ {
			lengths = append(lengths, v&15)
		}
	}
	symbols := make([]int, len(lengths))
	for i := range symbols {
		symbols[i] = i
	}
	sort.SliceStable(symbols, func(i, j int) bool { return lengths[symbols[i]] < lengths[symbols[j]] })
	t := huffman{}
	value, previous := 0, 0
	for _, s := range symbols {
		n := lengths[s]
		value <<= uint(n - previous)
		t[code{n, value}] = s
		value++
		previous = n
	}
	return t
}
func (b *bits) symbol(t huffman) int {
	value := 0
	for n := 1; n <= 13; n++ {
		value = value<<1 | (b.get(1) ^ 1)
		if b.err != nil {
			return 0
		}
		if s, ok := t[code{n, value}]; ok {
			return s
		}
	}
	b.err = fmt.Errorf("invalid Huffman code")
	return 0
}

// Fixed DCL code lengths (run-length encoded), also present in KTT.EXE.
var literal = table([]int{11, 124, 8, 7, 28, 7, 188, 13, 76, 4, 10, 8, 12, 10, 12, 10, 8, 23, 8, 9, 7, 6, 7, 8, 7, 6, 55, 8, 23, 24, 12, 11, 7, 9, 11, 12, 6, 7, 22, 5, 7, 24, 6, 11, 9, 6, 7, 22, 7, 11, 38, 7, 9, 8, 25, 11, 8, 11, 9, 12, 8, 12, 5, 38, 5, 38, 5, 11, 7, 5, 6, 21, 6, 10, 53, 8, 7, 24, 10, 27, 44, 253, 253, 253, 252, 252, 252, 13, 12, 45, 12, 45, 12, 61, 12, 45, 44, 173})
var length = table([]int{2, 35, 36, 53, 38, 23})
var distance = table([]int{2, 20, 53, 230, 247, 151, 248})
var bases = []int{3, 2, 4, 5, 6, 7, 8, 9, 10, 12, 16, 24, 40, 72, 136, 264}
var extra = []int{0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8}

func explode(data []byte, size int) ([]byte, error) {
	if len(data) < 2 || data[0] > 1 || data[1] < 4 || data[1] > 6 {
		return nil, fmt.Errorf("invalid DCL header")
	}
	if size < 0 || size > 16*1024*1024 {
		return nil, fmt.Errorf("output size exceeds limit")
	}
	b := bits{data: data, pos: 16}
	out := make([]byte, 0, size)
	for b.err == nil {
		if b.get(1) == 0 {
			var v int
			if data[0] == 1 {
				v = b.symbol(literal)
			} else {
				v = b.get(8)
			}
			if b.err != nil {
				break
			}
			if len(out) == size {
				return nil, fmt.Errorf("output exceeds declared size")
			}
			out = append(out, byte(v))
		} else {
			s := b.symbol(length)
			n := bases[s] + b.get(extra[s])
			if b.err != nil {
				break
			}
			if n == 519 {
				if len(out) != size {
					return nil, fmt.Errorf("output size mismatch: %d != %d", len(out), size)
				}
				if (b.pos+7)/8 != len(data) {
					return nil, fmt.Errorf("trailing compressed bytes")
				}
				return out, nil
			}
			shift := int(data[1])
			if n == 2 {
				shift = 2
			}
			d := (b.symbol(distance) << uint(shift)) + b.get(shift) + 1
			if b.err != nil {
				break
			}
			if d > len(out) {
				return nil, fmt.Errorf("reference before output")
			}
			if n > size-len(out) {
				return nil, fmt.Errorf("copy exceeds declared size")
			}
			for i := 0; i < n; i++ {
				out = append(out, out[len(out)-d])
			}
		}
	}
	return nil, b.err
}

type member struct {
	name string
	data []byte
}

func unpack(data []byte) ([]member, error) {
	if len(data) < 1 {
		return nil, fmt.Errorf("empty archive")
	}
	count := int(data[0])
	header := 1 + count*4
	if count == 0 || len(data) < header {
		return nil, fmt.Errorf("invalid archive table")
	}
	offsets := make([]int, count+1)
	for i := 0; i < count; i++ {
		v := binary.LittleEndian.Uint32(data[1+i*4:])
		if uint64(v) > uint64(len(data)) {
			return nil, fmt.Errorf("offset outside archive")
		}
		offsets[i] = int(v)
	}
	offsets[count] = len(data)
	if offsets[0] != header {
		return nil, fmt.Errorf("invalid first offset")
	}
	var result []member
	seen := map[string]bool{}
	for i := 0; i < count; i++ {
		start, end := offsets[i], offsets[i+1]
		if end-start < 22 {
			return nil, fmt.Errorf("invalid entry %d bounds", i)
		}
		entry := data[start:end]
		packed := binary.LittleEndian.Uint32(entry[1:])
		size := binary.LittleEndian.Uint32(entry[5:])
		if uint64(packed)+22 != uint64(len(entry)) {
			return nil, fmt.Errorf("entry %d size mismatch", i)
		}
		raw := append([]byte(nil), entry[9:22]...)
		for j := range raw {
			raw[j] ^= 100
		}
		name := strings.SplitN(string(raw), "\x00", 2)[0]
		ext := strings.ToUpper(filepath.Ext(name))
		if ext != ".MFM" && ext != ".MD" && ext != ".LL" {
			continue
		}
		if strings.ContainsAny(name, "/\\:< >|\"?*") || name == "" || strings.HasSuffix(name, ".") {
			return nil, fmt.Errorf("unsafe filename")
		}
		for _, c := range []byte(name) {
			if c < 33 || c > 126 {
				return nil, fmt.Errorf("invalid filename")
			}
		}
		stem := strings.ToUpper(strings.SplitN(name, ".", 2)[0])
		if stem == "CON" || stem == "PRN" || stem == "AUX" || stem == "NUL" || (len(stem) == 4 && (strings.HasPrefix(stem, "COM") || strings.HasPrefix(stem, "LPT")) && stem[3] >= '1' && stem[3] <= '9') {
			return nil, fmt.Errorf("reserved filename")
		}
		key := strings.ToUpper(name)
		if seen[key] {
			return nil, fmt.Errorf("duplicate filename: %s", name)
		}
		seen[key] = true
		if entry[0] != 2 {
			return nil, fmt.Errorf("%s: unsupported music method %d", name, entry[0])
		}
		if size > 16*1024*1024 {
			return nil, fmt.Errorf("%s: size exceeds limit", name)
		}
		decoded, err := explode(entry[22:], int(size))
		if err != nil {
			return nil, fmt.Errorf("%s: %w", name, err)
		}
		result = append(result, member{name, decoded})
	}
	if len(result) == 0 {
		return nil, fmt.Errorf("no music/list entries")
	}
	return result, nil
}

func run(input, output string) error {
	info, err := os.Stat(input)
	if err != nil {
		return err
	}
	paths := []string{input}
	if info.IsDir() {
		paths = nil
		for _, name := range []string{"PESNIF.CMB", "PESNIM.CMB", "MY.CMB"} {
			paths = append(paths, filepath.Join(input, name))
		}
	}
	var all []member
	for _, path := range paths {
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		entries, err := unpack(data)
		if err != nil {
			return fmt.Errorf("%s: %w", path, err)
		}
		dir := filepath.Join(output, strings.TrimSuffix(filepath.Base(path), filepath.Ext(path)))
		for _, e := range entries {
			all = append(all, member{filepath.Join(dir, e.name), e.data})
		}
	}
	// Validate all inputs before writing, and protect source files even via links.
	for _, e := range all {
		if dst, err := os.Stat(e.name); err == nil {
			for _, p := range paths {
				src, err := os.Stat(p)
				if err != nil {
					return err
				}
				if os.SameFile(src, dst) {
					return fmt.Errorf("output would overwrite input")
				}
			}
		}
	}
	for _, e := range all {
		if err := os.MkdirAll(filepath.Dir(e.name), 0755); err != nil {
			return err
		}
		if err := os.WriteFile(e.name, e.data, 0644); err != nil {
			return err
		}
		fmt.Printf("%s: %d bytes\n", e.name, len(e.data))
	}
	return nil
}
func main() {
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "Usage: extract_ktw INPUT_CMB_OR_DATA_DIRECTORY OUTPUT_DIRECTORY\nExtracts .MFM, .MD and .LL. Directory mode reads PESNIF.CMB, PESNIM.CMB, MY.CMB.")
	}
	flag.Parse()
	if flag.NArg() != 2 {
		flag.Usage()
		os.Exit(2)
	}
	if err := run(flag.Arg(0), flag.Arg(1)); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
