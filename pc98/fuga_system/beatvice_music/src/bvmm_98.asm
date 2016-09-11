; OPNDRV.EXE (C)風雅システム 用
; メインルーチン (for NASM)

%include 'hoot.inc'
int_hoot	equ	0x7F
int_driver	equ	0xd2

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

		mov	dx, HOOTFUNC
		mov	al, HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx, al

		xor	ax,ax		; 初期化
		int	int_driver

		mov	cx,0x1000	; 曲データバッファ確保
		mov	ax,0x0005
		int	int_driver

		mov	[buff_seg],ax	; 結果を保存
		mov	[buff_size],cx

		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
		mov	ax, 0x9801	; ダミーポーリング
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
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	dx, HOOTPORT
		in	al, dx
		cmp	al, HP_PLAY
		jz	short .play
		cmp	al, HP_STOP
		jz	short .fadeout
.ed:
		pop	es
		pop	ds
		popa
		iret

.play:
		mov	ax,0x03
		mov	cl,0x04
		int	int_driver

.chk_status:
		mov	ax,0x04
		int	int_driver
		cmp	al, 0x00
		jnz	.chk_status

		mov	ax,0x4200
		xor	cx,cx
		mov	dx,0x04		; 先頭4byte読み飛ばし
		xor	bx,bx		; 標準入力
		int	0x21

		mov	cx,[buff_size]	; バッファサイズ
		mov	ds,[buff_seg]	; バッファセグメント
		shl	cx,4		; バイト単位に変換
		xor	dx,dx		; データオフセット
		xor	bx,bx		; 標準入力
		mov	ah,0x3f		; 曲データ本体のロード(DS:DX)
		cli
		int	0x21
		jc	.stop

		mov	dx,HOOTPORT+4	; 曲番号を読み込む
		in	al,dx
		mov	cl,al
		inc	dx
		in	al,dx		; ループ有無
		mov	dl,al
		mov	ax,0x01		; 演奏開始
		int	int_driver
		jmp	short .ed

.stop:
		mov	ax,0x02		; 演奏停止
		int	int_driver
		jmp	short .ed

.fadeout:
		mov	ax,0x03		; フェードアウト
		mov	cl,0x08		; フェードアウト速度
		int	int_driver
		jmp	short .ed

buff_seg:	dw	0000		; バッファセグメント
buff_size:	dw	0000		; バッファサイズ

		ends

