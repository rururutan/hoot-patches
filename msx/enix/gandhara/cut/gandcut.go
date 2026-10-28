// gandcut extracts MSX Gandhara files ready for the hoot XML, including headers.
// Build: go build -trimpath -ldflags="-s -w" -o gandcut.exe gandcut.go
package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

const diskSize = 737280

type block struct {
	disk, offset int
	address      uint16
	size         int
}

var blocks = map[string]block{
	"TREE":     {0, 0x2501d, 0xa01d, 0x52},
	"JINGLE":   {0, 0x25f0f, 0xaf0f, 0xfa},
	"SE0":      {0, 0x24ac0, 0x9ac0, 0x40},
	"OPEN":     {0, 0x28954, 0x8954, 0x60},
	"TITLE":    {0, 0x289b4, 0x89b4, 0x285},
	"NAME":     {0, 0x28c39, 0x8c39, 0x281},
	"MENU":     {1, 0x25290, 0x5090, 0x290},
	"NINGEN":   {1, 0x1b07a, 0xc07a, 0xd5},
	"OVER":     {1, 0x23c76, 0x7c76, 0x127},
	"MENU2":    {1, 0x27f44, 0x7d44, 0x160},
	"DUNGEON":  {1, 0x173a2, 0x7ba2, 0x386},
	"HEIAN":    {1, 0x1130e, 0xb10e, 0x136},
	"JIGOKU":   {1, 0x1c085, 0xc085, 0x100},
	"GAKI":     {1, 0x1d08c, 0xc08c, 0x80},
	"CHIKUSHO": {1, 0x1e099, 0xc099, 0x160},
	"SHURA":    {1, 0x1f286, 0xc086, 0x160},
	"TENJO":    {1, 0x20486, 0xc086, 0x200},
	"EPILOGUE": {0, 0x23137, 0xc337, 0x280},
	"ENDING":   {0, 0x239bb, 0xcbbb, 0x280},
}

type track struct {
	block      string
	hl, de, bc uint16
}

// Index is the XML song code. A zero BC means two channels; zero DE means one.
var tracks = []track{
	{"TREE", 0xa01d, 0xa041, 0},
	{"JINGLE", 0xafa1, 0xafd4, 0},
	{"SE0", 0x9ac0, 0x9ac4, 0x9ac8},
	{"OPEN", 0x8954, 0x896f, 0x898e},
	{"TITLE", 0x89b4, 0x8a84, 0x8b1d},
	{"NAME", 0x8c39, 0x8cf6, 0x8dbe},
	{"MENU", 0x5090, 0x5110, 0x5188},
	{"NINGEN", 0xc07a, 0xc0e7, 0},
	{"OVER", 0x7c76, 0x7cea, 0x7d26},
	{"MENU", 0x5250, 0x5272, 0},
	{"MENU", 0x5292, 0x52db, 0},
	{"MENU2", 0x7de5, 0x7e0f, 0},
	{"MENU2", 0x7d44, 0, 0},
	{"MENU2", 0x7e59, 0x7e55, 0x7e51},
	{"DUNGEON", 0x7ba2, 0x7bcc, 0},
	{"DUNGEON", 0x7cf2, 0x7d2e, 0},
	{"DUNGEON", 0x7d8a, 0x7dc1, 0},
	{"DUNGEON", 0x7c0e, 0x7c72, 0},
	{"DUNGEON", 0x7e1c, 0x7e50, 0},
	{"HEIAN", 0xb10e, 0xb153, 0xb1a4},
	{"JIGOKU", 0xc085, 0xc0dd, 0},
	{"GAKI", 0xc08c, 0xc0bb, 0},
	{"CHIKUSHO", 0xc099, 0xc123, 0},
	{"SHURA", 0xc086, 0xc116, 0},
	{"TENJO", 0xc086, 0xc150, 0},
	{"EPILOGUE", 0xc337, 0xc3c2, 0xc45b},
	{"ENDING", 0xcbbb, 0xcc3b, 0xcd1d},
}

type output struct {
	name string
	data []byte
}

func extract(paths [2]string) ([]output, error) {
	var disks [2][]byte
	// Validate both disks before creating or replacing any output file.
	for i, path := range paths {
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		if len(data) != diskSize {
			return nil, fmt.Errorf("%s: disk %c must be %d bytes (got %d)", path, 'A'+i, diskSize, len(data))
		}
		disks[i] = data
	}

	files := []output{{"DRIVER.BIN", disks[0][0x24000:0x27000]}}
	for code, t := range tracks {
		b, ok := blocks[t.block]
		if !ok || b.size <= 0 || b.size+10 > 0x800 || b.offset+b.size > len(disks[b.disk]) {
			return nil, fmt.Errorf("song %02X: invalid block %s", code, t.block)
		}
		for _, p := range []uint16{t.hl, t.de, t.bc} {
			if p != 0 && (p < b.address || int(p)-int(b.address) >= b.size) {
				return nil, fmt.Errorf("song %02X: channel pointer outside block", code)
			}
		}
		data := make([]byte, 10+b.size)
		for i, word := range []uint16{b.address, uint16(b.size), t.hl, t.de, t.bc} {
			binary.LittleEndian.PutUint16(data[i*2:], word)
		}
		copy(data[10:], disks[b.disk][b.offset:b.offset+b.size])
		files = append(files, output{fmt.Sprintf("M%02X.BIN", code), data})
	}
	return files, nil
}

func run(args []string) error {
	if len(args) < 2 || len(args) > 3 {
		return fmt.Errorf("usage: gandcut A.DSK B.DSK [output-directory (default: mus)]")
	}
	files, err := extract([2]string{args[0], args[1]})
	if err != nil {
		return err
	}
	dir := "mus"
	if len(args) == 3 {
		dir = args[2]
	}
	// Also protect inputs renamed to an output name, or linked from that name.
	for _, path := range args[:2] {
		input, err := os.Stat(path)
		if err != nil {
			return err
		}
		for _, f := range files {
			outputPath := filepath.Join(dir, f.name)
			if existing, err := os.Stat(outputPath); err == nil && os.SameFile(input, existing) {
				return fmt.Errorf("output %s would overwrite input %s", outputPath, path)
			}
		}
	}
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	for _, f := range files {
		if err := os.WriteFile(filepath.Join(dir, f.name), f.data, 0644); err != nil {
			return err
		}
		fmt.Printf("%s size=0x%04X\n", f.name, len(f.data))
	}
	return nil
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "gandcut:", err)
		os.Exit(1)
	}
}
