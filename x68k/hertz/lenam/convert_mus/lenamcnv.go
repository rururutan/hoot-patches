package main

import (
	"bytes"
	"fmt"
	"os"
	"strings"
)

func header(size string, blankLine bool) string {
	s := "(i)\r\n" +
		"(m1," + size + ")(a1,1)(m2," + size + ")(a2,2)(m3," + size + ")(a3,3)(m4," + size + ")(a4,4)\r\n" +
		"(m5," + size + ")(a5,5)(m6," + size + ")(a6,6)(m7," + size + ")(a7,7)(m8," + size + ")(a8,8)\r\n"
	if blankLine {
		s += "\r\n"
	}
	return s
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: lenamcnv input.mus output.opm [/B|/C]")
}

func splitModeC(data []byte) [][]byte {
	normalized := bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n"))
	lines := bytes.Split(normalized, []byte{'\n'})
	tracks := make([][]byte, 0, 8)
	for _, line := range lines {
		if line = trimASCII(line); len(line) != 0 {
			tracks = append(tracks, append([]byte(nil), line...))
		}
	}
	if len(tracks) == 8 {
		return tracks
	}
	return splitTracks(data, true)
}

func tempoCommand(track []byte) []byte {
	for i := 0; i+1 < len(track); i++ {
		if (track[i] == 'T' || track[i] == 't') && track[i+1] >= '0' && track[i+1] <= '9' {
			end := i + 2
			for end < len(track) && track[end] >= '0' && track[end] <= '9' {
				end++
			}
			return append([]byte(nil), track[i:end]...)
		}
	}
	return nil
}

func splitTracks(data []byte, modeB bool) [][]byte {
	tracks := make([][]byte, 1, 8)
	for i := 0; i < len(data) && len(tracks) <= 8; i++ {
		separator := data[i] == 0
		if modeB {
			separator = i+1 < len(data) && data[i] == ':' && data[i+1] == '|'
			if separator {
				tracks[len(tracks)-1] = append(tracks[len(tracks)-1], ':', '|')
				i++
			}
		}
		if separator {
			if len(tracks) == 8 {
				break
			}
			tracks = append(tracks, nil)
			for i+1 < len(data) && data[i+1] <= 0x20 {
				i++
			}
			continue
		}
		if data[i] != 0 {
			tracks[len(tracks)-1] = append(tracks[len(tracks)-1], data[i])
		}
	}
	return tracks
}

func trimASCII(b []byte) []byte {
	return bytes.Trim(b, " \t\r\n")
}

func writeTrack(out *bytes.Buffer, number int, track []byte, protectTie bool) {
	track = trimASCII(track)
	for len(track) != 0 {
		cut := len(track)
		if len(track) >= 120 {
			cut = 0
			for i := 99; i < len(track); i++ {
				c := track[i]
				if c >= 'a' && c <= 'z' {
					c -= 'a' - 'A'
				}
				// The VB6 converter checked the command line instead of the
				// preceding MML byte here, so '&' does not inhibit a split.
				if strings.ContainsRune("CDEFGABR", rune(c)) && (!protectTie || i == 0 || track[i-1] != '&') {
					cut = i
					break
				}
			}
			if cut == 0 { // Malformed input: avoid the VB6 converter's endless loop.
				cut = len(track)
			}
		}
		fmt.Fprintf(out, "(t%d) %s\r\n", number, track[:cut])
		track = track[cut:]
	}
}

func main() {
	if len(os.Args) < 3 || len(os.Args) > 4 {
		usage()
		os.Exit(2)
	}
	mode := "A"
	if len(os.Args) == 4 {
		mode = strings.ToUpper(strings.TrimPrefix(os.Args[3], "/"))
	}
	if mode != "A" && mode != "B" && mode != "C" {
		usage()
		os.Exit(2)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	var out bytes.Buffer
	modeC := mode == "C"
	if modeC {
		out.WriteString(header("8000", false))
	} else {
		out.WriteString(header("4000", true))
	}
	tracks := splitTracks(data, mode == "B")
	if modeC {
		tracks = splitModeC(data)
		if len(tracks) != 0 {
			tracks[0] = trimASCII(tracks[0])
			if len(tracks[0]) != 0 && (tracks[0][0] == 'Z' || tracks[0][0] == 'z') {
				tracks[0] = tracks[0][1:]
			}
			if tempo := tempoCommand(tracks[0]); len(tempo) != 0 {
				for i := 1; i < len(tracks); i++ {
					if len(tempoCommand(tracks[i])) == 0 {
						tracks[i] = append(append([]byte(nil), tempo...), tracks[i]...)
					}
				}
			}
		}
	}
	for i, track := range tracks {
		track = trimASCII(track)
		if len(track) == 0 {
			break
		}
		writeTrack(&out, i+1, track, modeC)
		if !modeC {
			out.WriteString("\r\n")
		}
	}
	out.WriteString("\r\n(p)\r\n")
	if err := os.WriteFile(os.Args[2], out.Bytes(), 0644); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
