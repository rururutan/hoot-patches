; mmd.com for PM2AT
; メインルーチン (for pcatdos)

%include 'hoot.inc'
int_hoot	equ	0x07f
int_driver	equ	0x061

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

		mov	ah,0x48			; [DOS] ドライババッファの割り当て
		mov	bx,0x280
		int	0x21
		mov	[drvseg], ax

		push	ds
		mov	ds,[drvseg]
		mov	dx,0x100		; offset 100h
		mov	bx,0x09			; ハンドル9番固定
		mov	cx,0xffff		; データサイズ
		mov	ah,0x3f			; [DOS] read hundle
		int	0x21			; プログラムロード
		pop	ds
		jc	resist

		push	ds
		mov	ds,[drvseg]
		mov	bx, word [0x102]
		mov	[drvofs],bx

		mov	ax,0x00
		mov	[0x10a],ax
		call	far [cs:drvofs]		; 初期化起動

		pop	ds

resist:
		mov	ah,0x25			; hootドライバ登録
		mov	al,int_hoot
		mov	dx,vect_hoot
		int	0x21

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al
		sti

mainloop:
		mov	ax,0x9801
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
		mov	ah,0x01			; 演奏停止
		int	int_driver

		mov	ah,0x06			; 曲データバッファアドレスを取得(DS:DX)
		int	int_driver
		xor	bx,bx			; 標準入力
		mov	cx,0xffff		; データサイズ
		mov	ah,0x3f			; [DOS] read hundle
		int	0x21
		jc	.stop

		xor	ah,ah			; 演奏開始
		int	int_driver
		jmp	short .ed

.stop:
		mov	ah,0x01			; 演奏停止
		int	int_driver

		jmp	short .ed

.fadeout:
		mov	ax,0x0208		; フェードアウト
		int	int_driver
		jmp	short .ed

drvofs:		dw	0x011D
drvseg:		dw	0x0000			; ドライバセグメント
patchmsg:
		db	0x0D,0x0A,'PM2 for hoot driver ver 1.0 by RuRuRu',0x0D,0x0A,'$'
errormsg:
		db	0x0D,0x0A,'error!',0x0D,0x0A,'$'

		align	0x10
		times 0x100 db 0xff
stack:

prgend:
		ends

