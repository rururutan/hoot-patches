; SS 演奏(diadrum)
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x07f
int_ss		equ	0x042

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
		pop	dx
		popa
		iret

.play:
		mov	ah,0x02		; 演奏停止
		int	int_ss

		mov	dx,filename
		mov	cx,0xffff
		mov	ah,0x3f		; read hundle
		xor	bx,bx		; 標準入力から
		int	0x21		; 曲データロード
		jc	.stop
		mov	bx,ax
		mov	[filename+bx], byte 0

		mov	si,ds		; data segment
		xor	di,dx		; data address
		mov	ah,0x01		; データロード(si:di)
		int	int_ss
		jmp	short .ed

.stop:
		mov	ah,0x02		; 演奏停止
		int	int_ss
		jmp	short .ed

.fadeout:
		mov	ah,0x03		; フェードアウト
		mov	dl,0x00
		mov	dh,0x30
		int	int_ss

		jmp	short .ed

filename:
		times 0x10 db 0x00	; ファイル名格納用バッファ

		ends

