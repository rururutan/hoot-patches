*
* Dragon Buster/FM77AV for hoot driver
*
	ORG	$d000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
SYSCOD3	EQU	$0FD5B
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

	lda	#$01
	std	$FD93			* mmr off / bootram on

	lda	#$FF
	tfr	A,DP

	ldx	#$FF00			* clear bootram
clrlp
	clr	,X+
	cmpx	#$FFF0
	bcs	clrlp

	ldx	#$0000			* decode driver
neglp
	neg	,X+
	cmpx	#$D000
	bcs	neglp

	jsr	$79A6			* stop

	ldd	#$77F6
	std	$FFF8			* irq

	lda	#$04
	sta	$FD02			* irq mask

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
	jsr	$7A1B			* play
	bra	execend

stop
	jsr	$79A6			* stop

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
