; The Magic Candle
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0xd2

		org	0x0100
		use16
		cpu	186

start:
		cli
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

		mov	dx, HOOTFUNC
		mov	al, HF_DISABLE	; Disable hoot call
		out	dx, al

		mov	ax, cs			; Stack
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	ah, 0x00		; Get buffer(ES:BX)
		int	int_driver
		mov [bufofs], bx
		mov [bufseg], es

		mov	ah, 0x25		; Register hoot driver
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE	; Enable hoot call
		out	dx, al
		sti

mainloop:
;		mov	ax, 0x9801		; Polling
;		int	0x18
		jmp	short mainloop

; hoot port
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
		mov	ah, 0x03
		int	int_driver
		jmp	short .ed

.play:
		mov	dx, HOOTPORT+3			; Sound code(15~8bit)
		in	al, dx
		cmp	al, 0x00
		jnz	.play_se

		mov	dx, [cs:bufofs]
		mov	ds, [cs:bufseg]
		xor	bx,bx					; stdin
		mov	cx,0xffff				; size
		mov	ah,0x3f					; Load data (DS:DX)
		int	0x21

		mov	ah, 0x01
		int	int_driver
		jmp	.ed

.play_se:
		mov	dx,HOOTPORT+2			; Sound code(7~0bit)
		in	al,dx
		mov	ah, 0x05
		int	int_driver
		jmp	.ed

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

		align	0x10
		times 0x100 db 0xff		; Stack
stack:
prgend:

