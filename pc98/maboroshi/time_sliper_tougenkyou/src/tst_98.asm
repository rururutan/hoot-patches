; Maboroshi Ware - Timeslip Tougenkyou FM.SYS
;
; HOOTPORT + 2~3 : ファイルハンドル番号
; HOOTPORT + 4   : 曲番号
;

%include 'hoot.inc'
int_hoot	equ	0x7F

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

		push	ds
		mov	ax,0000			; FM割り込みからdevice driverセグメント割り出し
		mov	ds,ax
		mov	ax, [0x52]
		mov	[cs:entseg],ax
		mov	ds, ax
		mov	ax, [0x08]
		mov	[cs:entofs], ax
		mov	ax,entry		; RequestPacketのポインタを無理やり書き換え
		mov	[0x44],ax
		mov	[0x46],cs
		pop	ds

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
		jmp	short .ed

.fadeout:
		mov	byte [sound_code],01
		mov	byte [play_flag],0x50
		mov	word [entry_size], 0x03
		mov	ax, sound_cmd
		mov	[entry_addr_ofs], ax
		mov	[entry_addr_seg], cs

		les	bx,	[entry]
		call	far	[cs:entofs]
		jmp	short .ed

.play:
		mov	dx, HOOTPORT+2
		in	al, dx			; Song No
		mov	[sound_code],al

		mov	word [entry_size], 0x03
		mov	byte [play_flag],0x01
		mov	ax, sound_cmd
		mov	[entry_addr_ofs], ax
		mov	[entry_addr_seg], cs

		les	bx,	[entry]
		call	far	[cs:entofs]

		jmp	.ed

entofs:
		dw	0x0000
entseg:
		dw	0x0000

sound_cmd:
		db	0x01
sound_code:
		db	0x00
play_flag:
		db	0x01

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
		end

