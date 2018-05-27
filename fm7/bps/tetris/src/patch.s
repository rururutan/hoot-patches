*
* Tetris/FM7 for hoot driver
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
	ldx	#irq
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6
	ldx	#irqdummy
	stx	$FFFA

	lda	#$00			* Disable timer
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
	lda	#$FF
	sta	$5000

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	jsr	$5005			* play

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	lda	#$FF
	sta	$5000
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
irqdummy
	rti

	END
