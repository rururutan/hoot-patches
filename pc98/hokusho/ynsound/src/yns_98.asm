; HOKUSHO YNSOUND.COM
; hoot演奏ルーチン (for pc98dos)
;
; hootport + 6が非0ならアーカイバ読み込み
;
; [アーカイバ形式]
;  DWORD offset
;  DWORD size
; の列挙でoffsetが0でヘッダ終了
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x40

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
		mov	ah,0x04		; 演奏停止
		int	int_driver
		jmp	.ed

.fadeout:
		mov	ah,0x09		; 演奏停止
		mov	al,0x91		; speed
		int	int_driver
		jmp	.ed

.play:
		mov	ah,0x00
		int	int_driver

		mov	ax,0x0101
		int	int_driver

		mov	ah,0x03
		int	int_driver

; single / arc check
		mov	dx, HOOTPORT + 4
		in	al, dx
		cmp	al, 0x00
		jz	.single

; archiver type
		dec	al
		xor	ah, ah
		xor	cx, cx
		shl	ax, 3
		mov	dx, ax
		mov	ax, 0x4200		; AH=42 file seek
		xor	bx, bx
		int	0x21
		jb	.ed

		mov	ah, 0x3f		; AH=3F file read
		xor	bx, bx
		mov	cx, 0x0008		; 8byte
		mov	dx, fileinfo
		int	0x21
		jb	.ed

		mov	ax, 0x4200		; AH=42 file seek
		mov	cx, [fileofs+2]
		mov	dx, [fileofs]
		xor	bx, bx
		int	0x21
		jb	.ed

		push	ds
		mov	cx,[filesize]
		lds	dx,[bufofs]
		xor	bx,bx
		call	.fileload
		pop	ds
		jc	.ed
		jmp	.loaded

; single type
.single:
		push	ds
		lds	dx,[bufofs]
		xor	bx,bx
		mov	cx,0xffff
		call	.fileload
		pop	ds
		jc	.ed

.loaded:
		push	ds
		lds	si,[bufofs]
		mov	ax,0x0606			; Set buffer(DS:SI)
		int	int_driver
		pop	ds

		mov	ax,0x0b04
		int	int_driver

		mov	ah,0x07		; 演奏開始
		int	int_driver

		jmp	.ed

; in: ds:dx = buffer segment
; in: bx = handle number
.fileload:
		mov	ah,0x3f		; [DOS] read hundle
		int	0x21
		jc	.loadend
		mov	ax,0x4200	; [DOS] 先頭へシーク
		mov	cx,0x0000
		mov	dx,0x0000
		int	0x21
.loadend:
		ret

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

fileinfo:
fileofs:
		dw	0x0000
		dw	0x0000
filesize:
		dw	0x0000
		dw	0x0000

prgend:
		ends

