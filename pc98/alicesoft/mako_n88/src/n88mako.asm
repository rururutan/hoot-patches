; MAKO N88(86) (C)Alicesoft
;  分割ファイル版

%include 'hoot.inc'

		ORG	0x0000
		USE16
		CPU	186

OPNSEG	EQU	0x100				; ドライバセグメント

start:
		cli
		cld
		mov	dx,HOOTFUNC
		mov	al,HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx,al

		xor	ax,ax
		mov	ss,ax
		mov	sp,0x1000
		mov	ax,cs
		mov	ds,ax
		mov	es,ax

		; hoot ドライバ登録
		xor	ax,ax
		mov	ds,ax
		mov	word [0x7f*4+0],hf_entry
		mov	[0x7f*4+2],cs

		; Register dummy int C4H
		mov	word [0xC4*4+0],dummy
		mov	[0xC4*4+2],cs

		; Register int D2H
		push	ds
		mov	ax, 0xCEE0
		mov	ds, ax
		mov	ax, word [ds:0x0006]
		pop	ds
		mov	word [0xD2*4+0],ax
		mov	ax, 0xCEE0
		mov	[0xD2*4+2],ax

		; Set enable flag
		push	ds
		mov	ax, 0xA000
		mov	ds, ax
		mov	al, 0xff
		mov	[0x3fee], al
		pop	ds

		; Sound Driver init
		call far [cs:initofs]

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

		mov ax, 0x0200		; Stop
		int	0x40

mainloop:
		mov	ax,0x9801
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98VX::Play  ロード前
; inp8(HOOTPORT) = 1 → PC98VX::Play  ロード後
; inp8(HOOTPORT) = 2 → PC98VX::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

hf_entry:
		pusha
		push	ds
		push	es
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	dx,HOOTPORT
		in	al,dx
		cmp	al,HP_PLAY
		jz	short .play
		cmp	al,HP_LOADPLAY
		jz	short .play2
		cmp	al,HP_STOP
		jz	short .stop
.ed:
		pop	es
		pop	ds
		popa
		iret

.play:
		mov ax, 0x0200		; API 02 Stop
		int	0x40

		xor	ax,ax
		mov	dx,HOOTPORT+2
		in	al,dx
		out	dx,al

		jmp	short .ed

.play2:
		mov ax, 0x9800
		push	ax
		pop	ds
		xor	ax,ax
		push	ax
		pop	si
		mov ax, 0x0000		; API 00 Set / Play
		int	0x40
		jmp	short .ed

.stop:
		mov ax, 0x0200		; API 02 Stop
		int	0x40
		jmp	short .ed

dummy:
		iret

initofs:
		dw	0x0000
initseg:
		dw	0x9e00

