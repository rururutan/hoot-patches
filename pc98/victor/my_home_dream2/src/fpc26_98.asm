; FPC26.COM 用
; メインルーチン (for NASM)
; UME-3氏作iwaplayのソースを改変させてもらいました。

%include 'hoot.inc'

		ORG	0x0100
		USE16
		CPU	186

start:		cli
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	sp,stack

		mov	ah,0x08
		int	0xeb

		mov	bx,0x05		; 初期音色データ登録
		call	voiceset

		mov	ax,0x257f	; hootドライバ登録
		mov	dx,vect_7f
		int	0x21

		sti
mainloop:	hlt
		hlt
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

.play:
		call	stop_music	; 演奏停止
		mov	ah,0x3f		; [DOS] read hundle
		mov	dx,HOOTPORT+4	; 音色データ番号指定を読み込む
		in	al,dx
		or	al,al
		jz	.musload	; 指定されていなければ音色ロードをスキップ

.voiceload:	push	ax
		mov	ax,0x0aff	; 既存の音色データを全て削除
		int	0xeb
		pop	ax
		mov	bl,al		; hundle指定とする
		xor	bh,bh
		mov	dx,buff
		mov	cx,0x8000	; 音色データ最大サイズ(適当)
		int	0x21		; 音色データロード
		jc	.stop
		call	rewind		; ファイルポインタを戻す
		jc	.stop
		mov	cx,cs
		mov	dx,buff		; 音色データ連続登録(CX:DX)
		mov	ah,0x09
		int	0xeb

.musload:
		mov	ax,0x06ff	; 登録済み曲データを全て削除
		int	0xeb
		mov	ah,0x3f		; [DOS] read hundle
		xor	bx,bx		; 標準入力
		mov	cx,0x8000	; 曲データ最大サイズ(適当)
		mov	dx,buff
		int	0x21		; 曲データロード
		jc	.stop

		mov	cx,cs
		mov	dx,buff
		mov	ah,0x01		; 曲データ登録(CX:DX)
		int	0xeb

		mov	dx,HOOTPORT+5	; BGM/SE種別を読み込む
		in	al,dx
		or	al,0x7f		; ミュートボリュームを合成
		mov	dl,al
		mov	al,[buff+2]	; 曲ID
		mov	ah,0x02		; 演奏開始
		int	0xeb
		jnc	short .ed

.stop:		call	stop_music	; 異常時は演奏停止して戻る
		jmp	short .ed

.fadeout:
		mov	ax,0308h	; フェードアウト(AL=速度)
		int	0xeb
		jmp	short .ed

stop_music:
		mov	ax,0x03ff	; 演奏停止(その1)
		int	0xeb
		mov	ax,0x0301	; 演奏停止(その2)
		int	0xeb
		mov	ah,0x08
		int	0xeb
		ret

; 音色設定 BX=ファイルハンドル
voiceset:	mov	ah,0x3f		; [DOS] read hundle
		mov	cx,0x8000	; 音色データ最大サイズ(適当)
		mov	dx,buff
		int	0x21		; 音色データロード
		jc	return		; エラーなら無視する
		push	bx
		mov	cx,cs
		mov	dx,buff
		mov	ah,0x09		; 音色データセット(CX:DX)
		int	0xeb
		pop	bx

rewind:		push	ax		; ファイルポインタ(BX)を先頭に戻す
		push	cx
		push	dx
		mov	ax,0x4200	; [DOS] move file pointer
		xor	cx,cx
		mov	dx,cx
		int	0x21
		pop	dx
		pop	cx
		pop	ax
return:		ret

		times 0x100 db 0x00	; スタックエリア
stack:
		align	0x10
buff:					; 以下、ロードバッファ
		ends

