package main

import (
	"encoding/binary"
	"fmt"
	"log"
	"os"
	"path/filepath"
)

const fileInfoSize = 6 // WORD flag + WORD size1 + WORD size2

// EsFile で名前だけを保持しておきます。
// サイズはループ中で取得します。
type EsFile struct {
	Name string
}

func cutter(name string, data []byte) {
	if len(data) < 2 {
		fmt.Printf("%s : not onion's archive!\n", name)
		return
	}
	// MZ チェック (D の input[0] != 'M' && input[1] != 'Z')
	if data[0] != 'M' || data[1] != 'Z' {
		fmt.Printf("%s : not onion's archive!\n", name)
		return
	}

	// -------------------- file list offset --------------------
	// fn_ofs  = ((input[3] << 8) | input[2]) +
	//          (((input[5] << 8) | input[4]) - 1) << 9;
	low  := uint32(data[2]) | uint32(data[3])<<8
	high := uint32(data[4]) | uint32(data[5])<<8
	fnOfs := low + ((high-1) << 9)

	// -------------------- read file names --------------------
	fileInfos := make([]EsFile, 0)
	workofs := fnOfs + 4 // +4 is fixed header
	for workofs < uint32(len(data)) && data[workofs] != 0 {
		start := workofs
		for data[workofs] != 0 {
			workofs++
		}
		nameBytes := data[start:workofs]
		fileInfos = append(fileInfos, EsFile{Name: string(nameBytes)})
		workofs++ // skip the terminating NUL
	}
	totalCount := len(fileInfos)

	// -------------------- calculate offsets --------------------
	// fs_ofs = ++workofs;  // after the final NUL
	// fd_ofs = fs_ofs + (FILEINFO_SIZE * totalcount);
	fsOfs := workofs
	fdOfs := fsOfs + uint32(fileInfoSize*totalCount)

	fmt.Printf("\n[%s]\nfile name     : offset  : size\n-------------------------------", name)

	// -------------------- extract files --------------------
	dataofs := fdOfs
	workofs = fsOfs

	for i := 0; i < totalCount; i++ {
		if int(workofs+3) >= len(data) {
			log.Printf("invalid file info for %s\n", fileInfos[i].Name)
			break
		}
		size := binary.LittleEndian.Uint16(data[workofs+2 : workofs+4]) // size1
		// (size2 and flags are ignored)
		if int(dataofs)+int(size) > len(data) {
			log.Printf("data overflow for %s\n", fileInfos[i].Name)
			break
		}
		fmt.Printf("%13s : 0x%05x : %5d\n", fileInfos[i].Name, dataofs, size)

		// create directory if needed
		if dir := filepath.Dir(fileInfos[i].Name); dir != "." {
			if err := os.MkdirAll(dir, 0755); err != nil {
				log.Printf("cannot create dir %s: %v\n", dir, err)
			}
		}

		// write file
		if err := os.WriteFile(fileInfos[i].Name, data[dataofs:dataofs+uint32(size)], 0644); err != nil {
			log.Printf("cannot write %s: %v\n", fileInfos[i].Name, err)
		}

		dataofs += uint32(size)
		workofs += fileInfoSize
	}
}

func usage(name string) {
	fmt.Printf("usage: %s [filename]\n", name)
}

func main() {
	if len(os.Args) < 2 {
		usage(filepath.Base(os.Args[0]))
		return
	}

	for _, arg := range os.Args[1:] {
		// read the whole file
		data, err := os.ReadFile(arg)
		if err != nil {
			log.Printf("cannot read %s: %v\n", arg, err)
			continue
		}
		cutter(arg, data)
	}
}
