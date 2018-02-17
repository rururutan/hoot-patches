// Laplas (for MSX) ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"

static unsigned char dir[0x200*6];				// Directory (512byte x 6sector)
static unsigned char buff[0x200*9*160];			// 512byte x 9sector x 160track
char fname[FILENAME_MAX];						// 切り出しファイル名
char oname[FILENAME_MAX];						// 前のファイル名

D88 disk;
FILE *fp;

bool fcut(char *_fname, int _trk, int _C, int _H, int _R, int _N, int _offset, int _size)
{
	if (!disk.ReadDATA(_trk, _C, _H, _R, _N, buff, _size+_offset)) return false;
	fp = fopen(_fname,"wb");
	fwrite(buff + _offset, 1, _size, fp);
	fclose(fp);
	return true;
}

int main(int argc, char *argv[])
{
	int i,c,fn;
	int s_trk,e_trk,s_sec,size;

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
		disk.SetRecordRange(0x01,0x09);
		// trk:0 c:0 h:0 r:2 n:0
		int size;
		size = disk.ReadDATA(0x00, 0x00, 0x00, 0x07, D88::N_512, dir, 0x0800);

		for (fn=0; fn<sizeof(dir)/0x08; fn++)
		{
			unsigned char *ent = &dir[fn*0x08];
			if (*ent == 0x00) continue;	// ディレクトリの最後
			if (fn >= 0x100) break;

			int i;
			int fnp = 0;
			for (i = 0x00; i < 0x04; i++)
			{
				char c = ent[i];				// ファイル名を１文字ずつ取り出す
				if (c==' ') break;
				fname[fnp++] = c;				// ファイル名を構成する
			}
			fname[fnp++] = '\0';		// 文字列の最後


			if (strncmp(fname, "COM", 3) == 0) {
				fname[0] = '_';
			}

			if (strncmp(fname, oname, FILENAME_MAX) == 0) {
				fname[strlen(fname)] = '_';
			}

			s_trk  = *(ent+0x04) + (*(ent+0x05) << 8);	// 開始トラック
			e_trk  = *(ent+0x06) + (*(ent+0x07) << 8);	// 終了トラック
			size   = (e_trk - s_trk + 1) * 0x200;		// サイズ
			s_sec  = s_trk % 9 + 1;						// 開始セクタ
			s_trk  = s_trk / 9;

			printf("%-12s  TRACK:%02x SECTOR:%02x SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, D88::N_512, 0x0000, size);
			strcpy(oname, fname);
		}
	}
	return 0;
}
