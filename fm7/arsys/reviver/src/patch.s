*
* Reviver/FM77AV for hoot driver
*
	ORG	$4000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	ldu	#$E800
	lds	#STACK

* set vector
	ldx	#$0F0A
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6

	bsr	chkfm

	lda	#$04
	sta	$FD02			* timer enable

	jsr	$1220			* init

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$1220			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	jsr	$126A			* play

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	jsr	$1220			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irq
	pshs	DP,A
	LDA	$FD03
	puls	A,DP
irqdummy
	rti

chkfm
	clr	$FC00
	lda	#$02
	sta	$FD15
	clr	$FD16
	deca
	sta	$FD15
	lda	$FD16
	cmpa	#$FF
	bne	fmen

	ldx	#$FD0D
	stx	$FC06			* FM address
	rts
fmen
	lda	#$FF
	sta	$FC00			* FM flag
	ldx	#$FD15
	stx	$FC06			* FM address

	lda	#$2E
	jsr	$11AD

	rts

	END
