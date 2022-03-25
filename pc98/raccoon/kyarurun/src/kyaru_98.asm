; プリティ戦隊きゃるるーん KYARURU.EXE(CRC32:0xa068271d)演奏
; (C) RuRuRu
; 2022/03/26 1st Release
;

%include 'hoot.inc'
int_hoot	equ	0x7f

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

		mov	ah, 0x48		; AH=48 alloc memory
		mov	bx, 0x1000
		int	0x21
		mov	[bufseg],ax

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x2000		; パラグラフサイズ
		int	0x21
		mov	[ovrparam],ax		; entry更新
		mov	[ovrseg],ax
		add	ax, 0x25dc		; @FIXME driver segment offset
		mov	[initseg],ax
		mov	[loadseg],ax
		mov	[stopseg],ax

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
		call	far [cs:stopofs]
		jmp	short .ed

.play:
		mov	dx,HOOTPORT+2		; 曲番号
		in	al,dx
		xor	ah,ah

		les	dx, [cs:bufofs]		; buffer ptr ES:DX
		call	far [cs:loadofs]	; Load & play

		jmp	.ed

; Load EXE
drv_load:
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ax, 0x4b03		; [DOS] Overlay Load
		mov	dx, exec_path		; パス名 (DS:DX)
		mov	bx, ovrparam		; パラメータブロック(ES:BX)
		int	0x21

		call	far [cs:initofs]	; Sound initialize
		ret

exec_path:
	db	'KYARURU.EXE',00

ovrofs:
		dw	0x0000
ovrseg:
		dw	0x0000
bufofs:
		dw	0x2E07
bufseg:
		dw	0x0000
initofs:
		dw	0x0002
initseg:
		dw	0x0000
loadofs:
		dw	0x004a
;		dw	0x0071
loadseg:
		dw	0x0000
stopofs:
		dw	0x00f8
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

