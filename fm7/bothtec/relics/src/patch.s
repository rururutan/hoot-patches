*
* Relics/FM-7 for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

	lda	#$FD
	tfr	A,DP

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	cmpa	#$00
	bne	ending

	lda	#$02			* bug fix patch
	sta	$1A64
	lda	#$03
	sta	$1A57
	jsr	$1a54			* op play
	jmp	played

ending
	lda	SYSCOD2
	sta	$fc01			* fm/psg flag
	jsr	$0e31			* sound check
	jsr	$3b36			* ed play

played

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	orcc	#$50			* FIRQ/IRQ disable

	ldd	#$0028
	bsr	fmwrite
	ldd	#$0128
	bsr	fmwrite
	ldd	#$0228
	bsr	fmwrite
	ldd	#$7f4c
	bsr	fmwrite
	ldd	#$7f4d
	bsr	fmwrite
	ldd	#$7f4e
	bsr	fmwrite
	ldd	#$0027
	bsr	fmwrite

	ldd	#$0008
	bsr	fmwrite
	ldd	#$0009
	bsr	fmwrite
	ldd	#$000a
	bsr	fmwrite

*	andcc	#$ef			* IRQ enable

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

fmwrite
	pshs	a
	stb	$FD16
	lda	#$03
	sta	$FD15
	clr	$FD15
	puls	a
	sta	$FD16
	lda	#$02
	sta	$FD15
	clr	$FD15
	rts

	END
