; MDRV 演奏
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	7fh
int_mdrv	equ	0d2h

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

		mov	ax,0x257f		; hootドライバ登録
		mov	dx,vect_hoot
		int	0x21

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

mainloop:	mov	ax,0x9801		; ダミーポーリング
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
		pop	dx
		popa
		iret

.play:
		mov	ah, 3fh		; ファイル名のロード(coninから取得)
		xor	bx,bx
		mov	cx, -1
		mov	dx,filename
		int	21h
		jc	.stop
		mov	bx,ax
		mov	[filename+bx], byte 0

		mov	dx,filename
		mov	cx,cs
		mov	al,0x06		; データロード(cx:dx)
		int	int_mdrv

		mov	al,0x02		; 演奏停止
		int	int_mdrv

		mov	al,0x01		; 演奏開始
		int	int_mdrv
		jmp	short .ed

.stop:
		mov	al,0x02		; 演奏停止
		int	int_mdrv
		jmp	short .ed

.fadeout:
		mov	al,0x02		; 演奏停止(fade out無し)
		int	int_mdrv
		jmp	short .ed

filename:
		; ファイル名格納用バッファ
		times 0x10 db 0x00

prgend:
		ends

