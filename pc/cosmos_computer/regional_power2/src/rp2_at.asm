; MUSIC.EXE 演奏
; メインルーチン (for pcatdos)
; BaseはSilverHirame氏のmagic_98

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x61

		ORG	0x0100
		USE16
		CPU	186

start:
	cli
	mov	ax, cs
	mov	ds, ax
	mov	es, ax

	mov dx, HOOTFUNC
	mov al, HF_DISABLE
	out dx, al

	mov ax, cs
	mov ss, ax
	mov sp, stack_end

	mov bx, prg_end
	add bx, 0fh
	shr bx, 4
	mov ah, 4ah
	int 21h

	mov bx, 1000h
	mov ah, 48h
	int 21h
	mov [cs:buf_seg], ax

	xor cx, cx
	mov ax, 0
	call int_m

	mov	ah, 0x25
	mov	al, int_hoot
	mov	dx, hootfunc
	int	0x21

	mov dx, HOOTFUNC
	mov al, HF_ENABLE
	out dx, al

	sti

_main_loop:
	mov	ax, 0x9801		; ダミーポーリング
	int	0x18
	jmp _main_loop



int_m:
	int int_driver
	ret



hootfunc:
	sti

	push es
	push ds
	pusha

	mov dx, HOOTPORT
	in al, dx

	cmp al, HP_PLAY
	jne _hootfunc_stop

_hootfunc_play:
	mov ax, 4
	call int_m

	mov dx, (HOOTPORT+2)
	in ax, dx
	or ah, ah
	jz _hootfunc_play_7

	push ax

	xor bx, bx
	mov bl, ah

	xor dx, dx
	xor cx, cx
	mov ax, 4200h
	int 21h

	mov ax, [cs:buf_seg]
	mov es, ax
	mov ds, ax
	xor dx, dx
	mov cx, -1
	mov ah, 3fh
	int 21h

	mov cx, dx
	mov ax, 3
	call int_m

	pop ax

_hootfunc_play_7:
	xor bx, bx
	mov bl, al

	xor dx, dx
	xor cx, cx
	mov ax, 4200h
	int 21h

	mov ax, [cs:buf_seg]
	mov es, ax
	add ax, 4
	mov ds, ax
	xor dx, dx
	mov cx, -1
	mov ah, 3fh
	int 21h

	xor si, si
	xor di, di
	call xxx

	mov dx, ax
	mov cx, di
	mov ax, 5
	call int_m
	jmp _hootfunc_end

_hootfunc_stop:
	cmp al, HP_STOP
	jne _hootfunc_end

	mov ax, 4
	call int_m

_hootfunc_end:
	popa
	pop ds
	pop es
	iret


; in
;  ds:si data
;  es:di table
; out
;  ax  part num
;
xxx:
	push cx
	push bx
	push si
	push di

	lea bx, [si+0eh]
	lodsw
	push ax
	mov cx, ax
_xxx_2:
	mov ax, bx
	stosw
	mov ax, ds
	stosw
	lodsw
	add bx, ax
	mov ax, bx
	stosw
	mov ax, ds
	stosw
	loop _xxx_2
	pop ax

	pop di
	pop si
	pop bx
	pop cx
	ret

	even

buf_seg: dw 0

	times 0x100 db 0xff
stack_end:

prg_end:
	ends
