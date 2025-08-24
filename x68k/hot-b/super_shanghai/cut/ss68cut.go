/**
 * SuperShanghai 68K cutter
 *
 * ヘッダ付単純連結形式 + LZ。LZは別途デコードの事。
 * ヘッダにはデータサイズがWORD(BE)で書かれている。
 * ヘッダ長は0x28固定
 *
 */
package main

import (
	"fmt"
	"os"
	"io"
	"encoding/binary"
	"path/filepath"
)

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

	// ファイル内容を読み込む
	input := make([]byte, inputSize)
	_, err = inputFile.Read(input)
	if err != nil && err != io.EOF {
		fmt.Printf("Error reading file %s: %s\n", arg, err)
		return
	}

	// 出力ファイル名のベース部分を取得
	outBase := filepath.Base(arg)
	
	// 表示用のヘッダ
	fmt.Println("+---------+-------+----------------+")
	fmt.Println("| Offset  | Size  | Name           |")
	fmt.Println("+---------+-------+----------------+")

	var dataOfs uint32
	var dataSize uint16
	var headOfs uint32
	i := 0
	
	// ヘッダオフセットは0x28固定
	dataOfs = 40
	headOfs = 0

	// 分割処理
	for {
		if headOfs + 2 > uint32(inputSize) {
			break
		}
		dataSize = getWordBE(input[headOfs:])
		if dataSize > 0 {
			// 出力ファイル名
			outName := fmt.Sprintf("%s.%03d", outBase, i)
			fmt.Printf("| 0x%05x | %5d | %14s |\n", dataOfs, dataSize, outName)
			
			// 出力ファイルを作成
			outFile, err := os.Create(outName)
			if err != nil {
				fmt.Printf("Error creating output file %s: %s\n", outName, err)
				return
			}
			defer outFile.Close()

			// ファイルに書き込み
			_, err = outFile.Write(input[dataOfs : dataOfs+uint32(dataSize)])
			if err != nil {
				fmt.Printf("Error writing to output file %s: %s\n", outName, err)
				return
			}

			// 次の分割部分のための準備
			dataOfs += uint32(dataSize)
			headOfs += 2
			i++
		} else {
			break
		}
	}

	// 表示用のフッタ
	fmt.Println("+---------+-------+----------------+")
}

func main() {
	// 引数の処理
	if len(os.Args) < 2 {
		fmt.Println("Please provide a file as argument.")
		return
	}

	for _, arg := range os.Args[1:] {
		cutter(arg)
	}
}
