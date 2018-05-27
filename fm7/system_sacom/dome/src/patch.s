*
* DOME/FM-7 for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

	lda	#$FD
	tfr	A,DP

	jsr	$3ced			* init

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
	sta	SYSCODE			* file load

	ldy	#$964C
	jsr	$2989			* play

played

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	orcc	#$50			* FIRQ/IRQ disable
	lda	#$fd
	jsr	$2A17			* fadeout
	andcc	#$ef			* IRQ enable

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
