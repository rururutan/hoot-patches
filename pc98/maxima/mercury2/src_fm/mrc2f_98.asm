; Maxima Mercury2 MERCURY.EXE(CRC32:0x371BDF8B)
; hoot 2018/12版以降で動作
;
; @autor RuRuRu
; @date 2025/11/28 1st Release
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

		mov	ax, cs				; スタック設定
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x3000		; パラグラフサイズ
		int	0x21
		mov	[ovrparam],ax		; entry更新
		add ax, 0x705			; @FIXME FM driver segment offset
		mov	[initseg],ax
		mov	[playseg],ax
		mov	[stopseg],ax
		mov	[seseg],ax

		call	drv_load

		;  alloc buffer memory
		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x400		; パラグラフサイズ
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

		call	far [cs:initofs]	; Sound initialize
		call	far [cs:stopofs]	; Stop

mainloop:
		mov	ax, 0x9801		; ダミーポーリング
		int	0x18
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
		call	far [cs:stopofs]	; Stop
		jmp	short .ed

.play:
		mov	dx, HOOTPORT + 3
		in	al, dx
		cmp	al, 0x01
		jz	.effect

		call	far [cs:stopofs]	; Stop

		push	ds
		mov	ah, 0x3f		; AH=3F file read
		xor	bx, bx
		mov	cx, 0xffff
		lds	dx, [bufofs]
		int	0x21
		pop	ds
		jc .ed

		push ds
		push es
		les	dx, [bufofs]
		push	es					; seg
		push	dx					; ofs

		mov	ax, [playseg]		; ルーチン内でDS設定忘れてるので設定
		add 	ax, 0x1bd5		;
		mov	ds, ax
		call	far [cs:playofs]	; Sound play
		add sp,byte +0x4
		pop es
		pop ds
		jmp	.ed

.effect:
		mov	dx,HOOTPORT+2			; Song no
		in	al,dx
		xor ah,ah
		push ax
		call	far [cs:seofs]		; Effect play
		add sp,byte +0x2
		jmp	.ed


; Load MERCURY.EXE
drv_load:
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ax, 0x4b03			; [DOS] Overlay Load
		mov	dx, exec_path		; パス名 (DS:DX)
		mov	bx, ovrparam		; パラメータブロック(ES:BX)
		int	0x21
		ret

exec_path:
	db	'MERCURY.EXE',00

bufofs:
		dw	0x01c
bufseg:
		dw	0x0000
playofs:
		dw	0x00E2
playseg:
		dw	0x0000
initofs:
		dw	0x0020
initseg:
		dw	0x0000
stopofs:
		dw	0x016B	; stop
;		dw	0x01B0	; fadeout
stopseg:
		dw	0x0000
seofs:
		dw	0x01CD
seseg:
		dw	0x0000

; Over ray load用パラメータブロック
ovrparam:
		dw	0			; ロードセグメント
		dw	0			; リロケーションファクタ

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:


