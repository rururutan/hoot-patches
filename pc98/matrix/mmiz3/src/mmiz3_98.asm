
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
	STACK_SIZE		equ		256



;code cseg

	ORG	0x0100
	USE16
	CPU	186

main:
	cli

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

	mov ds, [cs:buf_seg]
	xor dx, dx
	mov cx, -1
	mov bx, 0x09
	mov ah, 3fh
	int 21h

	mov ah, 0x02
	mov dx, [cs:buf_seg]
	int 40h


	xor ax, ax
	int 40h

	mov dx, [cs:buf_seg]
	mov ax, 0100h
	int 40h


	mov dx, cs
	mov ds, dx
	mov dx, hootfunc
	mov ax, (2500h + HOOT_VECTOR)
	int 21h

	mov dx, HOOTFUNC
	mov al, HF_ENABLE
	out dx, al

	sti

main_loop:
	mov	ax,0x9801
	int	0x18
	jmp main_loop


hootfunc:
	pusha
	push ds
	push es

	mov dx, HOOTFUNC
	mov al, HF_DISABLE
	out dx, al

	mov dx, HOOTPORT
	in al, dx

	cmp al, HP_PLAY
	jne hootfunc_stop

hootfunc_play:

	mov ax, 0700h
	int 40h

	mov ax, 0600h
	int 40h

	mov ax, 0600h
	int 40h

	mov ds, [cs:buf_seg]
	xor dx, dx
	mov cx, -1
	xor bx, bx
	mov ah, 3fh
	int 21h

	mov ax, 0501h
	int 40h

	jmp hootfunc_end

hootfunc_stop:
	cmp al, HP_STOP
	jne hootfunc_end

	mov ax, 0600h
	int 40h

hootfunc_end:
	mov dx, HOOTFUNC
	mov al, HF_ENABLE
	out dx, al

	pop es
	pop ds
	popa
	iret

buf_seg:
	dw 0

	align	0x10
	times STACK_SIZE db 0xff		; スタックエリア
stack_end:

prg_end:

	end
