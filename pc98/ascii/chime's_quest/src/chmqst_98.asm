; Chime's Quest RPG.EXE(CRC32:0xc459b6d1)演奏
; hoot 2018/12版以降で動作
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0xd2

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

		mov	dx, HOOTFUNC
		mov	al, HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx, al

		mov	ax, cs			; スタック設定
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x2000		; パラグラフサイズ
		int	0x21
		mov	[ovrparam],ax		; entry更新
		mov	[bufseg],ax
		add	ax, 0x4be		; @FIXME code segment offset
		mov	[allocseg],ax
		mov	[initseg],ax
		mov	[loadseg],ax

		call	drv_load

		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
;		mov	ax, 0x9801		; ダミーポーリング
;		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)〜inp8(HOOTPORT+5)

vect_hoot:
		pusha
		push	ds
		push	es
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	dx, HOOTPORT
		in	al, dx
		cmp	al, HP_PLAY
		jz	short .play
		cmp	al, HP_STOP
		jz	short .fadeout
.ed:
		pop	es
		pop	ds
		popa
		iret
	
.stop:
.fadeout:
		mov	al, 0x00		; 演奏停止
		int	int_driver
		jmp	short .ed

.play:
		mov	ax, [bufseg]		; 割り込みルーチン内でDS設定忘れてるので設定
		add 	ax, 0xed7		; @FIXME RPG.EXE data segment
		mov	ds, ax

		mov	dx,HOOTPORT+2		; 曲番号
		in	al,dx
		mov	ah,al
		mov	al, 0x09
		int	int_driver

		jmp	.ed

; Load RPG.EXE
drv_load:
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ax, 0x4b03		; [DOS] Overlay Load
		mov	dx, exec_path		; パス名 (DS:DX)
		mov	bx, ovrparam		; パラメータブロック(ES:BX)
		int	0x21

		push	ds
		mov	ax, [bufseg]
		add	ax, 0x4be		; @FIXME code segment
		mov	ds, ax

		mov	al, 0xc3
		mov	[ds:0x75a0], al
		mov	[ds:0x72e0], al
		mov	[ds:0x7e70], al
		mov	[ds:0x74dd], al		; file error
		mov	al, 0xcb
		mov	[ds:0x0098], al
		mov	[ds:0x00ca], al
		mov	[ds:0x019d], al
		mov	[ds:0x025e], al
		mov	[ds:0x357f], al		; alloc error

		call	far [cs:allocofs]	; Buffer allocate
		call	far [cs:initofs]	; Sound initialize
		call	far [cs:loadofs]	; Load internal data

		pop	ds

		ret

exec_path:
	db	'RPG.EXE',00

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000
allocofs:
		dw	0x0019
allocseg:
		dw	0x0000
initofs:
		dw	0x00b7
initseg:
		dw	0x0000
loadofs:
		dw	0x014a
loadseg:
		dw	0x0000

; Over ray load用パラメータブロック
ovrparam:
		dw	0			; ロードセグメント
		dw	0			; リロケーションファクタ

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
		ends

