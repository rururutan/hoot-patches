// Silent Möbius for X68000 ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "d88.h"

static uint8_t dir[0x800];				// Directory (2048byte)
static uint8_t buff[0x200*4*80];		// 512byte x 10sector x 80track
char fname[FILENAME_MAX];				// 切り出しファイル名

D88 disk;

bool fcut(char *_fname, int _trk, int _C, int _H, int _R, int _N, int _offset, int _size)
{
	memset(buff, 0, sizeof(buff));
	int rsize = disk.ReadDATA(_trk, _C, _H, _R, _N, buff, _size+_offset);
	if (rsize == 0) {
		return false;
	}
	if (rsize != _size) {
		printf("size diff! O:%x R:%x\n", _size, rsize);
	}

	FILE *fp = fopen(_fname,"wb");
	fwrite(buff + _offset, 1, _size, fp);
	fclose(fp);
	return true;
}

int main(int argc, char *argv[])
{
	if (argc != 2) {
		// オプション指定がないとき
		fprintf(stderr, "Usage: %s [d88file]\n",argv[0]);
		return 1;
	}

	// ファイルを開いたらエラーになった
	if (!disk.SetFile(argv[1])) {
		fprintf(stderr, "ファイルをオープンできません\n");
		return 1;
	}

	int numdisk = disk.GetNumDisk();	// ディスクイメージ枚数

	for (int d=0; d<numdisk; d++)		// イメージ数分の処理
	{
		disk.SelectDisk(d);

		// ディレクトリの読み込み
		disk.SetRecordRange(0x01,0x08);
		disk.ReadDATA(0x01, 0x00, 0x01, 0x01, 0x02, dir, 0x0800);
		disk.SetRecordRange(0x01,0x0f);
		for (int fn=0; fn<sizeof(dir)/0x10; fn++)
		{
			int s_trk,s_sec,size;
			uint8_t *ent = &dir[fn*0x10];
			if (*ent == 0xff) {
				break;	// ディレクトリの最後
			}

			int i;
			int fnp = 0;
			for (i = 0x00; i <= 0x0b; i++)
			{
				char c = ent[i];				// ファイル名を１文字ずつ取り出す
				if (c==' ') break;
				fname[fnp++] = c;				// ファイル名を構成する
			}
			fname[fnp++] = '\0';		// 文字列の最後

			s_trk  = *(ent+0x0f) * 2;	// 開始トラック
			s_sec  = *(ent+0x0e);		// 開始セクタ
			size   = *(ent+0x0d)*0x200;	// サイズ
			if (s_sec >= 0x10) {
				s_trk ++;
				s_sec -= 0x10;
			}

			printf("%-9s\tTRACK:%02x SECTOR:%02x SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, 0x02, 0x0000, size);
		}
	}
	return 0;
}
