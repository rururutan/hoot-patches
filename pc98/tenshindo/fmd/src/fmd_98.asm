; FMD.COM(GR)演奏
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x07f
int_drv		equ	0x050

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

.enable_hoot:
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
		jz	short .stop
.ed:
		pop	es
		pop	dx
		popa
		iret

.stop:
		mov	bx,0x01			; 演奏停止
		int	int_drv
		jmp	.ed

.play:
		mov	bx,0x00			; 演奏開始
		mov	dx,HOOTPORT+2
		in	al,dx
		xor	ah,ah
;		mov	ax,0x01
		int	int_drv

		jmp	short .ed

		ends

