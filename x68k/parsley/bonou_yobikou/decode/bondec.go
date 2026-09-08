/**
 * 煩悩予備校/X68K *.md to *.opm decoder
 *  2009/12/21 D-language port
 *  2025/04/03 Go-language port
 */
package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func ChangeExtension(arg string, newExt string) (string, error) {
	// 拡張子が既に新しい拡張子でない場合に変更
	ext := filepath.Ext(arg)
	if ext == newExt {
		return arg, nil
	}

	// 拡張子を変更した新しいファイル名を作成
	base := arg[:len(arg)-len(ext)] // 拡張子を除いたファイル名
	newName := base + newExt

	return newName, nil
}

// decode関数では、ファイルの全てのバイトをNotして+1する処理を行います。
func decode(arg string) {
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
	inputFile.Close();

	// データをNot + 1する処理
	for i := 0; i < len(input); i++ {
		data := input[i]
		data = ^data + 1 // ビット反転して +1
		input[i] = data
	}

	// 出力ファイル名を作成
	outBase := filepath.Base(arg)
	outName, err := ChangeExtension(outBase, ".opm")
	if err != nil {
		fmt.Println("Change Extension Error:", err)
		return
	}

	// 結果をファイルに書き込み
	outFile, err := os.Create(outName)
	if err != nil {
		fmt.Printf("Error creating output file %s: %s\n", outName, err)
		return
	}
	defer outFile.Close()

	_, err = outFile.Write(input)
	if err != nil {
		fmt.Printf("Error writing to output file %s: %s\n", outName, err)
		return
	}

	fmt.Printf("File %s decoded successfully!\n", outName)
}

func main() {
	// 引数の処理
	if len(os.Args) < 2 {
		fmt.Println("Please provide a file as argument.")
		return
	}

	// 引数ごとにdecode関数を呼び出す
	for _, arg := range os.Args[1:] {
		decode(arg)
	}
}
