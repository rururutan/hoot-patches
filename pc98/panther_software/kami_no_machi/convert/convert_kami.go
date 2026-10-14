// Convert music files from 神の聖都 for use with the hoot
package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var songName = regexp.MustCompile(`(?i)^(KM[0-9]+MB?|SENT1|SENT2|SENT3|KTTL|NOTONM)$`)

var tableOverrides = map[string][]int{
	"SENT1": {0, 0x25c, 0x438, 0xc6a, 0xe20, 0xffff},
	"KM2M":  {0, 0x184, 0x28a, 0x518, 0x62a, 0x773},
	"KM3M":  {0, 0x082, 0x102, 0x28a, 0xffff, 0xffff},
	"KM4M":  {0, 0x088, 0x212, 0x410, 0x5eb, 0xffff},
	"KM29M": {0, 0x196, 0x328, 0xffff, 0x422, 0x474},
	"KM30M": {0, 0x02e, 0x05a, 0x168, 0x1ca, 0x22c},
}

func convert(raw []byte, name string) ([]byte, error) {
	if len(raw) < 8 {
		return nil, fmt.Errorf("music file is too short")
	}
	data := raw[4:]
	voiceSize := -1
	limit := len(data)
	if limit > 0x400 {
		limit = 0x400
	}
	for offset := 0; offset < limit; offset += 0x40 {
		if data[offset] == 0x83 {
			voiceSize = offset
			break
		}
	}
	if voiceSize < 0 {
		return nil, fmt.Errorf("music stream was not found")
	}

	var ends []int
	for i, value := range data[voiceSize:] {
		if value == 0xff {
			ends = append(ends, i+1)
		}
	}
	if len(ends) < 2 {
		return nil, fmt.Errorf("FM stream table was not found")
	}
	table := []int{0, ends[0], ends[1]}
	for _, offset := range ends[2:] {
		if len(table) == 6 {
			break
		}
		if voiceSize+offset < len(data) && data[voiceSize+offset] == 0x88 {
			table = append(table, offset)
		}
	}
	for len(table) < 6 {
		table = append(table, 0xffff)
	}
	// Some PSG streams use setup commands other than the usual 88h. The
	// overrides are copied from the game's own table in MKMDOS.COM.
	if override, ok := tableOverrides[strings.ToUpper(filepath.Base(name))]; ok {
		table = override
	}
	if voiceSize > 0xffff {
		return nil, fmt.Errorf("voice area is too large")
	}
	for _, offset := range table {
		if offset > 0xffff {
			return nil, fmt.Errorf("music stream offset is too large")
		}
	}

	out := make([]byte, 0x20+len(data))
	copy(out, "KAMI")
	binary.LittleEndian.PutUint16(out[4:], uint16(voiceSize))
	for i, offset := range table {
		binary.LittleEndian.PutUint16(out[6+i*2:], uint16(offset))
	}
	copy(out[0x20:], data)
	return out, nil
}

func convertFile(input, output string) error {
	raw, err := os.ReadFile(input)
	if err != nil {
		return err
	}
	converted, err := convert(raw, filepath.Base(input))
	if err != nil {
		return fmt.Errorf("%s: %w", input, err)
	}
	if err := os.MkdirAll(filepath.Dir(output), 0755); err != nil {
		return err
	}
	if err := os.WriteFile(output, converted, 0644); err != nil {
		return err
	}
	fmt.Printf("%s: %d bytes\n", filepath.Base(output), len(converted))
	return nil
}

func run(args []string) error {
	if len(args) != 2 {
		return fmt.Errorf("usage: convert_kami input-file output-file\n       convert_kami input-directory output-directory")
	}
	info, err := os.Stat(args[0])
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return convertFile(args[0], args[1])
	}
	entries, err := os.ReadDir(args[0])
	if err != nil {
		return err
	}
	count := 0
	for _, entry := range entries {
		if entry.IsDir() || !songName.MatchString(entry.Name()) {
			continue
		}
		if err := convertFile(filepath.Join(args[0], entry.Name()), filepath.Join(args[1], strings.ToUpper(entry.Name()))); err != nil {
			return err
		}
		count++
	}
	if count == 0 {
		return fmt.Errorf("no KM music files were found in %s", args[0])
	}
	return nil
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
