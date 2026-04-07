*
* Topple Zip/FM-7(PSG) for hoot driver
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

	jsr	$49a3			* initialize

	andcc	#$ef			* IRQ enable

LDA   #$08
JSR   $40CA

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
	jsr	$450C			* play
	bra	execend

stop
	jsr	$457F			* stop

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
