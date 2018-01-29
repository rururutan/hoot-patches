; RBEEP.COM / PACMAIN.COM(CRC32:0xe1956223)演奏
; メインルーチン (for pc98dos)
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0xfe

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

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x100		; パラグラフサイズ(64K)
		int	0x21
		mov	[bufseg],ax
		push	ax
		pop	es

		push	ds
		lds	dx, [bufofs]
		mov	cx, 0xffff
		mov	ah, 0x3f		; [DOS] ファイルからの読み取り
		mov	bx, 0x09		; code 9
		int	0x21
		pop	ds

		mov	ah, 0x00		; Initialize
		int	int_driver

		mov	ah, 0x30		; Set wave table
		mov	al, 0x00
		mov	bx, 0x0001		; Length
		mov	dx, 0x61E3		; ES:DX data
		int	int_driver

		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
;		mov	ax, 0x9801		; ダミーポーリング
;		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

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
		mov	ah, 0x14
		int	int_driver
		mov	ah, 0x23
		int	int_driver
		jmp	short .ed

.play:
		mov	ax, [bufseg]
		mov	es, ax

		xor	ax,ax
		mov	dx,HOOTPORT+2		; 曲番号
		in	al,dx

		mov	di, 0x6AFB		; flag table
		add	di, ax
		shl	ax, 1
		mov	si, 0x6B07		; music data offset table
		add	si, ax
		mov	cx, [es:si]
		mov	si, cx
		mov	al, [es:di]
		test	al, 0x80
		jnz	.play_se

		mov	[musflg], ax
		mov	[es:si+0x02], es	; set segment
		mov	[es:si+0x06], es
		mov	[es:si+0x0a], es

		mov	ah, 0x11		; API 11 データ登録(ES:SI)
		int	int_driver

		mov	ax, [musflg]
		and	al, 0x01		; flag
		mov	ah, 0x16		; API 16 loop
		int	int_driver
		mov	ah, 0x12		; API 12 play data
		int	int_driver

		jmp	.ed

.play_se:
		mov	ah, 0x20
		int	int_driver
		mov	ah, 0x21
		int	int_driver

		jmp	.ed

bufofs:
		dw	0x0100
bufseg:
		dw	0x0000

musflg:
		dw	0x0000

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
		ends

