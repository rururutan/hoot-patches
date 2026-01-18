// おとめぱーてぃ ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"

static unsigned char dir[0x400];				// Directory (1024byte)
static unsigned char buff[0x400*5*80];			// 1024byte x 5sector x 80track
char fname[FILENAME_MAX];						// 切り出しファイル名

D88 disk;
FILE *fp;

bool fcut(char *_fname, int _trk, int _C, int _H, int _R, int _N, int _offset, int _size)
{
	int rsize, osize, tmp;
	memset(buff, 0, sizeof(buff));

	while (_size) {
		rsize = disk.ReadDATA(_trk, _C, _H, _R, _N, buff, _size+_offset);
		if (rsize == 0) {
			printf("ReadData error: %s trk:%x C:%x H:%x R:%x N:%x ofs:%x size:%x\n", _fname, _trk, _C, _H, _R, _N, _offset, _size);
			return false;
		}
		// 特殊パターン Track0を跨ぐ場合はTrack2を読む
		if (_C == 0) {
			int read_next_track_size = (_size+_offset) - ((6-_R) * 0x400);
			if (read_next_track_size > 0) {
				rsize = disk.ReadDATA(2, 1, _H, 1, _N, buff+((6-_R) * 0x400), read_next_track_size);
				printf("%s trk:%x C:%x H:%x R:%x N:%x ofs:%x size:%x\n", _fname, _trk, _C, _H, _R, _N, _offset, _size);
			}
		}
		break;
	}

	fp = fopen(_fname,"wb");
	fwrite(buff + _offset, 1, _size, fp);
	fclose(fp);
	return true;
}

int main(int argc, char *argv[])
{
	int fn;
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
		disk.SetRecordRange(0x01,0x05);
		// Trk:1 C:0 H:1 R:1 N:3
		disk.ReadDATA(0x01, 0x00, 0x01, 0x01, 0x03, dir, 0x0400);
		for (fn=0; fn<sizeof(dir)/0x10; fn++)
		{
			unsigned char *ent = &dir[fn*0x10];
			if (*ent == 0xff) break;	// ディレクトリの最後

			int fnp = 0;
			for (int i = 0x00; i < 0x08; i++)
			{
				char c = ent[i];				// ファイル名を１文字ずつ取り出す
				if (c==' ') break;
				fname[fnp++] = c;				// ファイル名を構成する
			}
			{									// 拡張子を付与
				fname[fnp++] = '.';
			}
			for (int i=8; i<11; i++)	// 同じように拡張子を取り出す
			{
				char c=ent[i];
				if (c==' ') break;
				fname[fnp++] = c;
			}
			fname[fnp++] = '\0';		// 文字列の最後

			int val = (*(ent+0x0f) * 0x100) + *(ent+0x0e);
			s_trk  = val / 5;		// 開始トラック
			s_sec  = (val % 5) + 1;		// 開始セクタ
			size   = (*(ent+0x0d) * 0x100) + *(ent+0x0c);	// サイズ

			printf("%-12s  TRACK:%02d SECTOR:%02d SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, 0x03, 0x0000, size);
		}
	}
	return 0;
}
