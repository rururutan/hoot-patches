; 空想特撮シリーズ ウルトラ作戦 科特隊出撃せよ! MISULT.EXE(CRC32:0x1c98eb2e)演奏
; hoot 2018/12版以降で動作
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x57

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
		mov	[ovrseg],ax
		add	ax, 0xA14		; @FIXME code segment offset
		mov	[initseg],ax

		call	drv_load

		mov	ah, 0x48		; AH=48 alloc memory
		mov	bx, 0x1000
		int	0x21
		mov	[bufseg],ax

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

.play_se:
		mov	dx,HOOTPORT+2		; 曲番号
		in	al,dx
		mov	ah, 0x21		; SE
		mov	cx, 0x0000		; 1 loop
		int	int_driver
		jmp	short .ed

.stop:
.fadeout:
		mov	ax, 0x0200		; Stop Music
		int	int_driver
;		mov	ax, 0x2100		; Stop SE
;		mov	cx, 0x0000
		int	int_driver
		jmp	short .ed

.play:
		mov	dx, HOOTPORT + 3
		in	al, dx
		cmp	al, 0x00
		jnz	.play_se

		mov	ax, 0x0200		; Stop Music
		int	int_driver

		push	ds
		mov	ah, 0x3f		; AH=3F file read
		xor	bx, bx
		mov	cx, 0xffff
		lds	dx, [bufofs]
		int	0x21
		pop	ds
		jc	.ed

		mov	dx, HOOTPORT + 4
		in	al, dx			; Loop count
		lds	dx, [bufofs]
		push	ds
		pop	bx
		mov	si,dx
		mov	cx, [si]
		mov	ah, 0x01		; AH:Play
		int	int_driver

		jmp	.ed

; Load MISULT.EXE
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
	db	'MISULT.EXE',00

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000
ovrofs:
		dw	0x0000
ovrseg:
		dw	0x0000
initofs:
		dw	0x1bbe
initseg:
		dw	0x0000

; Over ray load用パラメータブロック
ovrparam:
		dw	0			; ロードセグメント
		dw	0			; リロケーションファクタ

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
