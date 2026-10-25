// Extract the PC-9801 Dungeon Conquest DC.DAT archive.
// Build: go build -trimpath -ldflags="-s -w" -o extract_dc.exe extract_dc.go

package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// decompress matches OPEN.EXE's MSB-first LZ decoder, including EOF in a token.
func decompress(data []byte) []byte {
	position := 0
	bits := func(count int) (int, bool) {
		if position+count > len(data)*8 {
			return 0, false
		}
		value := 0
		for i := 0; i < count; i++ {
			value = value<<1 | int((data[position/8]>>uint(7-position%8))&1)
			position++
		}
		return value, true
	}
	var window [1024]byte
	write := 0
	output := make([]byte, 0)
	for {
		flag, ok := bits(1)
		if !ok {
			return output
		}
		if flag == 0 {
			value, ok := bits(8)
			if !ok {
				return output
			}
			output = append(output, byte(value))
			window[write] = byte(value)
			write = (write + 1) & 1023
		} else {
			offset, ok := bits(10)
			if !ok {
				return output
			}
			length, ok := bits(4)
			if !ok {
				return output
			}
			read := (write + offset) & 1023
			for i := 0; i < length+2; i++ {
				value := window[read]
				read = (read + 1) & 1023
				output = append(output, value)
				window[write] = value
				write = (write + 1) & 1023
			}
		}
	}
}

type archiveEntry struct {
	offset int
	packed []byte
}

func readArchive(data []byte) ([]archiveEntry, error) {
	if len(data) < 2 {
		return nil, fmt.Errorf("missing archive header")
	}
	tableSize := int(binary.LittleEndian.Uint16(data))
	base := 2 + tableSize
	if tableSize == 0 || base > len(data) {
		return nil, fmt.Errorf("invalid packed offset table size")
	}
	table := decompress(data[2:base])
	if len(table) == 0 || len(table)%4 != 0 {
		return nil, fmt.Errorf("offset table is not an array of uint32 values")
	}
	previous := 0
	entries := make([]archiveEntry, 0, len(table)/4)
	for i := 0; i < len(table); i += 4 {
		end64 := uint64(binary.LittleEndian.Uint32(table[i:]))
		if end64 <= uint64(previous) || end64 > uint64(len(data)-base) {
			return nil, fmt.Errorf("invalid extent for entry %d", i/4)
		}
		end := int(end64)
		entries = append(entries, archiveEntry{base + previous, data[base+previous : base+end]})
		previous = end
	}
	if base+previous != len(data) {
		return nil, fmt.Errorf("data remains after the last archive entry")
	}
	return entries, nil
}

func entryKind(id int) string {
	// 141_bank.bin is SE, 154_bank.bin is voices.
	if id == 141 {
		return "se"
	}
	if id == 154 {
		return "tone"
	}
	if id >= 140 && id <= 160 {
		return "seq"
	}
	return "data"
}

type manifestEntry struct {
	ID            int               `json:"id"`
	Kind          string            `json:"kind"`
	File          string            `json:"file"`
	Offset        int               `json:"offset"`
	PackedSize    int               `json:"packed_size"`
	Size          int               `json:"size"`
	SHA256        string            `json:"sha256"`
	MemoryMatches map[string]string `json:"memory_matches"`
}

type manifest struct {
	ArchiveSHA256 string          `json:"archive_sha256"`
	EntryCount    int             `json:"entry_count"`
	Entries       []manifestEntry `json:"entries"`
}

type memoryDump struct {
	name string
	data []byte
}

func extract(archive, output, memoryDir string, audioOnly bool) error {
	data, err := os.ReadFile(archive)
	if err != nil {
		return err
	}
	entries, err := readArchive(data)
	if err != nil {
		return err
	}
	var memories []memoryDump
	if memoryDir != "" {
		files, err := os.ReadDir(memoryDir)
		if err != nil {
			return err
		}
		for _, file := range files {
			match, _ := filepath.Match("memory_*.bin", file.Name())
			if !match || file.IsDir() {
				continue
			}
			content, err := os.ReadFile(filepath.Join(memoryDir, file.Name()))
			if err != nil {
				return err
			}
			memories = append(memories, memoryDump{file.Name(), content})
		}
		if len(memories) == 0 {
			return fmt.Errorf("no memory_*.bin files in --memory-dir")
		}
	}
	output = filepath.Clean(output)
	if err := os.MkdirAll(filepath.Dir(output), 0755); err != nil {
		return err
	}
	// Refuse to overwrite existing extraction results or source files.
	if err := os.Mkdir(output, 0755); err != nil {
		return err
	}
	result := manifest{fmt.Sprintf("%x", sha256.Sum256(data)), len(entries), []manifestEntry{}}
	for id, entry := range entries {
		kind := entryKind(id)
		if audioOnly && kind == "data" {
			continue
		}
		unpacked := decompress(entry.packed)
		filename := fmt.Sprintf("%03d_%s.bin", id, kind)
		if err := os.WriteFile(filepath.Join(output, filename), unpacked, 0644); err != nil {
			return err
		}
		matches := make(map[string]string)
		for _, memory := range memories {
			if len(unpacked) > 0 {
				if address := bytes.Index(memory.data, unpacked); address >= 0 {
					matches[memory.name] = fmt.Sprintf("0x%05X", address)
				}
			}
		}
		result.Entries = append(result.Entries, manifestEntry{
			id, kind, filename, entry.offset, len(entry.packed), len(unpacked),
			fmt.Sprintf("%x", sha256.Sum256(unpacked)), matches,
		})
	}
	encoded, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(output, "manifest.json"), append(encoded, '\n'), 0644); err != nil {
		return err
	}
	fmt.Printf("Extracted %d / %d entries to %s\n", len(result.Entries), len(entries), output)
	return nil
}

const usage = `Dungeon Conquest (PC-9801) DC.DAT extractor
Usage: extract_dc [options] <DC.DAT> <new-output-directory>

Options may also follow the positional arguments.
  --audio-only       Extract 19 sequences, SE (141), and voices (154) only
  -h, --help         Show this help
  --                 Treat remaining arguments as paths
`

func run(args []string) error {
	var paths []string
	var memoryDir string
	audioOnly, pathsOnly := false, false
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if pathsOnly {
			paths = append(paths, arg)
			continue
		}
		switch {
		case arg == "-h" || arg == "--help":
			fmt.Print(usage)
			return nil
		case arg == "--":
			pathsOnly = true
		case arg == "--audio-only":
			audioOnly = true
		case arg == "--memory-dir":
			i++
			if i == len(args) || args[i] == "" || strings.HasPrefix(args[i], "--") {
				return fmt.Errorf("--memory-dir requires a directory")
			}
			memoryDir = args[i]
		case strings.HasPrefix(arg, "--memory-dir="):
			memoryDir = strings.TrimPrefix(arg, "--memory-dir=")
			if memoryDir == "" {
				return fmt.Errorf("--memory-dir requires a directory")
			}
		case strings.HasPrefix(arg, "-"):
			return fmt.Errorf("unknown option: %s", arg)
		default:
			paths = append(paths, arg)
		}
	}
	if len(paths) != 2 || paths[0] == "" || paths[1] == "" {
		return fmt.Errorf("expected DC.DAT and a new output directory; use --help for usage")
	}
	return extract(paths[0], paths[1], memoryDir, audioOnly)
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "extract_dc:", err)
		os.Exit(1)
	}
}
