*
* Ultima IV/FM77AV for hoot driver
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

	lda	#$00
	tfr	A,DP

	lda	#$39
	sta	$01BE			* rts patch

	lda	#$FF
	sta	$00CD			* Enable Flag

	lda	$FD16
	cmpa	#$FF
	bne	init2

	lda	#$01			* PSG
	sta	$006F			* PSG / FM Flag

	jsr	$0662			* init


init2
	jsr	$0121			* init

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play

	lda	#$00
	jsr	$0139			* play

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	lda	#$01
	jsr	$0139			* play

played

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	orcc	#$50			* FIRQ/IRQ disable
	lda	#$00
	jsr	$0139			* play
	andcc	#$ef			* IRQ enable

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
