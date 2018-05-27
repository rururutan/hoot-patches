*
* めぞん一刻 完結編/FM77AV for hoot driver
*
	ORG	$0000

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

	ldd	#$1B1B			* nop
	std	$2FC0
	std	$2FCB

	jsr	$1e2d			* irq init

	ldd	#$7000
	std	$27c4

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play

	jsr	$28b9			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	jsr	$2888			* play

played

	andcc	#$ef			* IRQ enable
	bra	loop

stop
	orcc	#$50			* FIRQ/IRQ disable
	jsr	$28b9			* stop
	andcc	#$ef			* IRQ enable

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
