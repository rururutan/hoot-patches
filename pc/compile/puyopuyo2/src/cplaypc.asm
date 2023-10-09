; ぷよぷよ(PC/AT) SPLAY

%include 'hoot.inc'

		ORG	0x0100
		USE16
		CPU	186

start:		cli
		mov	ax,cs
		mov	ds,ax
		mov	es,ax

		mov	dx,HOOTFUNC
		mov	al,HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx,al

		mov	ax,0x257d		; hootドライバ登録
		mov	dx,vect_7d
		int	0x21

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al

		sti
mainloop:
		hlt
		hlt
		hlt
;		mov	ax,0x9801		; ダミーポーリング
;		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

vect_7d:	pusha
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
;		mov	ax,0x0300	; 演奏停止
;		int	0x7f

		cld			; ファイル名バッファのクリア
		mov	cx,0x50/2
		mov	di,filename
		xor	ax,ax
		rep	stosw

		mov	ah,0x3f		; [DOS] read hundle
		xor	bx,bx		; 標準入力
		mov	dx,filename
		mov	cx,0x50-1	; ファイル名の長さ
		int	0x21
		jc	.stop

		mov	dx,filename	; ファイル名の指定
		mov	ah,0x09
		int	0x7f		; 曲データロード

		mov	dx,HOOTPORT+4	; ファイル指定を読み込む
		in	al,dx		; 曲番号指定を読み込む
		xor	ah,ah
		int	0x7f		; 演奏開始
		jmp	short .ed

.stop:
		mov	ax,0x0300	; 演奏停止
		int	0x7f
		jmp	short .ed

.fadeout:	mov	ax,0x0410	; フェードアウト
		int	0x7f
		jmp	short .ed

filename:	times 0x50 db 0x00	; ファイル名格納用バッファ

buff:					; データロード用バッファ

		ends

