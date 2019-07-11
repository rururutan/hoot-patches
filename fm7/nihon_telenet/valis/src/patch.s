*
* Valis/FM7 for hoot driver
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

	lda	#$05
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
	ldb	#$ff
	lbsr	$E000			* stop

	orcc	#$50			* FIRQ/IRQ disable
	lda	SYSCODE
	sta	SYSCODE			* file load

	ldx	#$c000			* data ptr
	ldb	SYSCOD2			* loop
	lbsr	$E000			* play
	andcc	#$ef			* IRQ enable
	bra	execend

stop
	ldb	#$ff
	lbsr	$E000			* stop
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
	pshs	DP,X,A,B
	lda	$FD03
	ldx	#$0E04
	tst	$002,X
	beq	irqend
	lbsr	$E722
irqend
	puls	B,A,X,DP
irqdummy
	rti

	END
