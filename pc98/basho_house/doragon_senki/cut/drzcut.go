// Dragon創世記 DRZ000A.DAT Cutter
//  (c) 2007 Ru^3

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	// コマンドライン引数 (プログラム名は除く)
	files := os.Args[1:]
	if len(files) == 0 {
		fmt.Println("Usage: go run main.go <file1> [file2 ...]")
		return
	}

	for _, path := range files {
		// ファイルサイズ取得
		info, err := os.Stat(path)
		if err != nil {
			fmt.Printf("Could not stat %s: %v\n", path, err)
			continue
		}
		if info.Size() <= 0x30 {
			fmt.Println("File length too short!")
			continue
		}

		// ファイル内容を一括で読む
		data, err := os.ReadFile(path)
		if err != nil {
			fmt.Printf("Could not read %s: %v\n", path, err)
			continue
		}

		// ". で区切って最初の部分を取得（D では split(arg, ".") の結果の 0 番目）
		baseName := strings.SplitN(filepath.Base(path), ".", 2)[0]

		curofs := 0
		for cnt := 0; cnt < 48; cnt += 2 {
			if cnt+1 >= len(data) {
				fmt.Printf("Header too short while reading offsets for %s\n", path)
				break
			}

			// 16bit little-endian オフセット
			nextofs := int(data[cnt]) | int(data[cnt+1])<<8

			if nextofs > len(data) || nextofs < curofs {
				fmt.Printf("Invalid offset (%d) in %s\n", nextofs, path)
				break
			}

			// 出力ファイル名: 例 "foo.000", "foo.001", …
			outName := fmt.Sprintf("%s.%03x", baseName, cnt/2)

			outFile, err := os.Create(outName)
			if err != nil {
				fmt.Printf("Could not create %s: %v\n", outName, err)
				break
			}

			// データを書き出す
			if _, err := outFile.Write(data[curofs:nextofs]); err != nil {
				fmt.Printf("Write error to %s: %v\n", outName, err)
			}
			outFile.Close()

			curofs = nextofs
		}
	}
}
