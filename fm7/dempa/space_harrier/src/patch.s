*
* Space Harrier/FM77AV for hoot driver
*
	ORG	$1000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

* set vector
	ldx	#irqdummy
	stx	$FFF8
	stx	$FFF6

	jsr	$8400			* stop
	clr	$F80C
	clr	$F80D
	jsr	$8000

	ldd	#$012e
	jsr	$81E8

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

	jsr	$8400			* stop

	lda	SYSCODE
	sta	SYSCODE			* file load

	lda	SYSCOD2
	jsr	$847B

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$8400			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irq
irqdummy
	rti

	END
