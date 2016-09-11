/**
 * BGMLIB/MASTERLIBデータ演奏ドライバ for hoot
 * 
 * コンパイルにはMS-C(small model)とBGMLIBが必要です。
 *
 * %ドライバ仕様
 *
 * ファイル名ハンドルは0x10固定
 * HOOTPORT + 2 に曲番号
 * HOOTPORT + 3 にリピートの有無
 *
 * %現状の制限
 *
 * BGMバッファはとりあえず20K
 * ファイル名バッファは128文字
 *
 */
#include <dos.h>
#include "bgmlib.h"

#define HOOTFUNC	0x07e8
#define HOOTPORT	0x07e0
#define HOOTINT		0x7f
#define HF_DISABLE	0x80
#define HF_ENABLE	0x81
#define HP_PLAY		0x00
#define HP_STOP		0x02

#define STI()	_enable()
#define CLI()	_disable()

void interrupt far hoot_hook(void);

int main () {
	char filename[128];
	union REGS inreg, outreg;
	struct SREGS sreg;

	/* hoot呼び出し禁止 */
	CLI();
	outp(HOOTFUNC, HF_DISABLE);

	/* 初期設定 */
	bgm_init(20480);

	/* 割り込みベクタ設定 */
	_dos_setvect(HOOTINT, hoot_hook);

	/* 先頭へSEEK */
	inreg.h.ah = 0x42;
	inreg.h.al = 0x0;
	inreg.x.bx = 0x10;	/* handle */
	inreg.x.cx = 0;
	inreg.x.dx = 0;
	segread(&sreg);
	intdosx(&inreg, &outreg, &sreg);

	/* READ FILENAME */
	memset((void*)filename, 0, 128);
	inreg.h.ah = 0x3f;
	inreg.x.bx = 0x10;	/* handle */
	inreg.x.cx = 128-1;
	inreg.x.dx = (unsigned int)&filename[0];
	segread(&sreg);
	intdosx(&inreg, &outreg, &sreg);

	bgm_read_data(filename, 0, 0);

	/* hoot呼び出し許可 */
	outp(HOOTFUNC, HF_DISABLE);
	STI();

	for (;;) {
		inreg.x.ax = 0x9801;
		int86(0x18, &inreg, &outreg);
	}
}

#define		INTCTRL			0x00
#define		EOI				0x20

void interrupt far hoot_hook(void)
{
	int mode = inp(HOOTPORT);
	if (mode == HP_PLAY) {
		int num  = inp(HOOTPORT+2);
		int flag = inp(HOOTPORT+3);

		bgm_stop_play();
		bgm_select_music(num);
		bgm_start_play();
		if (flag == 0) {
			bgm_repeat_on();
		} else {
			bgm_repeat_off();
		}
	} else {
		bgm_stop_play();
	}

	/* 割り込み処理終了 */
	outp(INTCTRL, EOI);
}
