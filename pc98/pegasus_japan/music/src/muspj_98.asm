; MUSIC.com Pegasus Japan Music Driver
; hoot演奏ルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x7e

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

		mov	ah, 0x48		; [DOS] OPNファイルバッファの割り当て
		mov	bx, 0x250
		int	0x21
		mov	[opnseg], ax

		mov	ah, 0x48		; [DOS] SSGファイルバッファの割り当て
		mov	bx, 0x100
		int	0x21
		mov	[ssgseg], ax

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x250		; パラグラフサイズ(64K)
		int	0x21
		mov	[loadseg],ax

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
		mov	ax,0x0002	; 演奏停止
		int	int_driver
		jmp	.ed

.fadeout:
		mov	bx,0x2EE0
		mov	al,0x0009	; フェードアウト
		int	int_driver
		jmp	.ed

.play:
		mov	ax,0x0002	; 演奏停止
		int	int_driver

		mov	bx,0x08		; OPNファイルのデフォルトハンドル番号:8
		mov	dx,HOOTPORT+3
		in	al,dx
		cmp	al,0x00		; 0でなければHOOTPORT+3をハンドル値にする
		jz	.opnload
		mov	bl,al
.opnload:
		mov	ax,[cs:opnseg]
		call	.fileload

		mov	bx,0x09		; SSGファイルのデフォルトハンドル番号:9
		mov	dx,HOOTPORT+4
		in	al,dx
		cmp	al,0x00		; 0でなければHOOTPORT+4をハンドル値にする
		jz	.ssgload
		mov	bl,al
.ssgload:
		mov	ax,[cs:ssgseg]
		call	.fileload

		mov	dx,HOOTPORT+2
		in	al,dx
		mov	bl,al
		mov	ax,[cs:loadseg]
		call	.fileload
		jc	.ed

		mov	ds,[cs:loadseg]
		xor	si,si
		mov	es,[cs:opnseg]
		xor	di,di
		mov	dx,[cs:ssgseg]
		xor	bx,bx
		mov	ax,0x0000	; バッファ設定
		int	int_driver

		mov	ax,0x0010	; Callback有効化
		mov	bl,0x94
		int	int_driver

		mov	ax,0x0007	; Timer開始
		int	int_driver

		mov	ax,0x0001	; 演奏開始
		int	int_driver

		jmp	.ed

; in: ax = buffer segment
; in: bx = handle number
.fileload:
		mov	ds,ax
		xor	dx,dx
		mov	cx,0xffff
		mov	ah,0x3f		; [DOS] read hundle
		int	0x21
		jc	.loadend
		mov	ax,0x4200	; [DOS] 先頭へシーク
		mov	cx,0x0000
		mov	dx,0x0000
		int	0x21
.loadend:
		ret


loadseg:	dw	0x0		; ロードセグメント
opnseg:		dw	0x0		; OPNセグメント
ssgseg:		dw	0x0		; SSGセグメント

prgend:
		ends

