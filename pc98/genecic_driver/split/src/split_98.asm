; SPLIT.COM 演奏
; メインルーチン (for pc98dos)
;
; HOOTPORT + 2~3 : ファイルハンドル番号

%include 'hoot.inc'
int_hoot	equ	0x07f
int_driver	equ	0x0d2

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

;		mov	ah, 0x48		; AH=48 alloc memory
;		mov	bx, 0x1000
;		int	0x21
;		mov	[bufseg],ax

		push	es
		mov	ah,0x02
		int	int_driver
		mov	ax,[es:bx+2]
		mov	[bufseg],ax
		pop	es

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
		jz	short .fadeout

.ed:
		pop	es
		pop	ds
		popa
		iret

.play:
;		mov	ax,0x0100		; 演奏停止
;		int	int_driver

		xor	cx,cx			; 4byte seek
		mov	dx,0x04
		xor	al,al
		xor	bx,bx
		mov	ah,0x42
		int	21h

		push	ds
		lds	dx, [bufofs]
		mov	cx,0xffff
		xor	bx,bx
		mov	ah,3fh
		int	21h

		mov	ax, 0x0101		; 再生
		int	int_driver
		pop	ds

		jmp	short .ed

.stop:
.fadeout:
		mov	ax, 0x0100
		int	int_driver
		jmp	short .ed

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:

prgend:
		ends

