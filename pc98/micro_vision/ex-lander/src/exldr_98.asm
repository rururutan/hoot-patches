; Ex-Lander (C)Micro Vision (Based on RANMA.ASM by UME-3)
; (C) RuRuRu
; 2022/09/28 1st Release

%include 'hoot.inc'

NEARENTRY	EQU	0x0e00		; near call呼び出し用配置アドレス

		ORG	0x0100
		USE16
		CPU	186

start:		cli
		cld
		mov	sp,stack
		mov	bx,prgend
		shr	bx,4
		mov	ah,0x4a		; [DOS] メモリブロックの縮小(ES:BX)
		int	0x21
		jnc	.skip1
		hlt
.skip1:		mov	bx,0x1000	; 大きさ適当
		mov	ah,0x48		; [DOS] メモリ割り当て
		int	0x21
		jnc	.skip2
		hlt
.skip2:		mov	[paramblk],ax	; 割り当てアドレスを保存
		mov	[paramblk+2],ax
		mov	[nearfar+2],ax
		add	ax,0x0700
		mov	[dataseg],ax
		mov	ax,0x4b03	; [DOS] Overlay Load
		mov	dx,exec_path	; パス名 (DS:DX)
		mov	bx,paramblk	; パラメータブロック(ES:BX)
		int	0x21
		jnc	.skip3
		hlt
.skip3:		mov	si,nearcall	; near callルーチンを転送
		mov	es,[nearfar+2]
		mov	di,NEARENTRY
		mov	cx,nearentrysize
		rep	movsb

		mov	ds,[dataseg]
		mov	ax,0x03e9	; 各種データロードと初期化
		call	nearexec

hoot_regist:	push	cs
		pop	ds
		mov	ax,0x257f	; hootドライバ登録
		mov	dx,vect_7f
		int	0x21
		sti
mainloop:	mov	ax,0x9801	; ダミーポーリング
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

vect_7f:	pusha
		push	ds
		push	es
		mov	ds,[cs:dataseg]
		mov	dx,HOOTPORT
		in	al,dx
		cmp	al,HP_PLAY
		jz	short .play
		cmp	al,HP_STOP
		jz	short .stop
.ed:		pop	es
		pop	ds
		popa
		iret

.play:		mov	dx,HOOTPORT+2
		in	ax,dx
		inc	ax
		jz	.effect
		mov	ax,0x4d77		; 演奏停止
		call	nearexec

		xor	bx,bx			; 標準入力
		mov	dx,0x1a74		; 曲データオフセット
		mov	cx,0xffff		; 曲データサイズ
		mov	ah,0x3f			; 曲データロード
		int	0x21
		jc	.ed
		mov	ax,0x4d6a		; 演奏開始
		call	nearexec
		jmp	short .ed

.stop:		mov	ax,0x4d77		; 演奏停止
		call	nearexec
		jmp	short .ed

.effect:	mov	dx,HOOTPORT+4
		in	al,dx			; 効果音番号取得
		mov	[0x1be9],al		; 効果音演奏
		jmp	short .ed

; near call呼び出しルーチン
nearexec:	call	far [cs:nearfar]	; near callで呼び出し
		ret

; near callルーチン
nearcall:	call	ax
		retf
nearentrysize:	equ	$ - nearcall

; オーバレイロード用パス
exec_path:	db	'OPENING.EXE',00

; far call用エントリ
nearfar:	dw	NEARENTRY
		dw	0

dataseg:	dw	0			; データセグメントオフセット

; オーバレイロード用パラメータブロック
paramblk:	dw	0			; ロードセグメント
		dw	0			; リロケーションファクタ

		times 0x200 db 0x00		; スタックエリア
stack:

		align	0x10
prgend:		

		ends

