; Lord of Wars (vbeep.drv) ���t
; ���C�����[�`�� (for pc98dos)

%include 'hoot.inc'
int_hoot	equ	0x07f
int_driver		equ	0x043

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax,cs
		mov	ds,ax
		mov	es,ax

		mov	dx,HOOTFUNC
		mov	al,HF_DISABLE		; ����������hoot�Ăяo�����֎~
		out	dx,al

		mov	ax, cs			; �X�^�b�N�ݒ�
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	ah, 0x48		; AH=48 alloc memory
		mov	bx, 0x1000		; AllocSize (paragraph)
		int	0x21
		mov	[bufseg],ax

		push	ds
		mov	ah, 0x3f		; AH=3F file read
		mov	bx, 0x10		; File handle
		mov	cx, 0xffff		; Read size (byte)
		lds	dx, [bufofs]
		int	0x21
		pop	ds

		mov	ax,0x257f		; hoot�h���C�o�o�^
		mov	dx,vect_hoot
		int	0x21

		mov	dx,HOOTFUNC
		mov	al,HF_ENABLE		; hoot�Ăяo��������
		out	dx,al
		sti

mainloop:
		nop
;		mov	ax,0x9801		; �_�~�[�|�[�����O
;		int	0x18
		jmp	short mainloop

; hoot����R�[�������
; inp8(HOOTPORT) = 0 �� PC98DOS::Play
; inp8(HOOTPORT) = 2 �� PC98DOS::Stop
; _code = inp8(HOOTPORT+2)�`inp8(HOOTPORT+5)

vect_hoot:
		pusha
		push	ds
		push	es
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	dx,HOOTPORT
		in	al,dx
		cmp	al,HP_PLAY
		jz	short .play
		cmp	al,HP_STOP
		jz	short .fadeout
.ed:		pop	es
		pop	dx
		popa
		iret

.play:
		mov	dx, HOOTPORT + 2	; �Đ��Ȕԍ�
		in	al, dx
.play_code:
		les	bx, [bufofs]
		sub	ah, ah
		mov	bx, 0x0a		; Table 1 Size
		mul	bx
		mov	bx, 0xcfe		; Table Pointer
		add	bx, ax
		mov	ah,0xff			; �f�[�^���[�h(es:bx)
		int	int_driver

		jmp	short .ed

.stop:
.fadeout:
		mov	al,0x13
		jmp	short .play_code

bufofs:
		dw	0x0000
bufseg:
		dw	0x0000

		align	0x10
		times 0x100 db 0xff		; �X�^�b�N�G���A

stack:

prgend:
		ends
