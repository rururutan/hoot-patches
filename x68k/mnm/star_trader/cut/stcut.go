package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	args := os.Args
	if len(args) < 2 {
		fmt.Printf("usage: %s [filename...]\n", filepath.Base(args[0]))
		return
	}

	for _, fn := range args[1:] {
		// ファイルを全体読み込み
		data, err := os.ReadFile(fn)
		if err != nil {
			log.Printf("cannot read %s: %v\n", fn, err)
			continue
		}

		if len(data) <= 0x30 {
			fmt.Println("length too short!")
			continue
		}

		// 先頭 4 バイトで最初のオフセット (逆順に読む)
		curofs := int(data[3]) | int(data[2])<<8 | int(data[1])<<16 | int(data[0])<<24

		// 出力ファイル名のベース（最初の '.' 以前）
		base := strings.Split(fn, ".")[0]

		// 4‑byte オフセットを 4‑byte ステップで読み取り
		for cnt := 4; cnt <= 0x30; cnt += 4 {
			var nextofs int
			if cnt == 0x30 { // 最後のエントリはファイル末尾
				nextofs = len(data)
			} else {
				nextofs = int(data[cnt+3]) | int(data[cnt+2])<<8 |
					int(data[cnt+1])<<16 | int(data[cnt])<<24
			}

			fmt.Printf("cur : %05x next : %05x - length : %04x\n",
				curofs, nextofs, nextofs-curofs)

			segNo := cnt / 4
			outName := fmt.Sprintf("%s%02d.m", base, segNo)

			// ディレクトリがある場合は作成
			if dir := filepath.Dir(outName); dir != "." {
				if err := os.MkdirAll(dir, 0755); err != nil {
					log.Printf("cannot create dir %s: %v\n", dir, err)
				}
			}

			if err := os.WriteFile(outName,
				data[curofs:nextofs], 0644); err != nil {
				log.Printf("cannot write %s: %v\n", outName, err)
			}

			curofs = nextofs
		}
	}
}
