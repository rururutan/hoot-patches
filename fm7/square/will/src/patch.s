*
* Will/FM7 for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$07FF0

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	ldu	#$F200
	lds	#STACK

	lda	#$FD
	tfr	A,DP

	lda	#$57
	sta	$0257
	lda	#$21
	sta	$0212
	lda	#$6C
	sta	$026c

* set vector
	lda	#$7E			* jmp
	sta	$01DD
	ldx	#$666D
	stx	$01DE

	ldx	#$01DD
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6

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

	jsr	$6600			* init

	andcc	#$ef			* IRQ enable
	bra	execend

stop
	lda	#$01
	sta	$2FFA			* enable flag
	ldd	#$073F
	jsr	$6532			* psg write
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irqdummy
	rti

	END
