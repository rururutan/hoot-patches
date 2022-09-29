; SIMANT ANTMUS.COM
; (C) RuRuRu
; 2022/09/26 1st Release

%include 'hoot.inc'
int_hoot	equ	07fh
int_drv		equ	050h

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

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

mainloop:	mov	ax,0x9801		; ダミーポーリング
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

vect_hoot:	pusha
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

.ed:		pop	es
		pop	dx
		popa
		iret

.play:
;		mov	ah,0x02		; 演奏停止
;		int	int_drv

		mov	ax,[cs:loadseg]
		mov	ds,ax
		xor	dx,dx
		mov	cx,0xffff
		mov	ah,0x3f		; read hundle
		xor	bx,bx		; 標準入力から
		int	0x21		; 曲データロード
		jc	.ed

		mov	ax,ds
		mov	dx,ax		; Data segment
		xor	si,si		; Data address
		mov	cx,0x960	; Data length
		mov	ah,0x01		; データロード
		int	int_drv

		mov	al,0x01		; 演奏
		mov	ah,0x02		; 状態変更
		int	int_drv
		jmp	short .ed

.stop:
.fadeout:
		xor	al,al		; 停止
		mov	ah,0x02		; 状態変更
		int	int_drv
		jmp	short .ed

loadseg:	dw	0		; ロードセグメント

		align	0x10
		times 0x100 db 0xff	; スタックエリア

stack:

prgend:
		ends

