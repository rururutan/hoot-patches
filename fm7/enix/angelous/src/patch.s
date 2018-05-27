*
* Angelous/FM77AV for hoot driver
*
	ORG	$4000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
SYSCOD3	EQU	$0FD5B
STACK	EQU	$0F000

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

	lda	#$FD
	tfr	A,DP

	ldd	#$01AE
	std	$FFF8			* irq

	lda	#$FF
	sta	$2B18			* music on

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$2c03			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	ldb	SYSCOD2
	lda	SYSCOD3
	std	datadr

	ldx	#$8000
	ldy	datadr
	ldd	#$0500
	lbsr	memcpy

	andcc	#$ef			* IRQ enable

	ldu	datadr
	jsr	$2c00			* play
	bra	loop

stop
	jsr	$2c03			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

memcpy
	ldu	,x++
	stu	,y++
	decb
	bne	memcpy
	cmpa	#00
	beq	mcpend
	deca
	bra	memcpy
mcpend
	rts

datadr
	fdb     $dc00

	END
