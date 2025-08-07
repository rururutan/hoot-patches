; Battle Block Alfin: BLOCK.EXE(CRC32:0xabf9a308(Un-exepack) / 0xc1769415(Original))
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
		mov	bx,0x8000		; パラグラフサイズ
		int	0x21
		mov	[ovrparam],ax		; entry更新
		add	ax, 0x40
		mov	[ovrseg],ax
		mov	[initseg],ax
		mov	[loadseg],ax
		mov	[loadseseg],ax

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
		mov	ah, 06
		mov	al, 0x14		; Fadeout
		int	int_driver
		jmp	short .ed

.play:
		mov	dx, HOOTPORT + 3
		in	al, dx
		cmp	al, 0x00
		jnz	.play_se

		mov	dx,HOOTPORT+2		; Song no
		in	al,dx
		call	far [cs:loadofs]	; Load internal data
		jmp	.ed

.play_se:
		mov	dx,HOOTPORT+2		; Song no
		in	al,dx
		mov	ah, 0x04
		int	int_driver

		jmp	.ed


; Load EXE
drv_load:
		push	ds
		push	es
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ax, 0x4b03		; [DOS] Overlay Load
		mov	dx, exec_path		; パス名 (DS:DX)
		mov	bx, ovrparam		; パラメータブロック(ES:BX)
		int	0x21

		push	ds
		mov	ax, [cs:ovrseg]
		mov	ds, ax
		mov	al, 0xcb		; Patch: ret -> retf
		mov	[0x00AF], al
		mov	[0x64FA], al
		mov	[0xB70B], al
		mov	al, 0x90
		mov	[0x009b], al
		mov	[0x009c], al
;		pop	ds

;		push	ds
		mov	ax, [cs:ovrseg]
		sub	ax, 0x50
		mov	ds, ax
		call	far [cs:initofs]	; Sound initialize
		pop	ds

		call	far [cs:loadseofs]	; Load SE data

		pop	es
		pop	ds

		ret

exec_path:
	db	'BLOCK.EXE',00

ovrofs:
		dw	0x0000
ovrseg:
		dw	0x0000
initofs:
		dw	0xb6a6
initseg:
		dw	0x0000
loadofs:
		dw	0x64e0
loadseg:
		dw	0x0000
loadseofs:
		dw	0x008d
loadseseg:
		dw	0x0000

; Over ray load用パラメータブロック
ovrparam:
		dw	0			; ロードセグメント
		dw	0			; リロケーションファクタ

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
