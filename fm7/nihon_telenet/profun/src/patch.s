*
* ÉvÉçñÏãÖÉtÉ@Éì/FM77AV for hoot driver
*
	ORG	$1000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
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

	lda	#$F8
	tfr	a,dp

	jsr	$E168

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$B837			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCOD2
	sta	<$D0			* loop flag

	lda	SYSCODE
	sta	SYSCODE			* file load

	ldd	#$2000			* data ptr
	std	<$FA
	jsr	$B824			* play

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$B837			* stop
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
