; Super上海 SNDDRV.EXE MIDI演奏
;
; @autor RuRuRu
; @date 2026/09/16 1st Release


%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x41

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
		call	init_sysex


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

; Send SYSEX.STD for MT-32 tone setting
init_sysex:
		push	ds
		mov	ah, 0x3f
		mov	bx, 0x0009
		mov	cx, 0xffff
		lds	dx, [bufofs]
		int	0x21
		pop	ds
		jc	.short_done

		les	bx, [bufofs]
		mov	ah, 0x80
		int	int_driver
		cmp	al, 0x01
		je	short .short_done
		xor	al, al			; Do not loop
		mov	ah, 0x81
		int	int_driver
.short_done:
		ret
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
		mov	ah, 0x82		; Stop
		int	int_driver
		jmp	short .ed

.play:

		mov	ah, 0x82		; Stop
		int	int_driver

		push	ds
		mov	ah, 0x3f		; AH=3F file read
		xor	bx, bx
		mov	cx, 0xffff
		lds	dx, [bufofs]
		int	0x21
		pop	ds
		jc	.ed

		les	bx, [bufofs]
		mov	ah, 0x80		; load(es:bx)
		int	int_driver

		mov	dx, HOOTPORT+4
		in	al, dx			; loop
		mov	ah, 0x081		; play
		int	int_driver

		jmp	.ed

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:

prgend:
		ends

