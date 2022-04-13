; ASCII SDD_2/MUSE2/MUSE3/NMUSE.DRV 演奏
; (C) RuRuRu
; 2008/09/30 1st Release
;
; HOOTPORT + 2~3 : ファイルハンドル番号
; HOOTPORT + 5   : SE(01) / SOUND(00)
;

%include 'hoot.inc'
int_hoot	equ	0x7F
int_driver	equ	0xD2

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

		mov	ah, 0x48		; AH=48 alloc memory
		mov	bx, 0x1000
		int	0x21
		mov	[bufseg],ax

		cmp	byte [0x80],0x00	; コマンドラインがなんらか有れば
		jnz	.beep
		mov	bx, 0x52		; FM
		jmp	.getdev
.beep:
		mov	bx, 0x22		; Timer
.getdev:
		call	sub_getdev

		push	ds
		mov	ah, 0x3f		; AH=3F file read
		mov	bx, 0x08		; Tone file
		mov	cx, 0xffff
		lds	dx, [bufofs]
		int	0x21
		pop	ds
		jc	.se_load

		mov	bx, [bufofs]
		mov	dx, [bufseg]
		call	sub_output

.se_load:
		push	ds
		mov	ah, 0x3f		; AH=3F file read
		mov	bx, 0x09		; SE file
		mov	cx, 0xffff
		lds	dx, [bufofs]
		int	0x21
		pop	ds
		jc	.redist

		mov	bx, [bufofs]
		mov	dx, [bufseg]
		call	sub_output

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
		call	.sub_stop
		jmp	short .ed

.play:
		mov	dx, HOOTPORT + 5
		in	al, dx
		cmp	al, 0x01
		jz	.play_se

		; stop
		call	.sub_stop

		; wait

		push	ds
		mov	ah, 0x3f		; AH=3F file read
		xor	bx, bx
		mov	cx, 0xffff
		lds	dx, [bufofs]
		int	0x21
		pop	ds
		jc	.ed

		mov	bx, [bufofs]
		mov	dx, [bufseg]
		call	sub_output

		jmp	.ed

.play_se:
		mov	word [entry_size], 0x02
		mov	ax, se_cmd
		mov	[entry_addr_ofs], ax
		mov	[entry_addr_seg], cs

		mov	dx, HOOTPORT + 2
		in	al, dx
		mov	[se_cmd + 1], al

		les	bx,	[entry]
		call	far	[cs:entofs]
		jmp	.ed

.sub_stop:
		mov	word [entry_size], 0x02
		mov	ax, stop_cmd
		mov	[entry_addr_ofs], ax
		mov	[entry_addr_seg], cs

		les	bx,	[entry]
		call	far	[cs:entofs]
		ret

; 割り込みからdevice driverセグメント割り出し
; bx : vector offset
sub_getdev:
		push	ds
		mov	ax,0000
		mov	ds,ax
		mov	ax, [bx]
		mov	[cs:entseg],ax
		mov	ds, ax
		mov	ax, [0x08]		; Device interrupt code
		mov	[cs:entofs], ax
		mov	ax,entry		; RequestPacketのポインタを無理やり書き換え
		mov	[0x12],ax
		mov	[0x14],cs
		pop	ds
		ret


;
; device driverのoutput functionをシミュレート
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

entofs:
		dw	0x0000
entseg:
		dw	0x0000

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

stop_cmd:
		db	0x11,0x00

se_cmd:
		db	0x01,0x00

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

