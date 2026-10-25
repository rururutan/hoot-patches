package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

func decode(src []byte) ([]byte, error) {
	if len(src) < 4 {
		return nil, errors.New("file is shorter than the 4-byte header")
	}
	outSize := int(binary.BigEndian.Uint32(src[:4]))
	out := make([]byte, 0, outSize)
	dict := make([]byte, 4096)
	dictPos := 0xfee
	pos := 4

	for pos < len(src) && len(out) < outSize {
		flags := src[pos]
		pos++
		for bit := 0; bit < 8 && pos < len(src) && len(out) < outSize; bit++ {
			if flags&1 != 0 {
				b := src[pos]
				pos++
				out = append(out, b)
				dict[dictPos] = b
				dictPos = (dictPos + 1) & 0xfff
			} else {
				if pos+2 > len(src) {
					return nil, errors.New("truncated dictionary reference")
				}
				lo, hi := src[pos], src[pos+1]
				pos += 2
				from := int(lo) | int(hi&0xf0)<<4
				count := int(hi&0x0f) + 3
				for i := 0; i < count && len(out) < outSize; i++ {
					b := dict[(from+i)&0xfff]
					out = append(out, b)
					dict[dictPos] = b
					dictPos = (dictPos + 1) & 0xfff
				}
			}
			flags >>= 1
		}
	}
	if len(out) != outSize {
		return nil, fmt.Errorf("decoded %d bytes; header requires %d", len(out), outSize)
	}
	return out, nil
}

func readFile(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open input %q: %w", path, err)
	}
	info, err := f.Stat()
	if err != nil {
		_ = f.Close()
		return nil, fmt.Errorf("stat input %q: %w", path, err)
	}
	if !info.Mode().IsRegular() {
		_ = f.Close()
		return nil, fmt.Errorf("input %q is not a regular file", path)
	}
	data, readErr := io.ReadAll(f)
	closeErr := f.Close()
	if readErr != nil {
		return nil, fmt.Errorf("read input %q: %w", path, readErr)
	}
	if closeErr != nil {
		return nil, fmt.Errorf("close input %q: %w", path, closeErr)
	}
	return data, nil
}

func sameFileName(a, b string) bool {
	a, errA := filepath.Abs(a)
	b, errB := filepath.Abs(b)
	return errA == nil && errB == nil && strings.EqualFold(filepath.Clean(a), filepath.Clean(b))
}

func writeFile(path string, data []byte) error {
	parent := filepath.Dir(path)
	if err := os.MkdirAll(parent, 0o755); err != nil {
		return fmt.Errorf("create output directory %q: %w", parent, err)
	}
	if info, err := os.Stat(path); err == nil && info.IsDir() {
		return fmt.Errorf("output %q is a directory", path)
	} else if err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("stat output %q: %w", path, err)
	}
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o644)
	if err != nil {
		return fmt.Errorf("open output %q: %w", path, err)
	}
	written := 0
	for written < len(data) {
		n, writeErr := f.Write(data[written:])
		written += n
		if writeErr != nil {
			_ = f.Close()
			return fmt.Errorf("write output %q after %d of %d bytes: %w", path, written, len(data), writeErr)
		}
		if n == 0 {
			_ = f.Close()
			return fmt.Errorf("write output %q stopped after %d of %d bytes", path, written, len(data))
		}
	}
	if err := f.Sync(); err != nil {
		_ = f.Close()
		return fmt.Errorf("flush output %q: %w", path, err)
	}
	if err := f.Close(); err != nil {
		return fmt.Errorf("close output %q: %w", path, err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("verify output %q: %w", path, err)
	}
	if info.Size() != int64(len(data)) {
		return fmt.Errorf("verify output %q: wrote %d bytes, file size is %d", path, len(data), info.Size())
	}
	return nil
}

func main() {
	outPath := flag.String("o", "", "output file or output directory when decoding multiple inputs")
	flag.Parse()
	inputs := flag.Args()
	if len(inputs) == 0 {
		fmt.Fprintln(os.Stderr, "usage: lnmext input.mcp [output.mdt]")
		fmt.Fprintln(os.Stderr, "       lnmext -o output input.mcp [input.mcp ...]")
		os.Exit(2)
	}
	positionalOutput := ""
	if *outPath == "" && len(inputs) == 2 {
		positionalOutput = inputs[1]
		inputs = inputs[:1]
	} else if *outPath == "" && len(inputs) > 2 {
		fmt.Fprintln(os.Stderr, "multiple inputs require -o output_directory")
		os.Exit(2)
	}

	for _, input := range inputs {
		src, err := readFile(input)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		decoded, err := decode(src)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", input, err)
			os.Exit(1)
		}

		dst := positionalOutput
		if dst == "" {
			dst = *outPath
		}
		if dst == "" {
			ext := filepath.Ext(input)
			dst = strings.TrimSuffix(input, ext) + ".MDT"
		} else if len(inputs) > 1 {
			base := strings.TrimSuffix(filepath.Base(input), filepath.Ext(input)) + ".MDT"
			dst = filepath.Join(dst, base)
		}
		if sameFileName(input, dst) {
			fmt.Fprintf(os.Stderr, "input and output are the same file: %s\n", input)
			os.Exit(1)
		}
		if err := writeFile(dst, decoded); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		fmt.Printf("%s -> %s (%d bytes)\n", input, dst, len(decoded))
	}
}
