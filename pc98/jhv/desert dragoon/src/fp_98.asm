; fp.com 演奏
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x07f
int_driver	equ	0x088

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

;		mov	ax,cs			; スタック設定
;		mov	ss,ax
;		mov	sp,stack

;		mov	bx,prgend
;		add	bx,0x0f
;		shr	bx,4
;		mov	ah,0x4a			; [DOS] メモリブロックの縮小(ES:BX)
;		int	0x21

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
;		mov	ah,0x02			; 演奏停止
;		int	int_driver

		mov	dx,filename
		mov	cx,0xffff
		mov	ah,0x3f			; [DOS] ファイルからの読み取り
		xor	bx,bx			; 標準入力から
		int	0x21			; 曲名ロード
		jc	.stop
		mov	bx,ax
		mov	[filename+bx], byte 0

		mov	ah,0x20			; データロード(es:dx)
		mov	bx,ds
		mov	es,bx
		int	int_driver

		mov	ah,0x01			; 演奏開始
		int	int_driver

		jmp	short .ed

.stop:
		mov	ah,0x01			; 演奏停止
		int	int_driver
		jmp	short .ed

.fadeout:
		mov	ah,0x04			; フェードアウト
		mov	al,0x08			; フェード時間
		int	int_driver

		jmp	short .ed

filename:
		; ファイル名格納用バッファ
		times 0x10 db 0x00

;		align	0x10
;		times 0x100 db 0xff		; スタックエリア

;stack:

;prgend:
		ends

