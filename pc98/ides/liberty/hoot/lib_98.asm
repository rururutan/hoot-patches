; Liberty (C)Cocktail Soft 用
; メインルーチン (for NASM)

%include 'hoot.inc'

		ORG	0x0000
		USE16
		CPU	186

OPNSEG		EQU	0x1ed6		; オープニング用セグメント

start:		cli
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

		mov	dx,HOOTFUNC		; hoot呼び出しを許可
		mov	al,HF_ENABLE
		out	dx,al
		sti

mainloop:	mov	ax,0x9801
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98VX::Play  ロード前
; inp8(HOOTPORT) = 1 → PC98VX::Play  ロード後
; inp8(HOOTPORT) = 2 → PC98VX::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

hf_entry:	push	ds
		push	es
		pusha
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	dx,HOOTPORT
		in	al,dx
		cmp	al,HP_PLAY
		jz	short .play
		cmp	al,HP_STOP
		jz	short .stop
.ed:		popa
		pop	es
		pop	ds
		iret

.check:
		mov	dx,HOOTPORT+3		; オープニング/エンディング指定の判定
		in	al,dx
		cmp	al,1
		ret

.play:	
		call	.check
		jz	.seplay

		mov	dx,HOOTPORT+2
		in	al,dx
		call	word OPNSEG:0x0086	; Request
		jmp	short .ed

.seplay:
		mov	dx,HOOTPORT+2
		in	al,dx
		call	word OPNSEG:0x029a	; S.E.
		jmp	short .ed

.stop:
		call	word OPNSEG:0x017c	; フェードアウト
		jmp	short .ed

		ends

