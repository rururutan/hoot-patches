; Humming bird MUSDRV3 演奏
; メインルーチン (for pc98dos)
; ロードスCD 音色データ変更対応版

%include 'hoot.inc'
int_hoot	equ	0x7f
int_drv		equ	0x43

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

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0xfff		; パラグラフサイズ(64K)
		int	0x21
		mov	[loadseg],ax

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x060		; パラグラフサイズ(15K)
		int	0x21
		mov	[toneseg],ax

		mov	al,00			; 初期化
		int	int_drv

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
		mov	al,0x04			; 演奏停止
		int	int_drv

		call	toneload

		push	ds
		mov	ax,[cs:loadseg]
		mov	ds,ax
		xor	dx,dx
		mov	cx,0xffff
		mov	ah,0x3f			; read hundle
		xor	bx,bx			; 標準入力から
		int	0x21			; 曲データロード
		pop	ds
		jc	.ed

		push	ds
		mov	ax,[cs:loadseg]
		mov	ds,ax
		xor	dx, dx
		mov	al,0x01			; 演奏開始(ds:dx)
		int	int_drv
		pop	ds
		jmp	short .ed

.stop:
		mov	al,0x04			; 演奏停止
		int	int_drv
		jmp	short .ed

.fadeout:
		mov	al,0x02			; 演奏停止
		mov	dl,0x0f
		int	int_drv
		jmp	short .ed

toneload:
		mov	dx,HOOTPORT+4		; 音色ハンドル取得
		xor	ah,ah
		in	al,dx
		mov	bx,ax

		mov	ah,0x42			; seek
		mov	al,0			; 先頭
		xor	cx,cx
		xor	dx,dx
		int	0x21

		push	ds
		mov	ax,[cs:toneseg]
		mov	ds,ax
		xor	dx,dx
		mov	cx,0xffff
		mov	ah,0x3f			; read hundle

		int	0x21			; 音色ロード

		xor	dx, dx
		mov	ax, [cs:toneseg]
		mov	ds, ax
		mov	al,0x07			; 音色ロード
		int	int_drv
		pop	ds
		ret

loadseg:	dw	0			; ロードセグメント
toneseg:	dw	0			; 音色セグメント

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
		ends

