package main

import (
	"fmt"
	"os"
	"io"
	"encoding/binary"
)

// バイト配列からBig Endian形式の32ビット整数を取得
func getDWordBE(data []byte) uint32 {
	return binary.BigEndian.Uint32(data)
}

// バイト配列からBig Endian形式の16ビット整数を取得
func getWordBE(data []byte) uint16 {
	return binary.BigEndian.Uint16(data)
}

func cutter(arg string) {
	// 入力ファイルを開く
	inputFile, err := os.Open(arg)
	if err != nil {
		fmt.Printf("Error opening file %s: %s\n", arg, err)
		return
	}
	defer inputFile.Close()

	// ファイルサイズを取得
	stat, err := inputFile.Stat()
	if err != nil {
		fmt.Printf("Error getting file stat for %s: %s\n", arg, err)
		return
	}
	inputSize := stat.Size()

	// ファイル内容を読み込み
	input := make([]byte, inputSize)
	_, err = inputFile.Read(input)
	if err != nil && err != io.EOF {
		fmt.Printf("Error reading file %s: %s\n", arg, err)
		return
	}

	var curofs, nextofs, headerofs, nameofs uint32

	// 最初のcurofsの計算
	curofs = uint32(getDWordBE(input[headerofs:])) * 0x10

	// メイン処理ループ
	for {
		// 名前のオフセット設定
		nameofs = headerofs + 4

		// 名前がNULLなら終了
		if input[nameofs] == 0x00 {
			break
		}

		// 次のヘッダのオフセット
		headerofs += 0x10
		nextofs = uint32(getDWordBE(input[headerofs:])) * 0x10

		// 名前を取得して表示
		outname := string(input[nameofs : nameofs+13])
		fmt.Printf("name: %s\n", outname)

		// 出力ファイルを作成
		outFile, err := os.Create(outname)
		if err != nil {
			fmt.Printf("Error creating output file %s: %s\n", outname, err)
			return
		}
		defer outFile.Close()

		// ファイルに書き込み
		_, err = outFile.Write(input[curofs+0x200 : curofs+0x200+nextofs-curofs])
		if err != nil {
			fmt.Printf("Error writing to output file %s: %s\n", outname, err)
			return
		}

		// 次のオフセット
		curofs = nextofs
	}
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Please provide a file as argument.")
		return
	}

	// 引数ごとにcutter関数を呼び出す
	for _, arg := range os.Args[1:] {
		cutter(arg)
	}
}
