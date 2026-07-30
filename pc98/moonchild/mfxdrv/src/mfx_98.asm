; MFXDDN.COM演奏
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0xd2

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	dx, ds
		mov	[execparam+8],ax		; entry更新
		mov	[execparam+12],ax		; entry更新
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	[execparam+4],ax		; entry更新

		mov	dx, HOOTFUNC
		mov	al, HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx, al

		mov	ax, cs			; スタック設定
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x2000		; パラグラフサイズ
		int	0x21
		mov	[bufseg],ax

		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
		mov	al, [flg_exec]
		cmp	al,01
		jz	mip_play
		cmp	al,02
		jz	mip_stop
		jmp	short mainloop

mip_play:
		mov	al, 0xff
		mov	[flg_exec],al

		mov	ax, filename
		mov	[execparam+2],ax	; "file name"
		call	mip_load
		jmp	short mainloop

mip_stop
		mov	al, 0xff
		mov	[flg_exec],al

		mov	ax, stop_param
		mov	[execparam+2],ax	; /s
		call	mip_load
		jmp	short mainloop


; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)〜inp8(HOOTPORT+5)

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
	
.stop:
.fadeout:
		mov	al, 0x02
		mov	[flg_exec],al
		jmp	short .ed

.play:
		mov	dx,filename1
		mov	cx,0xffff
		mov	ah,0x3f			; [DOS] ファイルからの読み取り
		xor	bx,bx			; 標準入力から
		int	0x21			; 曲名ロード
		jc	.stop
		mov	bx,ax
		mov	[filename1+bx], byte 0

		mov	al, 1
		mov	[flg_exec],al

		jmp	.ed

; Exec MIP.EXE
mip_load:
		pusha
		push	ds
		push	es
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ax, 0x4b00		; [DOS] Co-Process
		mov	dx, exec_path		; パス名 (DS:DX)
		mov	bx, execparam		; パラメータブロック(ES:BX)
		int	0x21
		jc	exec_err
		mov	ah, 0x4d
		int	0x21
exec_err:
		pop	es
		pop	ds
		popa
		ret

flg_exec:
		db	0xff

exec_path:
	db	'MIP.EXE',00

stop_param:
	db	' /s',00

filename:
	db	' '
filename1:
		; ファイル名格納用バッファ
		times 0x10 db 0x00

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

; Exec load用パラメータブロック
execparam:
		dw	0			; Env Segment
		dw	0x80			; Command Line
		dw	0
		dw	0x5c			; Default FCB
		dw	0
		dw	0x6c			; Default FCB
		dw	0

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
		ends

