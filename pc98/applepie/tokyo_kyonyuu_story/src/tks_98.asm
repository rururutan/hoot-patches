; E東京巨乳ストーリー (C)AppliePie

%include 'hoot.inc'

		ORG	0x0000
		USE16
		CPU	186

OPNSEG		EQU	0x4000			; ドライバセグメント

start:
		cli
		cld
		mov	dx,HOOTFUNC
		mov	al,HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx,al

		mov	ax,0x1000
		mov	ss,ax
		mov	sp,0x8000
		mov	ax,cs
		mov	ds,ax
		mov	es,ax

		; hoot ドライバ登録
		xor	ax,ax
		mov	ds,ax
		mov	word [0x7f*4+0],hf_entry
		mov	[0x7f*4+2],cs

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

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
		mov	dx,HOOTPORT+2
		xor	ax,ax
		in	al,dx
		sub	al, 01
		mov	bx, ax
		shl	ax, 1			; x2
		add	ax, bx			; x3
		mov	[apitbl], ax
		pushf
		call	far [cs:apitbl]
		jmp	short .ed

.play2:
		jmp	short .ed

.stop:
		xor	ax,ax
		mov	[apitbl], ax
		pushf
		call	word OPNSEG:0x01e	; Stop
		jmp	short .ed

apitbl:
		dw	0x0000			; ofs
		dw	OPNSEG			; seg

		.ends

