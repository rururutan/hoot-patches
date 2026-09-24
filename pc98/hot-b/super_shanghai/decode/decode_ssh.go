package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

type decoder struct {
	input  []byte
	pos    int
	flags  uint16
	bits   int
	output []byte
}

func (d *decoder) readByte() (byte, error) {
	if d.pos >= len(d.input) {
		return 0, fmt.Errorf("unexpected end of compressed data at 0x%x", d.pos)
	}
	value := d.input[d.pos]
	d.pos++
	return value, nil
}

func (d *decoder) readWord() (uint16, error) {
	if d.pos+2 > len(d.input) {
		return 0, fmt.Errorf("unexpected end of compressed data at 0x%x", d.pos)
	}
	value := binary.LittleEndian.Uint16(d.input[d.pos:])
	d.pos += 2
	return value, nil
}

// readBit reproduces the SHR BP,1 control-bit sequence in DE.EXE at 0x0B78.
func (d *decoder) readBit() (bool, error) {
	if d.bits == 0 {
		flags, err := d.readWord()
		if err != nil {
			return false, err
		}
		d.flags = flags
		d.bits = 16
	}
	value := d.flags&1 != 0
	d.flags >>= 1
	d.bits--
	// DE.EXE fetches the following flag word immediately after consuming the
	// 16th bit, before handling the current token.  This matters because the
	// next compressed bytes are already the new flags when that token reads
	// its literal or back-reference payload.
	if d.bits == 0 {
		flags, err := d.readWord()
		if err != nil {
			return false, err
		}
		d.flags = flags
		d.bits = 16
	}
	return value, nil
}

func (d *decoder) copyBack(distance, length int) error {
	if distance >= 0 || -distance > len(d.output) {
		return fmt.Errorf("invalid back-reference %d at output 0x%x", distance, len(d.output))
	}
	for i := 0; i < length; i++ {
		source := len(d.output) + distance
		if source < 0 || source >= len(d.output) {
			return fmt.Errorf("invalid back-reference source at output 0x%x", len(d.output))
		}
		d.output = append(d.output, d.output[source])
	}
	return nil
}

// decompress implements the LZSS routine in DE.EXE at file offset 0x0B46.
func decompress(input []byte) ([]byte, int, error) {
	d := decoder{input: input}
	for {
		literal, err := d.readBit()
		if err != nil {
			return nil, 0, err
		}
		if literal {
			value, err := d.readByte()
			if err != nil {
				return nil, 0, err
			}
			d.output = append(d.output, value)
			continue
		}

		longForm, err := d.readBit()
		if err != nil {
			return nil, 0, err
		}
		if !longForm {
			first, err := d.readBit()
			if err != nil {
				return nil, 0, err
			}
			second, err := d.readBit()
			if err != nil {
				return nil, 0, err
			}
			length := 2
			if first { length += 2 }
			if second { length++ }
			offset, err := d.readByte()
			if err != nil {
				return nil, 0, err
			}
			if err := d.copyBack(int(int16(0xff00|uint16(offset))), length); err != nil {
				return nil, 0, err
			}
			continue
		}

		code, err := d.readWord()
		if err != nil {
			return nil, 0, err
		}
		lengthCode := byte(code >> 8 & 7)
		distance := int(int16(uint16(code&0xff) | uint16(0xe0|byte(code>>11))<<8))
		if lengthCode != 0 {
			if err := d.copyBack(distance, int(lengthCode)+2); err != nil {
				return nil, 0, err
			}
			continue
		}

		extendedLength, err := d.readByte()
		if err != nil {
			return nil, 0, err
		}
		switch extendedLength {
		case 0:
			return d.output, d.pos, nil
		case 1:
			// The original advances DS/ES by 0x200 paragraphs here, to keep
			// its 16-bit source and destination offsets in range. A Go slice
			// is contiguous, so this marker needs no data operation.
			continue
		default:
			if err := d.copyBack(distance, int(extendedLength)+1); err != nil {
				return nil, 0, err
			}
		}
	}
}

func run() error {
	inputPath, outputDir := "SHANG.STD", "decoded"
	if len(os.Args) >= 2 { inputPath = os.Args[1] }
	if len(os.Args) >= 3 { outputDir = os.Args[2] }
	if len(os.Args) > 3 {
		return fmt.Errorf("usage: %s [input_file [output_directory]]", filepath.Base(os.Args[0]))
	}

	input, err := os.ReadFile(inputPath)
	if err != nil {
		return fmt.Errorf("read %s: %w", inputPath, err)
	}
	output, consumed, err := decompress(input)
	if err != nil {
		return fmt.Errorf("decompress %s: %w", inputPath, err)
	}
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return fmt.Errorf("create %s: %w", outputDir, err)
	}
	// DE.EXE uses the same compressor for MIDI, MFB, and other asset files.
	// Keep the input basename so the result can be used directly by HOOT.
	outputPath := filepath.Join(outputDir, filepath.Base(inputPath))
	if err := os.WriteFile(outputPath, output, 0644); err != nil {
		return fmt.Errorf("write %s: %w", outputPath, err)
	}
	fmt.Printf("%s -> %s (%d bytes; consumed 0x%x of 0x%x bytes)\n", inputPath, outputPath, len(output), consumed, len(input))
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
