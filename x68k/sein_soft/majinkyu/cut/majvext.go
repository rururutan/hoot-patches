// majvext extracts the original X-BASIC mus_* voice arrays; no dump data is used.
package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

var names = []string{"OPENING", "FIELD", "TOWN", "TOWER", "CAVE", "TELELE", "ENDING"}
var funcs = regexp.MustCompile(`(?is)func\s+mus_(\w+)\(\)(.*?)endfunc`)
var arrays = regexp.MustCompile(`(?i)dim\s+char\s+(\w+)\(4,10\)\s*=\s*\{([^}]*)\}`)
var calls = regexp.MustCompile(`(?i)m_vset\(\s*(\d+)\s*,\s*(\w+)\s*\)`)

func atomic(path string, b []byte) error {
	f, err := os.CreateTemp(filepath.Dir(path), ".majvext-*")
	if err != nil {
		return err
	}
	temp := f.Name()
	defer os.Remove(temp)
	n, err := f.Write(b)
	if err == nil && n != len(b) {
		err = io.ErrShortWrite
	}
	closeErr := f.Close()
	if err != nil {
		return err
	}
	if closeErr != nil {
		return closeErr
	}
	return os.Rename(temp, path)
}
func run(input, output string) error {
	b, err := os.ReadFile(input)
	if err != nil {
		return err
	}
	songs := map[string][]byte{}
	for _, f := range funcs.FindAllSubmatch(b, -1) {
		name := strings.ToUpper(string(f[1]))
		if _, ok := songs[name]; ok {
			return fmt.Errorf("duplicate function %s", name)
		}
		voices := map[string][]byte{}
		for _, a := range arrays.FindAllSubmatch(f[2], -1) {
			fields := strings.Split(string(a[2]), ",")
			if len(fields) != 55 {
				return fmt.Errorf("%s: expected 55 voice bytes", name)
			}
			data := make([]byte, 55)
			for i, v := range fields {
				n, e := strconv.Atoi(strings.TrimSpace(v))
				if e != nil || n < 0 || n > 255 {
					return fmt.Errorf("%s: invalid voice value", name)
				}
				data[i] = byte(n)
			}
			key := strings.ToUpper(string(a[1]))
			if _, ok := voices[key]; ok {
				return fmt.Errorf("%s: duplicate array", name)
			}
			voices[key] = data
		}
		c := calls.FindAllSubmatch(f[2], -1)
		if len(c) == 0 {
			return fmt.Errorf("%s: missing m_vset calls", name)
		}
		out := make([]byte, 8+len(c)*60)
		copy(out, "MVCE")
		binary.BigEndian.PutUint32(out[4:], uint32(len(c)))
		seen := map[int]bool{}
		for i, v := range c {
			n, e := strconv.Atoi(string(v[1]))
			data, ok := voices[strings.ToUpper(string(v[2]))]
			if e != nil || n < 1 || n > 200 || !ok || seen[n] {
				return fmt.Errorf("%s: invalid m_vset call", name)
			}
			seen[n] = true
			binary.BigEndian.PutUint32(out[8+i*60:], uint32(n))
			copy(out[12+i*60:], data)
		}
		songs[name] = out
	}
	for _, name := range names {
		if _, ok := songs[name]; !ok {
			return fmt.Errorf("missing mus_%s function", strings.ToLower(name))
		}
	}
	info, err := os.Stat(output)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return fmt.Errorf("output must be a directory")
	}
	for _, name := range names {
		if err := atomic(filepath.Join(output, name+".VCE"), songs[name]); err != nil {
			return err
		}
	}
	return nil
}
func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: majvext <MAJIN.bas> <output directory>")
		os.Exit(2)
	}
	if err := run(os.Args[1], os.Args[2]); err != nil {
		fmt.Fprintln(os.Stderr, "majvext:", err)
		os.Exit(1)
	}
	fmt.Println("Extracted 7 per-song voice files from original MAJIN.bas.")
}
