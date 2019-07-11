*
* Albatross/FM7 for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	ldu	#$0000
	lds	#STACK

* set vector
	ldx	#$87CA
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6
	ldx	#$F819
	stx	$FFFA

	ldx	#$2000
	jsr	$F000			* init
	jsr	$F002			* stop

	lda	#$04
	sta	$FD02

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

	jsr	$F002			* stop

	lda	SYSCODE
	sta	SYSCODE			* file load

*	lbsr	$9435
*	lbsr	$943E
*	lbsr	$9447

	jsr	$F004			* play

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$F002
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
	pshs	DP,X,A,B
	lda	$FD03
irqend
	puls	B,A,X,DP
irqdummy
	rti

chkfm
	clr	$FC02			* PSG/FM flag
	lda	#$02
	sta	$FD15
	clr	$FD16
	deca
	sta	$FD15
	lda	$FD16
	cmpa	#$FF
	bne	fmen
	com	$FC02
fmen
	com	$FC02
	rts


	END
