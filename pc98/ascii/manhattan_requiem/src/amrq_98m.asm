; PLAY.com(ASCII MRQ)
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	07fh

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

		mov	ah, 0x48		; [DOS] ドライババッファの割り当て
		mov	bx, 0xfff
		int	0x21
		mov	[drvseg], ax

		mov	ah,0x3d			; [DOS] ファイルオープン
		mov	dx,drvname
		int	0x21
		jc	resist

		push	ds
		mov	ds,[drvseg]
		mov	dx,0x0000
		mov	cx,0xffff
		mov	bx,ax
		mov	ah,0x3f			; [DOS] ファイルリード
		int	0x21
		pop	ds

		mov	ah,0x3e			; [DOS] ファイルクローズ
		int	0x21

		push	ds			; int d2登録
		xor	dx,dx
		mov	ax,[drvseg]
		mov	ds,ax
		mov	ax,0x25d2
		int	0x21
		pop	ds

;		mov	al,0x01			; 初期化
;		mov	ah,0x02			; MIDI音源
;		int	0xd2

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
		jz	short .fadeout
.ed:
		pop	es
		pop	ds
		popa
		iret

.play:
		mov	al,0x00			; バッファポインタ取得
		int	0xd2

		push	ds
		mov	ax,[drvseg]
		mov	ds,ax
		mov	dx,cx
		mov	cx,0xffff
		mov	ah,0x3f			; read hundle
		xor	bx,bx			; 標準入力から
		int	0x21			; 曲データロード
		pop	ds
		jc	.ed

		mov	al,0x01			; 初期化
		mov	ah,0x02			; MIDI音源
		int	0xd2

		mov	al,0x02			; 演奏
		int	0xd2
		jmp	short .ed

.stop:
		mov	ah,0x00
		mov	al,0x03			; 演奏停止
		int	0xd2

		jmp	short .ed

.fadeout:
		mov	ah,0x01
		mov	al,0x03			; 演奏停止
		int	0xd2
		jmp	short .ed

drvofs:		dw	0x0
drvseg:		dw	0x0			; ドライバセグメント
drvname		db	'PLAY.COM',00,'$'

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:

prgend:
		ends

