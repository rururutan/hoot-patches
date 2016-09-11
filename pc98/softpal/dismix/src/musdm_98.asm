; music.com(DISMIX)演奏
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x07f
int_drv		equ	0x040

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
		mov	bx,0x100		; パラグラフサイズ(64K)
		int	0x21
		mov	[loadseg],ax

		mov	ax,0x257f		; hootドライバ登録
		mov	dx,vect_hoot
		int	0x21

		mov	ax,[cs:loadseg]
		mov	ds,ax
		xor	dx,dx
		mov	cx,0x400
		mov	ah,0x3f			; [DOS] ファイルからの読み取り
		mov	bx,0x08			; 8番固定
		int	0x21			; 環境データロード
		jc	.enable_hoot

		mov	ds,ax
		mov	bx,ds
		xor	cx,cx
		mov	al,0x07			; 環境ロード(bx:cx)
		int	int_drv

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
		mov	al,0x02			; 演奏停止
		int	int_drv
		jmp	.ed

.play:
		mov	al,0x02			; 演奏停止
		int	int_drv

		mov	ax,[cs:loadseg]
		mov	ds,ax
		mov	dx,0x400
		mov	cx,0x2000
		mov	ah,0x3f			; [DOS] ファイルからの読み取り
		xor	bx,bx			; 標準入力から
		int	0x21			; 曲データロード
		jc	.ed

		mov	bx,dx
		cmp	byte [ds:bx],0x08	; 音色付きデータ?
		jnz	.tone_load

		mov	bx,ds
		mov	cx,dx

		add	cx,0x50
		mov	al,0x05			; 音色ロード(bx:cx)
		int	int_drv

		add	cx,0x750
.play_start:
		mov	al,0x00			; ロード(bx:cx)
		int	int_drv

		mov	al,0x01			; 演奏開始
		int	int_drv

		jmp	short .ed

.tone_load
		mov	ax,[cs:loadseg]
		mov	ds,ax
		mov	dx,0x2400
		mov	cx,0x800
		mov	ah,0x3f			; [DOS] ファイルからの読み取り
		mov	bx,0x09			; 9番固定
		int	0x21			; 曲データロード
		jc	.tone_err

		mov	bx,ds
		mov	cx,dx
		mov	al,0x05			; 音色ロード(bx:cx)
		int	int_drv
		jmp	.tone_ok

.tone_err:
		mov	bx,ds

.tone_ok:
		mov	cx,0x400
		jmp	.play_start

loadseg:	dw	0			; ロードセグメント

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:

prgend:
		ends

