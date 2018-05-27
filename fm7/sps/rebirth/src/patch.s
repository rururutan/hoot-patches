*
* ReBirth/FM-7 for hoot driver
*
	ORG	$4000

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

	ldx	#$0169
	stx	$FFF8

	jsr	$02BB			* init

	lda	$02B8
	bne	initend

	clr	$013E

initend
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

	lda	$013E			* psg/fm flag
	cmpa	$01
	bne	fm

	ldx	$6500
	jmp	play2

fm
	ldx	$6502

play2
	jsr	$0472			* play

played

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	orcc	#$50			* FIRQ/IRQ disable
	jsr	$0443			* stop
	andcc	#$ef			* IRQ enable

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

datah
	fcb	$65
datal
	fcb	$00

	END
