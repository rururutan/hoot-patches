; FM.COM 'NAK OPN DRIVER'演奏
; メインルーチン (for pc98dos)
;
; HOOTPORT + 2~3 : ファイルハンドル番号
; HOOTPORT + 4   : 曲番号
;
; SCR.BINの連結方法
;
; BYTE SONG NUMBER
; WORD OFFSET
;  x SONG NUMBER分
; BYTE DATA
;


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

		mov	ah, 0x48		; AH=48 alloc memory
		mov	bx, 0x1000
		int	0x21
		mov	[bufseg],ax

		mov	al,0x00			; init
		int	int_driver

		mov	dx, namebuf
		mov	cx, 0x10
		mov	bx, 0x08
		mov	ah, 3fh
		int	21h

		mov	bx, namebuf
		add	bx, ax
		mov	byte [bx], 0x00

		mov	al,0x04			; FM tone load
		mov	si, namebuf
		int	int_driver

		mov	dx, namebuf
		mov	cx, 0x10
		mov	bx, 0x09
		mov	ah, 3fh
		int	21h

		mov	bx, namebuf
		add	bx, ax
		mov	byte [bx], 0x00

		mov	al,0x05			; PSG tone load
		int	int_driver

		mov	al,0x06
		int	int_driver

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
;		mov	al,0x03		; 演奏停止
;		int	int_driver

		push	ds
		lds	dx, [bufofs]
		mov	cx,0xffff
		xor	bx,bx
		mov	ah,3fh
		int	21h
		pop	ds

		xor	ah,ah
		mov	dx,HOOTPORT+4
		in	al,dx

		call	calc_ofs

		mov	bx, [bufseg]
		mov	es, bx
;		mov	bx, [readofs]
		mov	bx, ax
		mov	al, 0x01		; 再生(ES:BX)
		int	int_driver

		jmp	short .ed

.stop:
.fadeout:
		mov	al, 0x03
		int	int_driver
		jmp	short .ed

; IN AL = no
calc_ofs:
		push	es
		push	bx
		push	cx

		push	ax

		les	bx, [bufofs]
		mov	ah, [es:bx]
		mov	[totalnum], ah

		mov	al, 0x02
		mul	byte [totalnum]
		add	ax, 0x01
		mov	cx, ax

		pop	ax

		shl	ax, 1
		add	ax, 1
		mov	bx, ax
		mov	ax, word [es:bx]

		add	ax, cx
		mov	[readofs], ax

		pop	cx
		pop	bx
		pop	es
		ret

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

totalnum:
		db	0x00

namebuf:
		times 0x10 db 0x00		; ファイル名バッファ

readofs:
		dw	0x0000

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:

prgend:
		ends

