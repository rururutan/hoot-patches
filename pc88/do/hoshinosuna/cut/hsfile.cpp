// 星の砂物語 (for PC88) ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"

static unsigned char dir[0x800];				// Directory (2048byte)
static unsigned char buff[0x200*10*80];			// 512byte x 10sector x 80track
char fname[FILENAME_MAX];						// 切り出しファイル名

D88 disk;
FILE *fp;

bool fcut(char *_fname, int _trk, int _C, int _H, int _R, int _N, int _offset, int _size)
{
	int rsize, osize, tmp;
	memset(buff, 0, sizeof(buff));
	rsize = disk.ReadDATA(_trk, _C, _H, _R, _N, buff, _size+_offset);
	if (rsize == 0) {
		return false;
	}

	// 先頭4byteがヘッダ
	tmp   = (buff[0] +(buff[1] << 8));
	osize = (buff[2] +(buff[3] << 8));

	if (osize != 0) {
		osize -= tmp;
	} else {
		printf("??? - ");
		osize = _size;
	}
	_offset += 4;

	printf("cut size:%x / org size:%x\n", _size, osize);
	if (osize < 0) {
		osize = _size;
		_offset = -4;
	}

	fp = fopen(_fname,"wb");
	fwrite(buff + _offset, 1, osize, fp);
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
		disk.SetRecordRange(0x01,0x10);
		disk.ReadDATA(0x01, 0x00, 0x01, 0x01, 0x01, dir, 0x0800);
		for (fn=0; fn<sizeof(dir)/0x10; fn++)
		{
			unsigned char *ent = &dir[fn*0x10];
			if (*ent == 0xff) break;	// ディレクトリの最後

			int i;
			int fnp = 0;
			for (i = 0x00; i < 0x06; i++)
			{
				char c = ent[i];				// ファイル名を１文字ずつ取り出す
				if (c==' ') break;
				fname[fnp++] = c;				// ファイル名を構成する
			}
			if (ent[6] != ' ')			// 拡張子が必要なら付ける
			{
				fname[fnp++] = '.';
			}
			for (i=6; i<9; i++)	// 同じように拡張子を取り出す
			{
				char c=ent[i];
				if (c==' ') break;
				fname[fnp++] = c;
			}
			fname[fnp++] = '\0';		// 文字列の最後

			s_trk  = *(ent+0x0a);		// 開始トラック
			s_sec  = *(ent+0x0b);		// 開始セクタ
			size   = *(ent+0x09)*0x100;	// サイズ

			printf("%-9s  TRACK:%02x SECTOR:%02x SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, 0x01, 0x0000, size);
		}
	}
	return 0;
}
