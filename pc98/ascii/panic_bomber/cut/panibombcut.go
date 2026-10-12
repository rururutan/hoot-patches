package main

import (
	"encoding/binary"
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

const (
	expectedImageSize = 0x134000
	resourceTable     = 0x400
	resourceBase      = 0x24000
)

type resource struct {
	id   int
	name string
}

var resources = []resource{
	{0x7e, "PBMDRV.BIN"},
	{0x7f, "PBMBASE.BIN"},
	{0x80, "SND01.BIN"},
	{0x81, "SND02.BIN"},
	{0x82, "SND03.BIN"},
	{0x83, "SND04.BIN"},
	{0x84, "SND05.BIN"},
	{0x85, "SND06.BIN"},
	{0x86, "SND07.BIN"},
	{0x87, "SND08.BIN"},
	{0x88, "SND09.BIN"},
	{0x89, "SND10.BIN"},
	{0x8a, "SND11.BIN"},
	{0x8b, "SND12.BIN"},
}

func extract(image []byte, outputDir string) error {
	if len(image) != expectedImageSize {
		return fmt.Errorf("unexpected image size: got %d bytes, want %d", len(image), expectedImageSize)
	}
	if string(image[2:10]) != "PANIBON " {
		return errors.New("PANIBON IPL signature not found")
	}
	if err := os.MkdirAll(outputDir, 0o755); err != nil {
		return fmt.Errorf("create output directory: %w", err)
	}

	for _, entry := range resources {
		tableOffset := resourceTable + entry.id*4
		start := int(binary.LittleEndian.Uint32(image[tableOffset:]))
		end := int(binary.LittleEndian.Uint32(image[tableOffset+4:]))
		if start < 0 || end <= start || resourceBase+end > len(image) {
			return fmt.Errorf("invalid resource %02X range: %X..%X", entry.id, start, end)
		}
		path := filepath.Join(outputDir, entry.name)
		if err := os.WriteFile(path, image[resourceBase+start:resourceBase+end], 0o644); err != nil {
			return fmt.Errorf("write %s: %w", path, err)
		}
		fmt.Printf("%s: resource %02X, %d bytes\n", entry.name, entry.id, end-start)
	}
	return nil
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "usage: %s input.hdm output-directory\n", filepath.Base(os.Args[0]))
		os.Exit(2)
	}
	image, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "read %s: %v\n", os.Args[1], err)
		os.Exit(1)
	}
	if err := extract(image, os.Args[2]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
