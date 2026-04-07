*
* Topple Zip/FM-7(FM) for hoot driver
*
	ORG	$8000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
SYSCOD3	EQU	$0FD5B
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

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
	lda	SYSCODE
	sta	SYSCODE			* file load

	clra
	jsr	$4542			* play
	bra	execend

stop
	jsr	$45D7			* stop

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
