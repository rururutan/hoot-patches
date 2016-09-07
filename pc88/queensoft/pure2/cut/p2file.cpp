// Pure II (for PC88) ファイル抽出プログラム

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"

static unsigned char dir[0x500];				// Directory (2048byte)
static unsigned char buff[0x200*10*80];			// 512byte x 10sector x 80track
char fname[FILENAME_MAX];						// 切り出しファイル名

D88 disk;
FILE *fp;

bool fcut(char *_fname, int _trk, int _C, int _H, int _R, int _N, int _size)
{
	const int osize = _size;					// オリジナルサイズ
	int dsize = 0;								// 読み込み済みサイズ
	int rsize = 0;								// 読み込みサイズ
	memset(buff, 0, sizeof(buff));

	while (_size) {
		rsize = disk.ReadDATA(_trk, _C, _H, _R, _N, buff+dsize, _size);
		dsize += rsize;
		if (rsize == 0) {
			return false;
		}
		if (rsize < _size) {
			_size -= rsize;
			_trk += 1;
			_C = _trk >> 1;
			_H = _trk & 1;
			_R = 1;
			continue;
		}
		break;
	}

	fp = fopen(_fname,"wb");
	fwrite(buff, 1, osize, fp);
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
        int rsize = disk.ReadDATA(0x01, 0x00, 0x01, 0x01, D88::N_1024, dir, 0x0500);
		for (fn=0; fn<sizeof(dir)/0x10; fn++)
		{
			unsigned char *ent = &dir[fn*0x10];

            int i;
			int fnp = 0;
			if (ent[0] == 0xff) {
				continue;						// 無効なファイル名
			}
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

			s_trk  = *(ent+0x0b);		// 開始トラック
			s_sec  = *(ent+0x0c)+1;		// 開始セクタ
			size   = *(ent+0x0f)*0x100 +*(ent+0x0e);	// サイズ

			printf("%-9s  TRACK:%02x SECTOR:%02x SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, D88::N_1024, size);
		}
	}
	return 0;
}
