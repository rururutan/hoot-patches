*
* Arcus/FM77AV for hoot driver
*
	ORG	$4000

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

	lbsr	$1FC4			* init

*	ldx	#irqmain
*	stx	$2000

	lbsr	$2128			* stop

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

	lda	SYSCODE
	sta	SYSCODE			* file load

	andcc	#$ef			* IRQ enable

	cmpa	#$00
	bne	play_main

* IPLはプログラム中でテンポ書き換えてる
	lda	#$D8
	sta	$9616

play_main
	lda	SYSCOD2
	sta	$1FB7			* loop flag

	lbsr	$210B			* play

	ldd   #$2D00
	jsr   $201C			* FM Write
	ldd   #$2E00
	jsr   $201C			* FM Write

	bra	loop

stop
	lbsr	$2128			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irqmain
*	jsr	$2232
*	jsr	$2232
*	andcc	#$ef			* IRQ enable
*	rts

	END
