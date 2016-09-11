; BNN mdr.exe 演奏
; メインルーチン (for pc98dos)
;
; 基本的にトンキンハウスの物と同じだか、データが内蔵
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x2f

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
		mov	ax, 0x879B
		mov	bx, 0x05		; 演奏停止
		mov	cx, 0x1e
		int	int_driver

		mov	ax, 0x879B
		mov	bx, 0x06		; Fadeout指定
		mov	si, 0x03
		int	int_driver

		jmp	short .ed

.play:
		mov	ax, 0x879B
		mov	bx, 0x05		; 演奏停止
		mov	cx, 0x1e
		int	int_driver

		mov	ax, 0x879B
		xor	cx, cx
		xor	dx, dx
		mov	bx, 0x01		; 音色登録1
		int	int_driver

		mov	ax, 0x879B
		xor	cx, cx
		xor	dx, dx
		mov	bx, 0x02		; 音色登録2
		int	int_driver

		mov	dx, HOOTPORT + 2	; 再生曲番号
		in	al, dx
		xor	ch, ch
		mov	cl, al
		mov	ax, 0x879B
		xor	dx, dx
		mov	si,0x01
		mov	bx,0x03			; 再生
		int	int_driver

		jmp	.ed

patchmsg:
		db	0x0D,0x0A,'MDR driver for hoot ver 1.0 by RuRuRu',0x0D,0x0A,'$'

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
		ends

