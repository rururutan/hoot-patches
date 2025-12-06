; bplay.com for hoot
; (C) RuRuRu
; 2025/03/20 1st Release
;
; hoot 2025/12版以降で動作
;
%include 'hoot.inc'
int_hoot	equ	0x07f
int_driver	equ	0x0ED

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

		mov	ax,0x2518
		mov	dx,int18cb
		int	0x21

		mov	ax,0x257f		; hootドライバ登録
		mov	dx,vect_hoot
		int	0x21

		mov	ax,0x02fa		; Mode setting
		int	int_driver

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
		mov	ah,0x13			; Stop
		int	int_driver

		mov	ah,0x06			; Clear buffer
		int	int_driver

		xor	bx,bx			; 標準入力
		mov	ah,0x3f			; [DOS] read hundle (DS:DX)
		push	cs
		pop	ds
		mov	dx,filename
		mov	cx,12			; 8+3, 拡張子込み
		int	0x21
		jc	.ed

		mov	bx,filename
		mov	ah,0x07			; ファイルロード(ES:BX)
		int	int_driver
		jc	.ed

		mov	ax,0x0a01		; Play start
		int	int_driver

		jmp	short .ed

.stop:
.fadeout:
		mov	ah,0x13			; Stop
		int	int_driver
		mov	al, 0x08
		out	0x35, al		; Beep disable
		jmp	short .ed

int18cb:
		pushf
		pusha
		cmp ah, 0x17
		jnz chk18

		mov dx, 0x35
		in al, dx
		and al, 0xf7
		out dx, al
		jp int18end

chk18:
		cmp ah, 0x18
		jnz int18end

		mov dx, 0x35
		in al, dx
		or al, 0x08
		out dx, al

int18end:
		popa
		popf
		iret

filename:	times 0x18 db 0x00	; ファイル名格納用バッファ
		db	0x00, 0x24

		times 0x100 db 0xff		; スタックエリア
		align	0x10
stack:

prgend:
