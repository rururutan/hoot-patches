*
* Daiva/FM7 for hoot driver
*
	ORG	$5000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	ldu	#$0000
	lds	#STACK

* set vector
	ldx	#irq
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6
	ldx	#irqdummy
	stx	$FFFA

	lda	#$FD
	tfr	A,DP

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	lbeq	stop
	bra	loop

play
	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	cmpa	#$00
	beq	play0
	cmpa	#$01
	beq	play1
	cmpa	#$02
	beq	play2
	cmpa	#$03
	beq	play3
	lbra	execend

play0
	ldx	#stop
	ldd	#$2C61
	std	1,x

	jsr	$1BBD			* set ire
	jsr	$2B68			* init
	jsr	$2BCD			* play
	lbra	execend

play1
	ldx	#$0000
	ldy	#$e000
	ldd	#$0800
	lbsr	memcpy

	ldx	#irq
	stx	$FFF8
	ldx	#irqfm
	ldd	#$E009
	std	1,x
	ldx	#stop
	ldd	#$E003
	std	1,x

	jsr	$E006			* init

	ldb	SYSCOD2
	jsr	$E000			* start
	bra	execend

play2
	ldx	#$0000
	ldy	#$e000
	ldd	#$0800
	lbsr	memcpy

	jsr	$E0BE			* init

	ldx	#irq
	stx	$FFF8
	ldx	#irqfm
	ldd	#$E0AE
	std	1,x
	ldx	#stop
	ldd	#$E17E
	std	1,x

	ldb	SYSCOD2
	stb	$E000			* code address
	jsr	$E11D			* start
	bra	execend

play3
	ldx	#irq
	stx	$FFF8
	ldx	#irqfm
	ldd	#$0CC9
	std	1,x
	ldx	#stop
	ldd	#$0D90
	std	1,x

	jsr	$0CD9			* init
	jsr	$0D36			* start
	bra	execend

stop
	jsr	$2C61			* stop
	lda	#$ff
	sta	SYSCODE
	lbra	loop

execend
	andcc	#$ef			* IRQ enable
	lbra	loop

irq
	lda	$FD03
	bita	#$08
	beq	irqfm
irqdummy
	rti
irqfm
	jsr	$E009
	rti

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

	END

