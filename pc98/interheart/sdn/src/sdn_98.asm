; SDN.com
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	07fh
int_sdn		equ	050h

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
		mov	bx, 0x250
		int	0x21
		mov	[drvseg], ax

		push	ds
		mov	ds,[drvseg]
		mov	dx,0x100
		mov	cx,0xffff
		mov	ah,0x3f			; read hundle
		mov	bx,0x09			; ハンドル9番固定
		int	0x21			; プログラムロード
		pop	ds
		jc	resist

		call	far [drvofs]		; 初期化起動

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x400
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
		jz	short .fadeout
.ed:
		pop	es
		pop	ds
		popa
		iret

.play:
		mov	ah,0x05		; 演奏停止
		int	int_sdn

		mov	ax,[cs:loadseg]
		mov	ds,ax
		xor	dx,dx
		mov	cx,0xffff
		mov	ah,0x3f		; read hundle
		xor	bx,bx		; 標準入力から
		int	0x21		; 曲データロード
		jc	.ed

		mov	si,ds		; data segment
		mov	es,si
		xor	di,dx		; data address
		mov	ah,0x01		; データロード(ES:DI)
		mov	al,0x00
		int	int_sdn
		jmp	short .ed

.stop:
		mov	ah,0x05		; 演奏停止
		int	int_sdn

		jmp	short .ed

.fadeout:
		mov	cx,0x19
		mov	dl,0x00
		mov	dh,0x0f
		mov	ah,0x07		; フェードアウト
		int	int_sdn
		jmp	short .ed

loadseg:	dw	0		; ロードセグメント
drvofs:		dw	0x100
drvseg:		dw	0x0		; ドライバセグメント

		align	0x10
		times 0x100 db 0xff	; スタックエリア

stack:

prgend:
		ends

