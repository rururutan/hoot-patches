package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type entry struct {
	name   string
	size   int
	offset int
}

func readCString(data []byte, offset *int) (string, error) {
	if *offset >= len(data) {
		return "", fmt.Errorf("header string starts outside the file at 0x%x", *offset)
	}

	end := bytes.IndexByte(data[*offset:], 0)
	if end < 0 {
		return "", fmt.Errorf("unterminated header string at 0x%x", *offset)
	}

	value := string(data[*offset : *offset+end])
	*offset += end + 1
	return value, nil
}

func parseIndex(data []byte) ([]entry, error) {
	offset := 0
	entries := make([]entry, 0, 19)

	for {
		name, err := readCString(data, &offset)
		if err != nil {
			return nil, err
		}
		if name == "" {
			break
		}

		sizeText, err := readCString(data, &offset)
		if err != nil {
			return nil, err
		}
		size, err := strconv.Atoi(sizeText)
		if err != nil || size < 0 {
			return nil, fmt.Errorf("invalid size for %s: %q", name, sizeText)
		}
		entries = append(entries, entry{name: name, size: size})
	}

	dataOffset := offset
	for i := range entries {
		entries[i].offset = dataOffset
		dataOffset += entries[i].size
		if dataOffset > len(data) {
			return nil, fmt.Errorf("%s extends past the end of the file", entries[i].name)
		}
	}
	if dataOffset != len(data) {
		return nil, fmt.Errorf("index sizes end at 0x%x, file ends at 0x%x", dataOffset, len(data))
	}

	return entries, nil
}

func decompress(payload []byte, memberName string) ([]byte, error) {
	var window [0x800]byte
	output := make([]byte, 0, len(payload)*2)
	source := 0
	windowPosition := 0

	for source < len(payload) {
		controlOffset := source
		control := payload[source]
		source++

		if control&0x80 == 0 {
			length := int(control) + 1
			if source+length > len(payload) {
				return nil, fmt.Errorf("%s: truncated literal run at 0x%x", memberName, controlOffset)
			}
			for i := 0; i < length; i++ {
				value := payload[source]
				source++
				output = append(output, value)
				window[windowPosition] = value
				windowPosition = (windowPosition + 1) & 0x7ff
			}
			continue
		}

		if source >= len(payload) {
			return nil, fmt.Errorf("%s: truncated match at 0x%x", memberName, controlOffset)
		}
		code := uint16(control)<<8 | uint16(payload[source])
		source++
		distance := int(code >> 4)
		length := int(code&0x0f) + 3
		matchPosition := (windowPosition - distance) & 0x7ff

		for i := 0; i < length; i++ {
			value := window[matchPosition]
			matchPosition = (matchPosition + 1) & 0x7ff
			output = append(output, value)
			window[windowPosition] = value
			windowPosition = (windowPosition + 1) & 0x7ff
		}
	}

	return output, nil
}

func outputName(memberName string) string {
	base := filepath.Base(memberName)
	ext := filepath.Ext(base)
	return strings.ToUpper(strings.TrimSuffix(base, ext)) + ".MDT"
}

func run() error {
	inputPath := "WOB.LZS"
	outputDir := "decoded"
	if len(os.Args) >= 2 {
		inputPath = os.Args[1]
	}
	if len(os.Args) >= 3 {
		outputDir = os.Args[2]
	}
	if len(os.Args) > 3 {
		return fmt.Errorf("usage: %s [WOB.LZS [output_directory]]", filepath.Base(os.Args[0]))
	}

	archive, err := os.ReadFile(inputPath)
	if err != nil {
		return fmt.Errorf("read %s: %w", inputPath, err)
	}
	entries, err := parseIndex(archive)
	if err != nil {
		return fmt.Errorf("parse %s: %w", inputPath, err)
	}
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return fmt.Errorf("create %s: %w", outputDir, err)
	}

	for _, item := range entries {
		payload := archive[item.offset : item.offset+item.size]
		decoded, err := decompress(payload, item.name)
		if err != nil {
			return err
		}
		name := outputName(item.name)
		if err := os.WriteFile(filepath.Join(outputDir, name), decoded, 0644); err != nil {
			return fmt.Errorf("write %s: %w", name, err)
		}
		fmt.Printf("%s: %d -> %d bytes from 0x%x\n", name, item.size, len(decoded), item.offset)
	}

	fmt.Printf("Extracted and decompressed %d songs to %s\n", len(entries), outputDir)
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
