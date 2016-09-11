; MFD.COM
; hoot演奏ルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x7c

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

		mov	ah, 0x48		; AH=48 alloc memory
		mov	bx, 0x1000
		int	0x21
		mov	[bufseg],ax

		push	ds
		lds	si,[bufofs]
		mov	ah,0x08		; Set buffer(DS:SI)
		int	int_driver
		pop	ds

resist:
		mov	ax,0x257f		; hootドライバ登録
		mov	dx,vect_hoot
		int	0x21

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

mainloop:
		mov	ax,0x9801		; ダミーポーリング
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
		jz	.fadeout
.ed:
		pop	es
		pop	ds
		popa
		iret

.stop:
		mov	ah,0x01		; 演奏停止
		int	int_driver
		jmp	.ed

.fadeout:
		mov	ah,0x03		; 演奏停止
		mov	al,0x04		; speed
		int	int_driver
		jmp	.ed

.play:
		mov	al,0x01		; 演奏停止
		int	int_driver

		push	ds
		lds	dx,[bufofs]
		xor	bx,bx
		call	.fileload
		pop	ds
		jc	.ed

		mov	ah,0x00		; 演奏開始
		int	int_driver

		jmp	.ed

.fileload:
		mov	cx,0xffff
		mov	ah,0x3f		; [DOS] read hundle
		int	0x21
		ret

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

prgend:
		ends

