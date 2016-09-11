;
; 雀ボーグすずめ
;

%include 'hoot.inc'

	ORG		0
	USE16
	CPU		186

	HOOT_VECTOR		equ		7fh
	STACK_SIZE		equ		0x200

start:
	cli
	cld

	mov dx, HOOTFUNC
	mov al, HF_DISABLE
	out dx, al

	xor ax, ax
	mov ss, ax
	mov sp, 0x1000

	xor		ax, ax
	mov		ds, ax

	; hoot ドライバ登録～
	mov word [HOOT_VECTOR * 4], hootfunc
	mov [(HOOT_VECTOR * 4) + 2], cs

	mov word [0x71*4], vect_71
	mov [0x71*4+2], cs

	; Patch
	mov	ax, 0x400
	mov	ds, ax
	mov	byte [0xb2], 0xcb		; RETF

	call	0x0400:0x000e		; 0400:0000

	; メイン
	sti
.idle:
	mov	ax,0x9801
	int	0x18
	jmp		short .idle

; Magical-DOS Dummy API
vect_71:
	iret


; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98VX::Play  ロード前
; inp8(HOOTPORT) = 1 → PC98VX::Play  ロード後
; inp8(HOOTPORT) = 2 → PC98VX::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)
hootfunc:
	sti
	pusha
	push ds
	push es

	mov	dx, HOOTPORT
	in	al, dx

	cmp	al, 0
	je	short .stop
	cmp	al, 1
	je	short .play
	cmp	al, 2
	je	short .stop
.ed:
	pop es
	pop ds
	popa
	iret

.play:
	mov	ax, 0x1000
	mov	ds, ax
	mov	ax, 0x0000
	mov	si, ax
	mov	ax, 0x0400	; Load(DS:SI)
	int	0x80

	xor	ax, ax		; Play
	int	0x80
	jmp	short .ed

.stop:
	mov	ax, 0300
	int	0x80
	jmp	short .ed

	ends

