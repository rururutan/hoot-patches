package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

const (
	diskSize = 154 * 8 * 1024
	dirOff   = 0x2000
	sector   = 1024
)

func unpack(src []byte) ([]byte, error) {
	if len(src) < 8 {
		return nil, errors.New("compressed file is shorter than its header")
	}
	size := int(binary.BigEndian.Uint32(src[4:8]))
	if size < 0 || size > 16*1024*1024 {
		return nil, fmt.Errorf("invalid expanded size %d", size)
	}
	dict := make([]byte, 0x1000)
	p := 0
	for i := 0; i < 0x100; i++ {
		for j := 0; j < 13; j++ {
			dict[p] = byte(i)
			p++
		}
	}
	for i := 0; i <= 0xff; i++ {
		dict[p] = byte(i)
		p++
	}
	for i := 0xff; i >= 0; i-- {
		dict[p] = byte(i)
		p++
	}
	for i := 0; i < 0x80; i++ {
		dict[p] = 0
		p++
	}
	for i := 0; i < 0x6e; i++ {
		dict[p] = 0x20
		p++
	}

	out := make([]byte, 0, size)
	// The original routine starts writing at the end of the initialized
	// dictionary ($fee), not at zero.  Matches may refer to the seeded area
	// immediately, so resetting this position corrupts both data and code.
	sp, dp, flags := 8, p, byte(0x80)
	var bits byte
	for len(out) < size {
		flags = (flags << 1) | (flags >> 7)
		if flags&1 != 0 {
			if sp >= len(src) {
				return nil, errors.New("truncated flag byte")
			}
			bits = src[sp]
			sp++
		}
		if sp >= len(src) {
			return nil, errors.New("truncated data byte")
		}
		data := src[sp]
		sp++
		if bits&flags != 0 {
			out = append(out, data)
			dict[dp] = data
			dp = (dp + 1) & 0xfff
			continue
		}
		if sp >= len(src) {
			return nil, errors.New("truncated match")
		}
		lengthByte := src[sp]
		sp++
		off := (int(lengthByte&0xf0) << 4) | int(data)
		length := int(lengthByte&0x0f) + 3
		for i := 0; i < length && len(out) < size; i++ {
			data = dict[off]
			off = (off + 1) & 0xfff
			out = append(out, data)
			dict[dp] = data
			dp = (dp + 1) & 0xfff
		}
	}
	return out, nil
}

func main() {
	outDir := flag.String("o", ".", "output directory")
	flag.Parse()
	if flag.NArg() != 1 {
		fmt.Fprintln(os.Stderr, "usage: extract_tmb [-o output-directory] MUSICBOX.2HD")
		os.Exit(2)
	}
	b, err := os.ReadFile(flag.Arg(0))
	if err != nil {
		fatal(err)
	}
	base := 0
	if len(b) >= 0xb7 && string(b[0xab:0xb7]) == "DIFC HEADER  " {
		base = 0x100
	}
	if len(b)-base != diskSize {
		fatal(fmt.Errorf("unexpected disk image size: got %d, want %d", len(b)-base, diskSize))
	}
	if err := os.MkdirAll(*outDir, 0755); err != nil {
		fatal(err)
	}

	seen := make(map[byte]bool)
	for i := 0; i < 254; i++ {
		p := base + dirOff + i*4
		track, sec, count, no := b[p], b[p+1], b[p+2], b[p+3]
		// The first four bytes are a volume signature, not a file record.
		if i == 0 {
			continue
		}
		if track == 0 && sec == 0 && count == 0 && no == 0 {
			continue
		}
		if seen[no] {
			fatal(fmt.Errorf("duplicate file number %02x", no))
		}
		seen[no] = true
		start := base + (int(track)*8+int(sec)-1)*sector
		end := start + int(count)*sector
		if sec < 1 || sec > 8 || start < base || end > len(b) {
			fatal(fmt.Errorf("invalid directory entry %d", i))
		}
		data := b[start:end]
		name := fmt.Sprintf("file%03x", no)
		switch {
		case no == 8:
			name = "driver"
			data, err = unpack(data)
		case no == 2:
			name = "adpcm"
			data, err = unpack(data)
		case no >= 0x40 && no <= 0xee:
			name = fmt.Sprintf("sound%03x", no)
		case (no >= 1 && no <= 0x21) || no == 0xf8 || no >= 0xfe:
			name = fmt.Sprintf("pack%03x", no)
			data, err = unpack(data)
		}
		if err != nil {
			fatal(fmt.Errorf("file %02x: %w", no, err))
		}
		if err = os.WriteFile(filepath.Join(*outDir, name), data, 0644); err != nil {
			fatal(err)
		}
	}
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "extract_tmb:", err)
	os.Exit(1)
}
