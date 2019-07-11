*
* DDS/FM77AV for hoot driver
*
	ORG	$2000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
STACK	EQU	$0FC7E

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

	lda	#$FD
	tfr	a,dp
	jsr	$F2B1			* sound init

	lda	#$F8
	tfr	a,dp

	lda	#$C0
	sta	<$08			* ????

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$E1AE			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCOD2
	sta	$F8C0			* loop flag

	lda	SYSCODE
	sta	SYSCODE			* file load

	ldd	#$0100			* data ptr
	std	$F8F8
	jsr	$E19B			* play
	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$E1AE			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irq
irqend
irqdummy
	rti

	END
