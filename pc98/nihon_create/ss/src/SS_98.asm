; 日本クリエイト SS.COM 演奏(3x3eyes/魔京伝/Super野球道2)
; メインルーチン (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x07f
int_driver		equ	0x041

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
		pop	ds
		popa
		iret

.play:
		mov	dx,HOOTPORT+2	; 曲番号指定を読み込む
		in	al,dx

		cmp	al,0xff		; 曲番号が0xffの場合はSSG-PCM設定
		jz	.ssgpcm

		cmp	al,0xfe		; 曲番号が0xfeの場合は曲ループを抜ける
		jz	.loopend

		mov	ah,0x02		; 演奏停止
		int	int_driver

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
		int	int_driver
		jmp	short .ed

.stop:
		mov	ah,0x02		; 演奏停止
		int	int_driver
		jmp	short .ed

.fadeout:
		mov	ah,0x03		; フェードアウト
		mov	dl,0x00
		mov	dh,0x30
		int	int_driver

		jmp	short .ed

.ssgpcm:
		mov	al,[pcmflg]
		mov	ah,0x05		; SSG-PCM設定
		int	int_driver
		inc	byte [pcmflg]
		and	byte [pcmflg],0x01

		jmp	short .ed

.loopend:
		mov	al,0x01
		mov	ah,0x0c		; 曲ループ設定
		int	int_driver

		jmp	short .ed


pcmflg:
		db	1

filename:
		times 0x10 db 0x00	; ファイル名格納用バッファ

		ends

