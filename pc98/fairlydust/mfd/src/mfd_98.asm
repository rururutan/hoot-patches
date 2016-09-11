; MFD.EX 用
; メインルーチン (for NASM)

%include 'hoot.inc'

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	sp,stack

		mov	ax,0x257f	; hootドライバ登録
		mov	dx,vect_7f
		int	0x21
		sti

		mov	ax,0x01		; 初期化
		xor	bx,bx
		int	0x42

mainloop:
		mov	ax, 0x9801		; ダミーポーリング
		int	0x18


; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

vect_7f:	pusha
		push	ds
		push	es
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	dx,HOOTPORT
		in	al,dx
		cmp	al,HP_PLAY
		jz	short play
		cmp	al,HP_STOP
		jz	short fadeout
ed:		pop	es
		pop	ds
		popa
		iret

play:
		call	stop_music	; 演奏停止

		mov	ax,0x01		; 初期化
		xor	bx,bx
		int	0x42

		mov	ah,0x3f		; [DOS] read hundle
		xor	bx,bx		; 標準入力
		mov	cx,0x100	; 曲データ最大サイズ(適当)
		mov	dx,buff
		int	0x21		; 曲データロード
		jc	.stop

		mov	dx,HOOTPORT+4
		in	al,dx
		xor	bx,bx
		mov	bl,al		; FM(2)/MIDI(1)
		mov	ax,0x01		; 再生デバイス選択
		int	0x42

		mov	cx,buff
		mov	dx,cs
		mov	bx,0x01		; Play
		mov	ax,0x03		; 曲データ登録(DX:CX)
		int	0x42

		jnc	short ed

.stop:
fadeout:
		call	stop_music	; 演奏停止
		jmp	short ed

stop_music:
		mov	ax,005h
		xor	bx,bx
		int	0x42
		ret

vwait:
		mov	cx,0x10
wait_lp:
		mov	dx,0x60
		mov	ah,0x20
.wait1
		in	al,dx
		test	ah,al
		jz	.wait1
.wait2
		in	al,dx
		test	ah,al
		jnz	.wait2
		loop	wait_lp
		ret

flg_play:
		db	00

		times 0x100 db 0x00	; スタックエリア
stack:
		align	0x10
buff:					; 以下、ロードバッファ
		ends

