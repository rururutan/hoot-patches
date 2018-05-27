*
* WorldGolf2/FM7 for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$08000

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

* set vector
	ldx	#$565A
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6

	ldd	#$0001
	jsr	$56D1

	lda	#$FD
	tfr	A,DP

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
	jsr	$56E5

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$573C
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
	lda	$FD03
irqdummy
	rti

	END
