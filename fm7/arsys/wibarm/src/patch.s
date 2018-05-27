*
* Wibarm/FM77AV for hoot driver
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
	ldx	#$07BA
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6

	lda	#$F3
	tfr	A,DP

	bsr	chkfm

	lda	#$05
	sta	$FD02
	jsr	$0932

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$0932

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	lda	SYSCOD2
	jsr	$0D00			* play

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	jsr	$0932
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irq
irqdummy
	rti

chkfm
	lda	#$FF
	sta	$1A25			; FM flag
	lda	#$02
	sta	$FD15
	clr	$FD16
	deca
	sta	$FD15
	lda	$FD16
	cmpa	#$FF
	bne	fmen
	clr	$1A25			; FM flag
	rts
fmen
	ldd	#$2D00
	jsr	$08B1			; Sound Write
	inca
	jsr	$08B1			; Sound Write
	rts

	END
