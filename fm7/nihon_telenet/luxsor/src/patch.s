*
* Luxsor/FM77AV for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
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

	lda	#$FF
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
	lbsr	$E076			* stop

	orcc	#$50			* FIRQ/IRQ disable
	lda	SYSCODE
	sta	SYSCODE			* file load

	ldd	#$1000			* data ptr
	std	$E079

*	lda	#$01
*	sta	$E07B

	lbsr	$E073			* play
	andcc	#$ef			* IRQ enable
	bra	execend

stop
	lbsr	$E076			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irq
	pshs	DP,A,B
	ldb	$FD03
	bitb	#$08
	bne	irqend
	lbsr	$EDC1
irqend
	puls	B,A,DP
irqdummy
	rti

	END
