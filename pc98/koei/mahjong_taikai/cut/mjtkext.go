// mjtkext extracts the original non-DOS executable and its named FM bank.
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type song struct {
	Code uint16
	Name string
}

var songs = []song{
	{0x0100, "LAS"},
	{0x0101, "LAS2"},
	{0x0102, "CHINA"},
	{0x0103, "HASAN"},
	{0x0104, "MILLION"},
	{0x0105, "PRISE"},
	{0x0106, "GOLD"},
	{0x0107, "JANSO"},
	{0x0108, "SWIN"},
	{0x0109, "SLOST"},
	{0x010a, "PUNK"},
	{0x010b, "TAIKAI"},
	{0x010c, "BAKEN1"},
	{0x010d, "BAKEN2"},
	{0x010e, "BAKEN3"},
	{0x010f, "WIN"},
	{0x0111, "TOP"},
	{0x0112, "PINCH"},
	{0x0113, "HORA"},
	{0x0114, "TSUMO"},
	{0x0115, "U_HOJU"},
	{0x0116, "C_HOJU"},
	{0x0117, "YMAN"},
	{0x0200, "BG1"},
	{0x0201, "BG2"},
	{0x0202, "BG3"},
	{0x0203, "BG4"},
	{0x0204, "BG5"},
	{0x0205, "BG6"},
	{0x0206, "BG7"},
	{0x0207, "BG8"},
	{0x0208, "BG9"},
	{0x0209, "BG10"},
	{0x020a, "BG11"},
	{0x020b, "BG12"},
	{0x020c, "BG13"},
	{0x020d, "BG14"},
	{0x020e, "BG15"},
	{0x020f, "BG16"},
	{0x0210, "BG17"},
	{0x0211, "BG18"},
	{0x0118, "TAHAI"},
	{0x0119, "FURO"},
	{0x011a, "RICHI"},
	{0x011b, "DOBON"},
}

func run() error {
	if len(os.Args) != 3 {
		return fmt.Errorf("usage: mjtkext system.hdm output-directory")
	}
	disk, err := os.ReadFile(os.Args[1])
	if err != nil {
		return err
	}
	if len(disk) != 1261568 {
		return fmt.Errorf("expected 1261568-byte raw HDM, got %d", len(disk))
	}
	if !bytes.Equal(disk[0x9c00:0x9c08], []byte{0xfa, 0xfc, 0x8d, 0x06, 0xe0, 0xff, 0xb1, 0x04}) || !bytes.Equal(disk[0xac802:0xac80a], []byte("TAHAI   ")) {
		return fmt.Errorf("unsupported system disk signatures")
	}
	// Original startup selects DS=CS+0FFEh, initializes DS:0000..100Fh
	// from disk, and zeroes the BSS. The sound bank is loaded separately.
	data := make([]byte, 0x9030)
	copy(data, disk[0x19be0:0x1abf0])
	names := make(map[string]uint16)
	off := 0xac800
	for len(names) < len(songs) {
		if off+24 > len(disk) {
			return fmt.Errorf("truncated bank")
		}
		n := int(binary.LittleEndian.Uint16(disk[off:]))
		if n < 24 || off+n > len(disk) {
			return fmt.Errorf("invalid bank record at %x", off)
		}
		name := strings.TrimRight(string(disk[off+2:off+10]), " ")
		if _, exists := names[name]; exists {
			return fmt.Errorf("duplicate bank name %q", name)
		}
		names[name] = uint16(0x113e + off - 0xac800 + 2)
		off += n
	}
	if 0x113e+off-0xac800+2 > len(data) {
		return fmt.Errorf("bank too large")
	}
	copy(data[0x113e:], disk[0xac800:off])
	// Original 04E8h loader separately reads the 0600h-byte FM voice bank
	// from disk sector 02C2h into DS:513Eh. Play resolves 6-byte voice names
	// against these 32-byte records, then copies 26-byte patches to DS:106Eh.
	copy(data[0x513e:0x573e], disk[0xb0800:0xb0e00])
	// The following disk bytes are another resource, not a bank terminator.
	// Zero-filled BSS supplies the original lookup's zero-length sentinel.
	var inc strings.Builder
	inc.WriteString("; Generated from original disk bank; code, DS name pointer.\n")
	for _, s := range songs {
		ptr, ok := names[s.Name]
		if !ok {
			return fmt.Errorf("missing song %q", s.Name)
		}
		fmt.Fprintf(&inc, "        dw 0x%04x, 0x%04x ; %s\n", s.Code, ptr, s.Name)
	}
	if err = os.MkdirAll(os.Args[2], 0755); err != nil {
		return err
	}
//	files := map[string][]byte{"MJCODE.BIN": disk[0x9c00:0x19be0], "MJDATA.BIN": data, "songs.inc": []byte(inc.String())}
	files := map[string][]byte{"MJCODE.BIN": disk[0x9c00:0x19be0], "MJDATA.BIN": data}
	for name, b := range files {
		target := filepath.Join(os.Args[2], name)
		if err = os.WriteFile(target, b, 0644); err != nil {
			return fmt.Errorf("write %s: %w", target, err)
		}
	}
	fmt.Printf("Extracted original code, initialized data, and %d named sound records.\n", len(names))
	return nil
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
