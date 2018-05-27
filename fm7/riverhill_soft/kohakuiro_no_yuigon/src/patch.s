*
* 琥珀色の遺言/FM77AV for hoot driver
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

	jsr	$2C12			* set vector

*	ldx	#irq
*	stx	$FFF8

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$3D81

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	jsr	$3DB6			* load

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$3D81
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irq
irqdummy
	rti

	END
