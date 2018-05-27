*
* ぎゃんぶらぁ自己中心派/FM7 for hoot driver
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

	lda	#$04
	sta	$FD02

	lda	#$80
	sta	$0614
	jsr	$C000			* bgm #0 register init
	clr	$0614

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

	lda	#$80
	sta	$0614			* enable

	jsr	$C006			* stop

	lda	SYSCODE
	clr	SYSCODE			* file load

	cmpa	#$00
	beq	play0
	cmpa	#$01
	beq	play1
	cmpa	#$02
	beq	play2
	bra	playend

play0
	lda	#$7e			* jmp
	sta	$C114
	ldx	#$C0E6			* $c0e6
	stx	$C115			* デモ曲に移行するのを防ぐ

	lda	#$09
	sta	$C01D			* tempo

	jsr	$C000			* bgm #0
	bra	playend

play1
	lda	#$bd			* jsr
	sta	$C114
	ldx	#$C242			* $c0e6
	stx	$C115			* 復帰

	jsr	$C00a			* bgm #1
	bra	playend

play2
	lda	#$7e			* jmp
	sta	$C114
	ldx	#$C0E6			* $c0e6
	stx	$C115			* デモ曲に移行するのを防ぐ

	jsr	$C010			* bgm #2

playend
	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$C006			* stop
	clr	$0614			* disable
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
	lda	$FD03
	bita	#$04
	bne	irqdummy

	pshs	cc
	orcc	#$50
	jsr	$C003
	andcc	#$ef			* IRQ enable
	puls	cc

irqdummy
	rti

	END
