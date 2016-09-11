; Microcabin Music Driver 「あけみちゃん」(MMD2.SYS/MMD.SYS)用
; メインルーチン (for NASM)

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

		mov	ax,0x257f		; hootドライバ登録
		mov	dx,vect_7f
		int	0x21

		xor	ax,ax			; ドライバ初期化
		int	0x48
		mov	[musbuf_size],cx	; バッファサイズを保存

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot呼び出しを許可
		out	dx,al

		sti
mainloop:	hlt
		hlt
		hlt
		hlt
		jmp	short mainloop

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
		jz	short .play
		cmp	al,HP_STOP
		jz	short .fadeout
.ed:		pop	es
		pop	ds
		popa
		iret

.play:		mov	dx,HOOTPORT+3	; 曲番号指定を読み込む
		in	al,dx
		mov	ah,al
		dec	dx
		in	al,dx		; 曲番号が0xffffの場合はループ抜け出し
		inc	ax
		jz	.sync
		mov	ah,0x03		; 演奏停止
		int	0x48
		cli
		mov	ah,0x3f		; [DOS] read hundle
		mov	dx,HOOTPORT+4	; 音色データ番号指定を読み込む
		in	al,dx
		or	al,al
		jz	.musload	; 指定されていなければ音色ロードをスキップ
		mov	bl,al		; hundle指定とする
		xor	bh,bh
		mov	dx,buff
		mov	cx,0x0c00	; 音色データ最大サイズ
		int	0x21		; 音色データロード
		jc	.stop
		call	rewind		; ファイルポインタを戻す
		jc	.stop
		mov	dx,ds
		mov	bx,buff
		mov	cx,ax		; 音色データの実際のサイズ
		mov	ah,0x11
		int	0x48		; 音色データセット

.musload:	mov	ah,0x3f		; [DOS] read hundle
		xor	bx,bx		; 標準入力
		mov	cx,[musbuf_size]
		mov	dx,buff
		int	0x21		; 曲データロード
		jc	.stop

		mov	dx,ds
		mov	bx,buff
		mov	cx,ax		; 曲データの実際のサイズ
		mov	ah,0x10		; 曲データセット
		int	0x48

		mov	ah,0x01
		int	0x48		; 演奏開始
		jmp	short .ed

.sync:		mov	ax,0x0a01	; ループ抜け出し
		int	0x48
		jmp	short .ed

.stop:		mov	ah,0x03		; 演奏停止
		int	0x48
		jmp	short .ed

.fadeout:	mov	ax,0x0608	; フェードアウト
		int	0x48
		jmp	short .ed

; ファイルポインタ(BX)を先頭に戻す
;
rewind:		push	ax
		push	cx
		push	dx
		mov	ax,0x4200	; [DOS] move file pointer
		xor	cx,cx
		mov	dx,cx
		int	0x21
		pop	dx
		pop	cx
		pop	ax
		ret

musbuf_size:	dw	0		; 曲データバッファサイズ

buff:					; データロード用バッファ

		ends

