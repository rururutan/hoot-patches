*
* Asteka2/FM7 for hoot driver
*
	ORG	$2000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

* set vector
	ldx	#irq
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6

	lbsr	chkfm

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
	lbsr	mute
	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	cmpa	#$00
	beq	play0
	cmpa	#$01
	beq	play1
	cmpa	#$02
	beq	play2
	bra	execend

play0
	ldx	#$A1C9
	stx	$FFF8
	lda	fmflag
	sta	$A1C6
	lda	SYSCOD2
	sta	$7EEC
	jsr	$A3AF
	bra	execend

play1
	ldx	#$8000
	ldy	#$C000
	ldd	#$1000
	lbsr	memcpy

	lda	fmflag
	sta	$C4E9
	lda	SYSCOD2
	sta	$C4EA
	jsr	$C67A
	bra	execend


play2
	ldx	#$8000
	ldy	#$0100
	ldd	#$0700
	lbsr	memcpy

	lda	#$04
	sta	$FD02
	ldx	#$06FA
	stx	$FFF8
	lda	fmflag
	sta	$01F3
	lda	SYSCOD2
	sta	$06F8
	jsr	$0855
	bra	execend

execend
	andcc	#$ef			* IRQ enable
	lbra	loop

stop
	orcc	#$50			* FIRQ/IRQ disable
	bsr	mute
	lda	#$ff
	sta	SYSCODE
	lbra	loop

mute
	lda	fmflag
	cmpa	#$00
	beq	mutepsg
	ldd	#$2800
	lbsr	fmw
	ldd	#$2801
	lbsr	fmw
	ldd	#$2802
	lbsr	fmw
	rts
mutepsg
	ldd	#$07BF
	lbsr	psgw
	rts

irq
	lda	$FD03
irqdummy
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

fmw
	pshs	a,b,x
	ldx	#$FD15
	bra	devw
psgw
	pshs	a,b,x
	ldx	#$FD0D
devw
	sta	1,x
	lda	#$03
	sta	,x
	clr	,x
	stb	1,x
	deca
	sta	,x
	clr	,x
	puls	a,b,x
	rts

chkfm
	clr	fmflag
	lda	#$02
	sta	$FD15
	clr	$FD16
	deca
	sta	$FD15
	lda	$FD16
	cmpa	#$FF
	bne	fmen
	rts
fmen
	com	fmflag
	rts

fmflag
	fcb     $00

	END
