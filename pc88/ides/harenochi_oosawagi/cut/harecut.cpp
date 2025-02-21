// 晴れのちおおさわぎ！(PC88) ファイルカッター

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "d88.h"
#define	getword(x)	(buff[x]+buff[x+1]*0x100)

static unsigned char dir[0x800];				// Directory (2048byte)
static unsigned char buff[0x100*16*80];

D88 disk;
FILE *fp;

bool fcut(char *_fname, int _trk, int _C, int _H, int _R, int _N, int _offset, int _size) {
	if (!disk.ReadDATA(_trk, _C, _H, _R, _N, buff, _size+_offset)) return false;
//	printf ("cutting ... %s\n",_fname);
	fp = fopen(_fname,"wb");
	fwrite(buff + _offset, 1, _size, fp);
	fclose(fp);
	return true;
}

bool msave(char *_fname, unsigned char *_adr, int _size) {
	printf ("cutting ... %s\n",_fname);
	fp = fopen(_fname,"wb");
	fwrite(_adr, 1, _size, fp);
	fclose(fp);
	return true;
}

struct fpos {
	int trk;
	int sec;
	int size;
};

int main(int argc, char *argv[])
{
	char fname[FILENAME_MAX];
	int i,d;
	unsigned char id[]="HARE88:";

	if (argc != 2) {
		// オプション指定がないとき
		fprintf(stderr, "Usage: %s [d88file]\n",argv[0]);
		return 1;
	}

	if (!disk.SetFile(argv[1])) {
		fprintf(stderr, "ファイルをオープンできません.\n");
		return 1;
	}

	int numdisk = disk.GetNumDisk();
	for (d=0; d<numdisk; d++) {
		disk.SelectDisk(d);
		disk.SetRecordRange(0x01,0x10);
		// ディスク判定
		disk.ReadDATA(0x00, 0x00, 0x00, 0x01, 0x01, buff, 0x100);
		if (!memcmp(&buff[0xf8], id, sizeof(id)-1)) {
			int adr,HL,DE,H,L,A;
			switch (buff[0xff]) {
			case 'A':
				printf("Disk Aを認識しました.");
				// バージョン判定
				disk.ReadDATA(0x00, 0x00, 0x00, 0x03, 0x01, buff, 0x0d00);
				switch (getword(0x0117)) {
				case 0x6265:
					printf("(Type A)\n");
					DE = 0xe9eb;							// デコードキー初期値(Type A)
					break;

				case 0x2a08:
					printf("(Type B)\n");
					DE = 0x1cdb;							// デコードキー初期値(Type B)
					break;

				default:
					printf("\n未対応のバージョンです.");
					return 2;
				}

				// Track 76～78を読み込み
				disk.ReadDATA(0x4c, 0x26, 0x00, 0x01, 0x01, buff, 0x2400);

				for (adr=0; adr<0x2400; adr++) {
					HL = (DE*7) & 0xffff;					// ADD HL,HL/ADD HL,DE/ADD HL,HL/ADD HL,DE
					H = HL >> 8;
					L = HL & 0xff;
					DE = L*0x100+H;							// LD E,H / LD D,L
					H = ((H << 2) & 0xfc) | (H >> 6);		// RLC H x2
					L = (L >> 1) | ((L & 1) << 7);			// RRC L
					HL = H*0x100+L;
					DE = (HL + DE + 0x1119) & 0xffff;		// ADD HL,DE / LD DE,1119H / ADD HL,DE
					A = DE>>8;
					buff[adr] ^= A;							// デコード
				}
				// サウンドドライバ書き出し
				msave("driver.bin", &buff[0x700], 0x600*2);
				break;

			case 'B':
				printf("Disk Bを認識しました.\n");
				break;

			case 'C':
				printf("Disk Cを認識しました.\n");
				break;

			default:
				break;
			}
		}

		// ディレクトリの読み込み
        int fn;
        int s_trk,s_sec,size;
		disk.SetRecordRange(0x01,0x10);
		disk.ReadDATA(0x01, 0x00, 0x01, 0x01, 0x01, dir, 0x0800);
        for (fn=0; fn<sizeof(dir)/0x10; fn++) {
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

			s_trk  = *(ent+0x09);		// 開始トラック
			s_sec  = *(ent+0x0a);		// 開始セクタ
			size   = *(ent+0x0e)*0x100 + *(ent+0x0d);	// サイズ

			printf("cutting ... %-9s\n",fname);
//			printf("%-9s  TRACK:%02x SECTOR:%02x SIZE:%04x\n",fname,s_trk,s_sec,size);
			fcut(fname, s_trk, s_trk>>1, s_trk&1, s_sec, 0x01, 0x0000, size);
		}
    }
	return 0;
}

