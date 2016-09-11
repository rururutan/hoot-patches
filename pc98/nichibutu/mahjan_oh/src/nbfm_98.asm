; 日本物産 FM.SYS 演奏
; メインルーチン (for pc98dos)
;
; HOOTPORT + 2~4 : ファイルハンドル番号
;

%include 'hoot.inc'
int_hoot	equ	0x7F
int_driver	equ	0x15

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

		mov	ax, cs			; スタック設定
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	bx, 0x52		; FM
		call	sub_getdev

.redist:
		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
		mov	ax, 0x9801		; ダミーポーリング
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

.stop:
.fadeout:
		mov	ax, cmd_stop
		mov	bx, ax
		mov	dx, cs
		mov	ax, 0x03
		call	sub_output
		jmp	short .ed

.play:
		mov	dx, HOOTPORT + 4
		in	al, dx
		mov	[cmd_array], al

		mov	dx, HOOTPORT + 3
		in	al, dx
		mov	[cmd_array + 1], al

		mov	dx, HOOTPORT + 2
		in	al, dx
		mov	[cmd_array + 2], al

		mov	ax, cmd_array
		mov	bx, ax
		mov	dx, cs
		mov	ax, 0x03
		call	sub_output

		jmp	.ed

;
; 割り込みからdevice driverセグメント割り出し
; STRATEGYポインタの書き換え
;
; IN: bx = vector offset
;
sub_getdev:
		push	ax
		push	ds
		push	es

		mov	ax,0000
		mov	ds,ax
		mov	ax, [bx]
		mov	[cs:entseg],ax
		mov	[cs:srgseg],ax
		mov	ds, ax
		mov	ax, [0x08]		; Device interrupt code
		mov	[cs:entofs], ax
		mov	ax, [0x06]
		mov	[cs:srgofs], ax

		mov	bx, entry
		push	cs
		pop	es
		call	far	[cs:srgofs]

		pop	es
		pop	ds
		pop	ax
		ret

;
; device driverのoutput functionをシミュレート
;
; IN: ax = size
; IN: dx:bx = data
;
sub_output:
		mov	[entry_size], ax
		mov	[entry_addr_ofs], bx
		mov	[entry_addr_seg], dx

		push	es
		push	bx
		les	bx,	[entry]
		call	far	[cs:entofs]
		pop	bx
		pop	es
		ret

srgofs:
		dw	0x0000
srgseg:
		dw	0x0000

entofs:
		dw	0x0000
entseg:
		dw	0x0000

cmd_array:
		db	0x00, 0x00, 0x00

cmd_stop:
		db	0x01, 0x01, 0x50

;--RequestPackt Start---------------------
entry:
entry_packet:
		db	0x00
entry_unit:
		db	0x00
entry_func:
		db	0x08					; output
entry_status:
		dw	0x0000
entry_reserve:
		times 	0x08 db 0x00
entry_media:
		db	0x00
entry_addr_ofs:
		dw	0x0000
entry_addr_seg:
		dw	0x0000
entry_size:
		dw	0x0000
entry_sector:
		dw	0x0000
entry_volume:
		dw	0x0000,0x0000
entry_sector32:
		dw	0x0000,0x0000
;--RequestPackt End---------------------

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:

prgend:
		ends

