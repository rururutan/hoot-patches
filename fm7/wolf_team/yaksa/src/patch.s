*
* YAKSA/FM77AV for hoot driver
*
	ORG	$5000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

	lda	#$FD
	tfr	A,DP

	lda	#$39
	sta	$9B8B			* RTS patch (palette)

	jsr	$A871			* IRQ init
	jsr	$A6D0			* stop

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	jsr	$A6D0			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	lda	SYSCOD2
	cmpa	#01
	beq	op_drv

* game driver
	jsr	$3274			* init

	ldx	#$7A00
	stx	$3270			* stop

	jsr	$30F1			* play
	bra	play_main

op_drv
	jsr	$A871			* init

	ldx	#$7A00
	stx	$96BD

	jsr	$A6D0			* stop
	jsr	$A69B			* play


play_main
	andcc	#$ef			* IRQ enable
	bra	loop

stop
	jsr	$A6D0			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
