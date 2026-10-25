package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

// cutter は D の `cutter(char[] arg)` に相当
// 1 つのファイルを読み込み、ヘッダーに従って複数ファイルに分割して書き出す
func cutter(path string) error {
	// ファイルを一括で読み込む
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("cannot read %s: %w", path, err)
	}

	if len(data) < 0xc+4 { // 先頭のオフセットが読めるか確認
		return fmt.Errorf("%s is too small", path)
	}

	nameofs := 0          // 名前の位置
	sizeofs := 0xc        // オフセット表の開始位置
	var nextofs uint32    // 次のオフセット

	// 最初に「nextofs」を取得（D のコードの先頭でやっていること）
	if len(data) < sizeofs+4 {
		return fmt.Errorf("invalid header in %s", path)
	}
	nextofs = binary.LittleEndian.Uint32(data[sizeofs : sizeofs+4])

	// ここから while (input[nameofs] != 0) のループ
	for nameofs < len(data) && data[nameofs] != 0 {
		// fileofs は前回の nextofs
		fileofs := nextofs

		// 次のオフセットを取得（D のコード内でやっていること）
		if len(data) < sizeofs+0x10+4 {
			return fmt.Errorf("invalid header in %s", path)
		}
		nextofs = binary.LittleEndian.Uint32(
			data[sizeofs+0x10 : sizeofs+0x14],
		)

		// 何か情報を表示（D の writefln と同等）
		fmt.Printf("sizeofs: %04x fofs: %04x nofs: %04x fsize: %04x\n",
			sizeofs, fileofs, nextofs, nextofs-fileofs)

		// 12 バイトの名前を取得
		if nameofs+12 > len(data) {
			return fmt.Errorf("name overflow in %s", path)
		}
		nameBytes := data[nameofs : nameofs+12]
		// 先頭 0 は終端文字なので除外
		nameEnd := 12
		for i, b := range nameBytes {
			if b == 0 {
				nameEnd = i
				break
			}
		}
		outName := string(nameBytes[:nameEnd])
		fmt.Printf("name : %s\n", outName)

		// ファイルサイズを計算
		if int(nextofs) > len(data) || int(fileofs) > len(data) {
			return fmt.Errorf("offset out of bounds in %s", path)
		}
		content := data[fileofs:nextofs]

		// 出力ファイルを作成して書き込み
		if err := os.WriteFile(outName, content, 0644); err != nil {
			return fmt.Errorf("cannot write %s: %w", outName, err)
		}

		// 次のエントリへ
		nameofs += 0x10
		sizeofs += 0x10
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
