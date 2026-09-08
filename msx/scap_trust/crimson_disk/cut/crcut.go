// MSX bsave header cutter
//
// 7byteのヘッダ
// 00 : FE
// 01 : ロードアドレス(LE)
// 03 : エンドアドレス(LE)
// 05 : ロードアドレス(LE)
//
package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("usage: bsavcut <file> [<file> ...]")
		return
	}

	fmt.Println("+--------+--------+--------+")
	fmt.Println("| Offset | Size   | Run    |")
	fmt.Println("+--------+--------+--------+")

	// すべてのファイルを処理
	for _, path := range os.Args[1:] {
		if err := processFile(path); err != nil {
			fmt.Fprintf(os.Stderr, "error processing %s: %v\n", path, err)
		}
	}

	fmt.Println("+--------+--------+--------+")
}

func processFile(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read file: %w", err)
	}

	if len(data) < 7 {
		return fmt.Errorf("file too short (must be at least 7 bytes)")
	}

	// 先頭 0xFE チェック
	if data[0] != 0xfe {
		fmt.Println("illegal data.")
		return nil
	}

	// 2 バイトずつ little‑endian で読み取る
	dataOfs := binary.LittleEndian.Uint16(data[1:3])
	dataEnd := binary.LittleEndian.Uint16(data[3:5])
	runAdr := binary.LittleEndian.Uint16(data[5:7])
	dataSize := dataEnd - dataOfs + 1

	fmt.Printf("| 0x%04x | 0x%04x | 0x%04x |\n", dataOfs, dataSize, runAdr)

	// dataSize が 0 なら何もしない
	if dataSize == 0 {
		return nil
	}

	// 7 バイトのヘッダ以降に切り出す
	if int(7)+int(dataSize) > len(data) {
		return fmt.Errorf("data size (%d) exceeds file length", dataSize)
	}
	payload := data[7 : 7+dataSize]

	// Output
	outPath := filepath.Clean(path)
	if err := os.WriteFile(outPath, payload, 0644); err != nil {
		return fmt.Errorf("write file: %w", err)
	}

	return nil
}
