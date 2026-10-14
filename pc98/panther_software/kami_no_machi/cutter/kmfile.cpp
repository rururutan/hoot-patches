// 神の聖都 ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"

static unsigned char dir[0x100*14];				// Directory (256byte x 14sector)
static unsigned char buff[0x400*8*153];			// 1024byte x 8sector x 153track
char fname[FILENAME_MAX];						// 切り出しファイル名

D88 disk;
FILE *fp;

bool fcut(char *_fname, int _trk, int _C, int _H, int _R, int _N, int _offset, int _size)
{
	if (!disk.ReadDATA(_trk, _C, _H, _R, _N, buff, _size+_offset)) {
		printf("error\n");
		return false;
	}
	fp = fopen(_fname,"wb");
	fwrite(buff + _offset, 1, _size, fp);
	fclose(fp);
	return true;
}

int main(int argc, char *argv[])
{
	int i,c,fn;
	int s_trk,s_sec,size;

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
		// trk:0 c:0 h:0 r:2 n:0
		int size;
		size = disk.ReadDATA(0x00, 0x00, 0x00, 0x07, 0x3, dir, 0x0e00);

		for (fn=0; fn<sizeof(dir)/0x10; fn++)
		{
			unsigned char *ent = &dir[fn*0x10];
			if (*ent == 0x00) continue;	// Volume Label

			int i;
			int fnp = 0;
			for (i = 0x00; i < 0x08; i++)
			{
				char c = ent[i];				// ファイル名を１文字ずつ取り出す
				if (c==' ') break;
				fname[fnp++] = c;				// ファイル名を構成する
			}
			if (ent[8] != ' ')			// 拡張子が必要なら付ける
			{
				fname[fnp++] = '.';
			}
			for (i=8; i<0xb; i++)	// 同じように拡張子を取り出す
			{
				char c=ent[i];
				if (c==' ') break;
				fname[fnp++] = c;
			}
			fname[fnp++] = '\0';		// 文字列の最後

//			s_trk  = *(ent+0x0b) + (*(ent+0x0c) << 8);	// 開始トラック
//			s_sec  = s_trk % 8 + 2;						// 開始セクタ
//			size   = ((*(ent+0x1b) + (*(ent+0x1c) << 8)) - s_trk) * 0x400;
//			s_trk  = s_trk / 8 + 1;

			s_trk  = *(ent+0x0b) + (*(ent+0x0c) << 8) + 1;	// 開始トラック
			s_sec  = s_trk % 8 + 1;							// 開始セクタ
			size   = ((*(ent+0x1b) + (*(ent+0x1c) << 8)) - s_trk + 1) * 0x400;
			s_trk  = s_trk / 8 + 1;

			printf("%-12s  TRACK:%02x SECTOR:%02x SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, D88::N_1024, 0x0000, size);
		}
	}
	return 0;
}
