*
* PSY-O-BLADE/FM7 for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

* set vector
	ldx	#irq
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6

	lda	#$f0
	tfr	a,dp

	jsr	$E5F0			* init

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$E7A1			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	ldx	#$3000
	jsr	$E61F			* play

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$E7A1			* stop
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
	lda	$FD03
	bita	#$08
	bne	irqdummy
	jsr	$E7FD
irqdummy
	rti

	END
