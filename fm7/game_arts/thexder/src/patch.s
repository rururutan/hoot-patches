*
* Thexder/FM7 for hoot driver
*
	ORG	$4000

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

	lda	#$10
	tfr	a,dp

	lda	#$39			* rts patch
	sta	$1066

	jsr	$1304			* reg init
	jsr	$1039			* tone init

	ldx	#$1000			* save init.bin
	ldy	#$8000
	ldd	#$0800
	lbsr	memcpy

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

	bsr	play_stop

	lda	SYSCODE
	sta	SYSCODE			* file load

	cmpa	#$00
	beq	play0
	cmpa	#$01
	beq	play1
	bra	execend

play0
	clr	stopflg

	ldx	#$8000			* load init.bin
	ldy	#$1000
	ldd	#$0800
	lbsr	memcpy

	jsr	$1039			* tone init

	ldd	#$900F			* clear SSG-EG
ssgegclr
	pshs	b
	clrb
	jsr	$109A
	inca
	puls	b
	decb
	bne	ssgegclr

	jsr	$1B5B			* play

	andcc	#$ef			* IRQ enable
	bra	loop

play1
	lda	#$01
	sta	stopflg

	ldx	#$c000
	ldy	#$1cfb
	ldd	#$0400
	lbsr	memcpy

	jsr	$1AAF			* play

	andcc	#$ef			* IRQ enable
	bra	loop

play_stop
	lda	stopflg
	cmpa	#$00
	bne	play_stop2

	jsr	$1BE5			* stop
	rts

play_stop2
	cmpa	#$01
	bne	stop_end

	jsr	$1B20			* stop
stop_end
	rts

stop
	bsr	play_stop

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
	lda   $FD03
irqdummy
	rti

stopflg
	fcb	$02

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
