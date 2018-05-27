*
* うる星やつら/FM77AV for hoot driver
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

	lda	#$F0
	tfr	A,DP

	ldx	#$F3C6
	stx	$FFF8

	ldx	#$7000
	jsr	$F018			* init

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play

	jsr	$F021			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

*	jsr	$F01B			* play
	jsr	$F01E			* play

played

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	orcc	#$50			* FIRQ/IRQ disable
	jsr	$F021			* stop
	andcc	#$ef			* IRQ enable

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
