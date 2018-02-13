// Ys (for MSX) ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"

static unsigned char dir[0x200*6];				// Directory (512byte x 6sector)
static unsigned char buff[0x200*9*160];			// 512byte x 9sector x 160track
char fname[FILENAME_MAX];						// 切り出しファイル名

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

	if (argc < 3) {
		// オプション指定がないとき
		fprintf(stderr, "Usage: %s [d88file] [0~2]\n",argv[0]);
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

		char *no = argv[2];
		switch ( no[0] ) {
		  case '0':
			size = disk.ReadDATA(0x00, 0x00, 0x00, 0x02, D88::N_512, dir, 0x0c00);
			break;
		  case '1':
			size = disk.ReadDATA(0x00, 0x00, 0x00, 0x05, D88::N_512, dir, 0x0c00);
			break;
		  case '2':
			size = disk.ReadDATA(0x00, 0x00, 0x00, 0x07, D88::N_512, dir, 0x0c00);
			break;
		  default:
			return -1;
		}

		for (fn=0; fn<sizeof(dir)/0x10; fn++)
		{
			unsigned char *ent = &dir[fn*0x10];
			if (*ent == 0xff) break;	// ディレクトリの最後

			int i;
			int fnp = 0;
			for (i = 0x00; i < 0x08; i++)
			{
				char c = ent[i];				// ファイル名を１文字ずつ取り出す
				if (c==' ') break;
				if (c==-1) break;				// For YsI
				fname[fnp++] = c;				// ファイル名を構成する
			}
			fname[fnp++] = '\0';		// 文字列の最後

			s_trk  = *(ent+0x0c) + (*(ent+0x0d) << 8);	// 開始トラック
			e_trk  = *(ent+0x0e) + (*(ent+0x0f) << 8);	// 終了トラック
			size   = (e_trk - s_trk + 1) * 0x200;		// サイズ
			s_sec  = s_trk % 9 + 1;						// 開始セクタ
			s_trk  = s_trk / 9;

			printf("%-12s  TRACK:%02x SECTOR:%02x SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, D88::N_512, 0x0000, size);
		}
	}
	return 0;
}
