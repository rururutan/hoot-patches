// THEXDER (for FM7) ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"

static unsigned char dir[0x800];				// Directory (2048byte)
static unsigned char head[0x100];				// File Header (256byte)
static unsigned char buff[0x200*10*80];			// 512byte x 10sector x 80track
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
	int fn;
	int s_trk,s_sec,size,offs;

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
		disk.ReadDATA(0x02, 0x01, 0x00, 0x04, 0x01, dir, 0x0800);
		for (fn=0; fn<sizeof(dir)/0x20; fn++)
		{
			unsigned char *ent = &dir[fn*0x20];
			if (*ent == 0xff) break;	// ディレクトリの最後

			int i;
			int fnp = 0;
			for (i = 0x00; i < 0x08; i++)
			{
				char c = ent[i];				// ファイル名を１文字ずつ取り出す
				if (c==' ') break;
				if (c==00) c='_';
				fname[fnp++] = c;				// ファイル名を構成する
			}
			fname[fnp++] = '\0';		// 文字列の最後

			s_trk  = *(ent+0x0e)/2+4;		// 開始トラック
			s_sec  = *(ent+0x0e)%2*8+1;		// 開始セクタ

			disk.ReadDATA(s_trk, s_trk>>1, s_trk&1, s_sec, 0x01, head, 0x100);

			int fileofs;
			if ( head[0] ) {
				size   = *(head+0x02)*0x100 + *(head+0x03);	// サイズ
				offs   = 0;								   	// メモリオフセット
				fileofs = 6;
			} else {
				size   = *(head+0x01)*0x100 + *(head+0x02);	// サイズ
				offs   = *(head+0x03)*0x100 + *(head+0x04);	// メモリオフセット
				fileofs = 5;
			}
			if (size == 0xffff) size = 0x100;

			printf("%-9s  TRACK:%02x SECTOR:%02x SIZE:%04x MEMOFS:%04x\n",fname,s_trk,s_sec,size,offs);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, 0x01, fileofs, size);
		}
	}
	return 0;
}
