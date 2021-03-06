; SDRV.SYS 演奏
; メインルーチン (for pc98dos)
;
; SS.COMと互換だがドライバ内蔵データ再生の対応を追加。
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x41

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

		mov	dx, HOOTFUNC
		mov	al, HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx, al

		mov	ax, cs			; スタック設定
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
		mov	ax, 0x9801		; ダミーポーリング
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)〜inp8(HOOTPORT+5)

vect_hoot:
		pusha
		push	ds
		push	es
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	dx, HOOTPORT
		in	al, dx
		cmp	al, HP_PLAY
		jz	short .play
		cmp	al, HP_STOP
		jz	short .fadeout
.ed:
		pop	es
		pop	ds
		popa
		iret

.stop:
.fadeout:
		mov	ah, 0x02		; 演奏停止
		int	int_driver
		jmp	short .ed

.play:
;		mov	ax, 0x0200		; 演奏停止
;		int	int_driver

		mov	dx, HOOTPORT + 5
		in	al, dx
		cmp	al, 0x01
		jnz	.play_file

		push	cs
		pop	cx
		mov	bx, cb_func
		mov	ah, 0x07
		mov	dx, HOOTPORT + 2
		in	al, dx
		mov	dx, 0x0
		int	int_driver

		jmp	.ed

.play_file:
		push	ds
		mov	ah, 0x3f		; AH=3F file read
		xor	bx, bx
		mov	cx, 0x10
		push	cs
		pop	ds
		mov	dx, namebuf
		int	0x21
		pop	ds
		jb	.playerr

		push	cs
		pop	si
		mov	di, namebuf
		mov	ah, 0x01		; 再生
		int	int_driver

.playerr:
		jmp	.ed

cb_func:
		retf

namebuf:
		times 0x10 db 0x00		; ファイル名バッファ

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:

prgend:
		ends

