; Reverser 氷結都市TOKYO F1.COM
; (C) RuRuRu
; 2023/01/08 1st Release

%include 'hoot.inc'
int_hoot	equ	07fh
int_drv		equ	0EBh

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

		mov	ax,cs			; スタック設定
		mov	ss,ax
		mov	sp,stack

		mov	bx,prgend
		add	bx,0x0f
		shr	bx,4
		mov	ah,0x4a			; [DOS] メモリブロックの縮小(ES:BX)
		int	0x21

		mov	ax,0x257f		; hootドライバ登録
		mov	dx,vect_hoot
		int	0x21

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

		call	drvini
		call	voireg
		call	musreg

mainloop:
		mov	ax,0x9801		; ダミーポーリング
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

vect_hoot:	pusha
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

.ed:		pop	es
		pop	ds
		popa
		iret

.play:
		mov	al,0x00
		mov	ah,0x03		; 演奏停止
		int	int_drv

		mov	dx, HOOTPORT + 2
		in	al, dx
		xor	bh, bh
		mov	bl, al

		mov	ax,mtbl
		add	bx,ax
		mov	al,[bx]		; Music No
		mov	ah,0x02		; 演奏
		mov	dl,0x4f
		int	int_drv
		jmp	short .ed

.stop:
.fadeout:
		mov	al,0x00		; 停止
		mov	ah,0x03		; 状態変更
		int	int_drv
		jmp	short .ed

drvini:
		mov	al,0xff
		mov	ah,0x03
		int	int_drv
		mov	al,0x01
		mov	ah,0x03
		int	int_drv
		mov	al,0xff
		mov	ah,0x06
		int	int_drv
		mov	al,0xff
		mov	ah,0x0a
		int	int_drv
		ret

; Regist tone data
voireg:
		push	ds
		mov	ah, 0x3f		; AH=3F file read
		mov	bx, 0x05		; FM_VOICE.DAT
		mov	cx, 0x1000
		push	cs
		pop	ds
		mov	dx, vocdat
		int	0x21
		pop	ds
		jc	.regend

		mov	ax,ds
		mov	cx,ax		; Data segment
		mov	dx,vocdat	; Data address
		mov	ah,0x09		; Regist Voice
		int	int_drv
.regend
		ret

; Regist music data
musreg:
		push	ds
		mov	ah, 0x3f		; AH=3F file read
		mov	bx, 0x06		; MUSICDAT.SYS
		mov	cx, 0x4000
		push	cs
		pop	ds
		mov	dx, musdat
		int	0x21
		pop	ds
		jc	.regend

		mov	di,musdat
		mov	si,di
		add	si,0x3c
		mov	[wofs], si
		mov	bx,mtbl
		mov	cx,0x1d
.reglp
		pusha
		mov	al,[si+02]
		mov	[bx],al
		mov	ah,01		; regist data
		mov	cx,ds		; segment
		mov	dx,si		; offset
		int	int_drv
		popa
		inc	bx
		add	di,0x02
		mov	ax,[di]
		mov	si,[wofs]
		add	si,ax
		loop	.reglp
.regend
		ret

wofs:		dw	0		; Work offset
mtbl:
		align	0x10
		times 0x40 db 0x00	; スタックエリア

vocdat:
		align	0x10
		times 0x1000 db 0xff	; スタックエリア

musdat:
		align	0x10
		times 0x4000 db 0x00	; スタックエリア

		align	0x10
		times 0x100 db 0xff	; スタックエリア

stack:

prgend:
		ends

