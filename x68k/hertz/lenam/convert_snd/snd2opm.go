package main

import (
	"bufio"
	"fmt"
	"os"
)

func usage() {
	fmt.Fprintln(os.Stderr, "usage: snd2opm input.snd output.opm")
}

func writeVoice(w *bufio.Writer, number int, values []int) error {
	if _, err := fmt.Fprintf(w, "(v%d,0", number); err != nil {
		return err
	}
	for _, v := range values {
		if _, err := fmt.Fprintf(w, ",%d", v); err != nil {
			return err
		}
	}
	_, err := fmt.Fprint(w, ")\r\n")
	return err
}

func convert55(w *bufio.Writer, data []byte) error {
	for n := 0; n < len(data)/55; n++ {
		values := make([]int, 55)
		for i, b := range data[n*55 : (n+1)*55] {
			values[i] = int(b)
		}
		if err := writeVoice(w, n+1, values); err != nil {
			return err
		}
	}
	return nil
}

// The Opening Disk editor stores one voice in an 80-byte record.  Bytes
// 0..9 are its name; the old converter used byte 0 as the OPM connection
// value.  Operator parameters at 10..53 are transposed from parameter-major
// to operator-major order.  Bytes 54..66 hold the common voice parameters.
func convert80(w *bufio.Writer, data []byte) error {
	for n := 0; n < len(data)/80; n++ {
		r := data[n*80 : (n+1)*80]
		values := []int{
			int(r[54])*8 + int(r[55]),
			int(r[65]), int(r[56]), int(r[64]), int(r[57]),
			int(r[60]), int(r[61]), int(r[58]), int(r[59]), int(r[66]),
			int(r[0]),
		}
		for column := 0; column < 4; column++ {
			for i := 10 + column; i <= 53; i += 4 {
				values = append(values, int(r[i]))
			}
		}
		if err := writeVoice(w, n+1, values); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	if len(os.Args) != 3 {
		usage()
		os.Exit(2)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	out, err := os.Create(os.Args[2])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	w := bufio.NewWriter(out)
	switch {
	case len(data)%80 == 0:
		err = convert80(w, data)
	case len(data)%55 == 0:
		err = convert55(w, data)
	default:
		err = fmt.Errorf("unsupported SND size %d (not a multiple of 55 or 80)", len(data))
	}
	if err == nil {
		_, err = fmt.Fprint(w, "\r\n")
	}
	if flushErr := w.Flush(); err == nil {
		err = flushErr
	}
	if closeErr := out.Close(); err == nil {
		err = closeErr
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
