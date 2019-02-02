; Broderband/Blodia BLODIA.EXE(CRC32:0x78bf364c)
;
; @autor RuRuRu
; @date 2019/01/30 1st Release
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
		mov	[initseg],ax
		mov	[playseg],ax
		mov	[loadseg],ax
		mov	[stopseg],ax
		mov	[bufseg],ax

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
		push	ds
		mov	ax, [bufseg]		; 割り込みルーチン内でDS設定忘れてるので設定
		add	ax, 0x4fb		; @FIXME DS segment offset
		mov	ds, ax
		call	far [cs:stopofs]	; Stop
		pop	ds
		jmp	short .ed

.play:
		push	ds
		mov	ax, [bufseg]		; 割り込みルーチン内でDS設定忘れてるので設定
		add	ax, 0x4fb		; @FIXME DS segment offset
		mov	ds, ax

		mov	dx,HOOTPORT+2		; 曲番号
		xor	ax,ax
		in	al,dx
		call	far [cs:loadofs]	; Load data
		call	far [cs:playofs]	; Sound play
		pop	ds
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

		push	es
		mov	ax, [bufseg]
		mov	es, ax

		mov	al, 0xcb		; patch to retf
		mov	[es:0x4cb2], al
		mov	[es:0x4cbc], al
		mov	[es:0x4dc9], al
		mov	[es:0x4dce], al
		mov	[es:0x4dd3], al
		mov	[es:0x4de0], al
		mov	[es:0x4de3], al
		mov	[es:0x4de4], al
		mov	[es:0x4de5], al

		push	ds
		mov	ax, [bufseg]
		add	ax, 0x4fb		; @FIXME DS segment offset
		mov	ds, ax
		call	far [cs:initofs]	; Sound initialize
		pop	ds

		pop	es

		ret

exec_path:
	db	'BLODIA.EXE',00

bufseg:
		dw	0x0000
playofs:
		dw	0x4CCA
playseg:
		dw	0x0000
initofs:
		dw	0x4CA2
initseg:
		dw	0x0000
loadofs:
		dw	0x4CBD
loadseg:
		dw	0x0000
stopofs:
		dw	0x4CD7
stopseg:
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

