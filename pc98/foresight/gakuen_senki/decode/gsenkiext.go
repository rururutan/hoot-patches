// gsenkiext expands the original DLZ-compressed BGM files, without renaming them.
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

type reader struct {
	data []byte
	pos  int
	bits uint16
	left int
}

func (r *reader) byte() byte {
	if r.pos >= len(r.data) {
		panic("truncated DLZ stream")
	}
	v := r.data[r.pos]
	r.pos++
	return v
}
func (r *reader) refill() { lo := r.byte(); r.bits = uint16(lo) | uint16(r.byte())<<8; r.left = 16 }
func (r *reader) bit() bool {
	v := r.bits&1 != 0
	r.bits >>= 1
	r.left--
	// The original decoder refills before reading the current token's payload.
	if r.left == 0 {
		r.refill()
	}
	return v
}
func expand(src []byte) (out []byte, err error) {
	defer func() {
		if e := recover(); e != nil {
			out = nil
			err = fmt.Errorf("%v", e)
		}
	}()
	if len(src) < 15 || !bytes.Equal(src[:6], []byte{0x9d, 0x89, 'd', 'l', 'z', 0}) {
		return nil, fmt.Errorf("not a DLZ file")
	}
	if int(binary.LittleEndian.Uint16(src[6:])) != len(src)-13 {
		return nil, fmt.Errorf("DLZ compressed size mismatch")
	}
	size := int(binary.LittleEndian.Uint16(src[11:]))
	out = make([]byte, 0, size)
	r := reader{data: src, pos: 13}
	r.refill()
	copyMatch := func(offset, n int) {
		if len(out)+n > size || len(out)+offset < 0 || offset >= 0 {
			panic("invalid DLZ match")
		}
		for i := 0; i < n; i++ {
			out = append(out, out[len(out)+offset])
		}
	}
	for tokens := 0; tokens < 1000000; tokens++ {
		if r.bit() {
			if len(out) >= size {
				panic("DLZ output overflow")
			}
			out = append(out, r.byte())
			continue
		}
		if !r.bit() {
			off := int(r.byte()) - 256
			if !r.bit() {
				if off == -1 {
					if r.bit() {
						continue
					}
					if len(out) != size {
						panic("DLZ expanded size mismatch")
					}
					return out, nil
				}
			} else {
				off -= 256
				if !r.bit() {
					off -= 1024
				}
				if !r.bit() {
					off -= 512
				}
				if !r.bit() {
					off -= 256
				}
			}
			copyMatch(off, 2)
			continue
		}
		off := int(r.byte()) - 256
		hi := 0
		if !r.bit() {
			hi++
		}
		if !r.bit() {
			off -= 512
			if !r.bit() {
				hi *= 2
				if !r.bit() {
					hi++
				}
				off -= 512
				if !r.bit() {
					hi *= 2
					if !r.bit() {
						hi++
					}
					off -= 1024
					if !r.bit() {
						off -= 2048
						hi *= 2
						if !r.bit() {
							hi++
						}
					}
				}
			}
		}
		off -= hi * 256
		n := 3
		for n < 7 && !r.bit() {
			n++
		}
		if n == 7 {
			if r.bit() {
				if r.bit() {
					n = 8
				}
			} else if r.bit() {
				n = int(r.byte()) + 17
			} else {
				n = 9
				if r.bit() {
					n += 4
				}
				if r.bit() {
					n += 2
				}
				if r.bit() {
					n++
				}
			}
		}
		copyMatch(off, n)
	}
	return nil, fmt.Errorf("too many DLZ tokens")
}
func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: gsenkiext input-directory output-directory (or input-file output-file)")
	}
	in, out := os.Args[1], os.Args[2]
	info, err := os.Stat(in)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return convert(in, out)
	}
	if err = os.MkdirAll(out, 0755); err != nil {
		return err
	}
	for i := 1; i <= 13; i++ {
		name := fmt.Sprintf("BGM%03d.MID", i)
		if err = convert(filepath.Join(in, name), filepath.Join(out, name)); err != nil {
			return err
		}
	}
	return nil
}
func convert(in, out string) error {
	a, err := filepath.Abs(in)
	if err != nil {
		return err
	}
	b, err := filepath.Abs(out)
	if err != nil {
		return err
	}
	if bytes.EqualFold([]byte(a), []byte(b)) {
		return fmt.Errorf("input and output must differ")
	}
	src, err := os.ReadFile(in)
	if err != nil {
		return err
	}
	data, err := expand(src)
	if err != nil {
		return fmt.Errorf("%s: %w", in, err)
	}
	if !bytes.HasPrefix(data, []byte("MThd")) {
		return fmt.Errorf("%s: expanded data is not SMF", in)
	}
	f, err := os.Create(out)
	if err != nil {
		return err
	}
	n, writeErr := f.Write(data)
	closeErr := f.Close()
	if writeErr != nil {
		return writeErr
	}
	if n != len(data) {
		return fmt.Errorf("short write: %s", out)
	}
	if closeErr != nil {
		return closeErr
	}
	fmt.Printf("%s: %d -> %d bytes\n", filepath.Base(in), len(src), len(data))
	return nil
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
