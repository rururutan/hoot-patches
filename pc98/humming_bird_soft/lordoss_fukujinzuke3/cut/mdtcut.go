package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

// cutter は D の `cutter(char[] arg)` に相当
// 1 つのファイルを読み込み、ヘッダーに従って
// 複数ファイルに分割して書き出す
func cutter(path string) error {
	// 1. ファイルを一括で読み込む
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("cannot read %s: %w", path, err)
	}
	fileSize := uint32(len(data))

	// 2. outbase (ファイル名) を取得
	outBase := filepath.Base(path) // D の std.path.getName

	// 3. 最初の 4 バイトから startofs を取得
	if fileSize < 4 {
		return fmt.Errorf("%s is too small", path)
	}
	startofs := binary.LittleEndian.Uint32(data[0:4])
	if startofs > fileSize {
		return fmt.Errorf("invalid startofs in %s", path)
	}

	curofs := startofs
	fCnt := 0

	// 4. offset テーブルを走査
	for cnt := uint32(4); cnt <= startofs; cnt += 4 {
		var nextofs uint32

		if cnt == startofs { // 末尾：EOF
			nextofs = fileSize
		} else { // テーブルの 4 バイトを読む
			if int(cnt+4) > len(data) {
				return fmt.Errorf("offset table overflow in %s", path)
			}
			nextofs = binary.LittleEndian.Uint32(data[cnt : cnt+4])
		}

		// デバッグ出力（D の writefln）
		fmt.Printf("cur : %04x next : %04x - length : %04x\n",
			curofs, nextofs, nextofs-curofs)

		if nextofs != curofs { // 実際に書き出すデータがある場合
			outName := fmt.Sprintf("%s%02d.MLD", outBase, fCnt)

			// データを切り取って書き出す
			if int(nextofs) > len(data) {
				return fmt.Errorf("offset out of bounds in %s", path)
			}
			if err := os.WriteFile(outName, data[curofs:nextofs], 0644); err != nil {
				return fmt.Errorf("cannot write %s: %w", outName, err)
			}

			fmt.Printf("name : %s\n", outName)
			fCnt++
		}

		curofs = nextofs
	}

	return nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <file1> [file2 ...]\n", filepath.Base(os.Args[0]))
		os.Exit(1)
	}

	for _, arg := range os.Args[1:] {
		if err := cutter(arg); err != nil {
			fmt.Fprintf(os.Stderr, "error processing %s: %v\n", arg, err)
		}
	}
}
