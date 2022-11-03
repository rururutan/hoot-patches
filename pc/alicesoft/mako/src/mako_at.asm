; MAKO & DRI player for pcatdos driver
; nasm version
; (C) RuRuRu
; 2007/09/27 1st Release

%include 'hoot.inc'
int_hoot	equ	0x07f
int_mako	equ	0x060
int_dri		equ	0x061

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax,cs
		mov	ds,ax
		mov	es,ax

		mov	dx,HOOTFUNC
		mov	al,HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx,al

		mov	bx,prgend
		add	bx,0x0f
		shr	bx,4
		mov	ah,0x4a			; [DOS] メモリブロックの縮小(ES:BX)
		int	0x21

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x1000
		int	0x21
		mov	[loadseg],ax

		mov	ah,0x25			; hootドライバ登録
		mov	al,int_hoot
		mov	dx,vect_hoot
		int	0x21

		mov	ah,0x09
		mov	dx,patchmsg
		int	0x21

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

mainloop:
		mov	ax,0x9801
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

vect_hoot:
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
		cmp	al,HP_STOP
		jz	short .fadeout

.ed:
		pop	es
		pop	ds
		popa
		iret

.play:
		mov	ax,0x0100		; [mako] play stop
		int	int_mako

		; fix file offset
		mov	ah,0x42
		xor	cx,cx
		xor	dx,dx
		mov	al,0x00
		int	21h

		; get data index
		mov	dx,HOOTPORT+2
		in	al,dx
		mov	cl,al
		xor	ch,ch
		dec	cx

		mov	ah,00			; [dri] load file
		mov	dx,musname		; file name(DS:DX)
		mov	bx,[cs:loadseg]		; buffer ptr(BX:BP)
		xor	bp,bp
		int	int_dri
		cmp	ax,0
		jnz	.ed

		mov	bx,[cs:loadseg]		; buffer ptr(DS:SI)
		mov	ds,bx
		xor	si,si
		mov	ah,0x00			; [mako] play from buffer
		int	int_mako

		jmp	short .ed

.stop:
.fadeout:
		mov	ax,0x0100		; [mako] stop
		int	int_mako
		jmp	short .ed

musname:
		db	'A:AMUS.DAT',00,00,00,00,00,'$'

patchmsg:
		db	0x0D,0x0A,'MAKO & DRI player for hoot driver ver 1.0 by RuRuRu',0x0D,0x0A,'$'

loadseg:
		dw	0

prgend:
		ends

