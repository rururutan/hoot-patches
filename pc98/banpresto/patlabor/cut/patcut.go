// PC-98 PATLABER / MUSIC.FLK split tool

package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

func main() {
	// 引数チェック
	args := os.Args[1:]
	if len(args) == 0 {
		usage()
		return
	}

	// ファイル処理を実行
	for _, arg := range args {
		splitFile(arg)
	}
}

func usage() {
	fmt.Println("Patlabor/PC-98 .FLK split tool by 2025 Ru^3")
	fmt.Println("Usage: patcut <file1> <file2> ...")
	fmt.Println("At least one file should be provided.")
}

func splitFile(arg string) {
	// ファイルのサイズを取得
	info, err := os.Stat(arg)
	if err != nil {
		fmt.Printf("Error getting file info: %s\n", err)
		return
	}
	cCnt := info.Size()

	// ファイルサイズが小さすぎる場合
	if cCnt <= 0x200 {
		fmt.Println("length too short!")
		return
	}

	// ファイルを読み込む
	input, err := ioutil.ReadFile(arg)
	if err != nil {
		fmt.Printf("Error reading file: %s\n", err)
		return
	}

	// curofsをuint16型に変更
	curofs := uint16(0x200)
	var nextofs uint16
	var outname [13]byte

	// データを処理
	for cnt := 0; cnt < 0x200; cnt += 0x10 {
		// nextofsの計算
		nextofs = uint16(input[cnt+0x10]) + uint16(input[cnt+0x11])<<8
		nextofs <<= 4
		if nextofs == 0 {
			break
		}
		nextofs += 0x200

		// 名前を取得
		copy(outname[:12], input[cnt+4:cnt+16])
		outname[12] = '\x00'

		// 名前を文字列に変換
		outputFileName := strings.TrimRight(string(outname[:]), "\x00")

		// 空文字列はスキップ
		if outputFileName == "" {
			fmt.Println("Invalid file name, skipping.")
			continue
		}

		fmt.Printf("name : %s | offset : 0x%04x | length : 0x%04x\n", outputFileName, curofs, nextofs-curofs)

		// ファイル書き込み
		outputFile, err := os.Create(outputFileName)
		if err != nil {
			fmt.Printf("Error creating file: %s\n", err)
			continue
		}

		_, err = outputFile.Write(input[curofs:nextofs])
		if err != nil {
			fmt.Printf("Error writing to file: %s\n", err)
			outputFile.Close()
			continue
		}
		outputFile.Close()

		curofs = nextofs // curofsをnextofsに更新
	}
}
