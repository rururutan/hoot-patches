; MAKO & DRI player for pc98dos driver
; nasm version
; 2007/08/27 1st Release
; 2023/07/13 Clean up & PCM support

%include 'hoot.inc'
int_hoot	equ	0x07f
int_mako	equ	0x040
int_dri		equ	0x041

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

.stop:
.fadeout:
		mov	ax,0x0100		; [mako] stop
		int	int_mako
		call	pcm_stop
		jmp	short .ed

.play:
		mov	ax,0x0100		; [mako] play stop
		int	int_mako

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

		mov	dx,HOOTPORT+3
		in	al,dx
		cmp	al,1
		jz	.pcm_play

		mov	ah,0x00			; [mako] play from buffer
		int	int_mako

		jmp	.ed

.pcm_play:
		mov	ah,0x40			; [makop] pcm start
		int	int_mako
		jmp	.ed

pcm_stop:
		mov	ah,0x41			; [makop] pcm stop
		int	int_mako
		ret

musname:
		db	'A:AMUS.DAT',00,00,00,00,00,'$'

patchmsg:
		db	0x0D,0x0A,'MAKO & DRI player for hoot driver ver 2.0 by RuRuRu',0x0D,0x0A,'$'

loadseg:
		dw	0

prgend:
;		.ends

