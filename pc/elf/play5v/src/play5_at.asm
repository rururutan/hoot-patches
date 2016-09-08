; PLAY5V.COM ââëtÉãÅ[É`Éì (for pcatdos)
;
	.186


	HOOTPORT		equ		07e0h
	HP_PLAY			equ		00h
	HP_LOADPLAY		equ		01h
	HP_STOP			equ		02h

	HOOTFUNC		equ		07e8h
	HF_DISABLE		equ		80h
	HF_ENABLE		equ		81h
	HF_NORMAL		equ		82h
	HF_BURST		equ		83h

; ---- pc98generic only

	HOOTCTRL		equ		07d0h
	HC_SETADDR		equ		10h
	HC_GETADDR		equ		11h
	HC_LOADBGM		equ		20h
	HC_LOADBGM2		equ		21h



	HOOT_VECTOR		equ		7fh
	STACK_SIZE		equ		1024

code cseg

	rs 100h

main:
	cli

	mov dx, HOOTFUNC
	mov al, HF_DISABLE
	out dx, al

	mov bx, prg_end
	add bx, 0fh
	shr bx, 4
	mov ah, 4ah
	int 21h

	mov ax, cs
	mov ss, ax
	mov sp, stack_end

	mov bx, 1000h
	mov ah, 48h
	int 21h
	mov cs:[buf_seg], ax

	mov dx, cs
	mov ds, dx
	mov dx, hootfunc
	mov ax, (2500h + HOOT_VECTOR)
	int 21h

	mov dx, HOOTFUNC
	mov al, HF_ENABLE
	out dx, al

	sti
_main_loop:
	hlt
	jmp _main_loop




hootfunc:
	pusha
	push ds
	push es

	mov dx, HOOTPORT
	in al, dx

	cmp al, HP_PLAY
	jne _hootfunc_stop

_hootfunc_play:
	mov al, 03h
	int 0d0h

	mov ds, cs:[buf_seg]
	xor dx, dx
	mov cx, -1
	xor bx, bx
	mov ah, 3fh
	int 21h

	mov cx, ax
	mov es, cs:[buf_seg]
	xor bx, bx
	mov al, 00
	int 0d0h

	jmp _hootfunc_end

_hootfunc_stop:
	cmp al, HP_STOP
	jne _hootfunc_end

	mov al, 03h
	int 0d0h

_hootfunc_end:
	pop es
	pop ds
	popa
	iret



	even

buf_seg: dw 0

	even

	rs STACK_SIZE
stack_end:

prg_end:

	end
