*
* The Return of Ishtar/FM77AV for hoot driver
*
	org	$8000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

* set vector
	ldx	#irqdummy
	stx	$FFF8
	stx	$FFF6

	jsr	$5000			* initialize

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	lda	SYSCOD2
	cmpa	#$FF
	beq	effect

	lda	#$FF
	jsr	$0009			* stop

	orcc	#$50			* FIRQ/IRQ disable
	lda	SYSCODE
	sta	SYSCODE			* file load
	andcc	#$ef			* IRQ enable

	ldx	#mustbl
	lda	SYSCOD2
	lsla
	ldy	a,x			* data ptr
	lda	#$FF
	jsr	$0000			* load

	bra	execend

effect
	ldx	#setbl
	lda	SYSCODE
	lsla
	ldy	a,x			* data ptr
	lda	#$04
	jsr	$0000			* load
	bra	execend

stop
	lda	#$FF
	jsr	$0009			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

irq
irqdummy
	rti

mustbl
	fdb	$1000
	fdb	$1280			* IBGM1:1 Opening
	fdb	$1178			* IBGM6:1 Name Entry
	fdb	$1004			* ISED:0 Miss
	fdb	$10f6			* ISED:1 GameOver
	fdb	$4108			* MAINGATE
	fdb	$421c			* MAINGATE
	fdb	$15A8			* MAIN:Round Clear
	fdb	$1284			* ISSD:Credit
	fdb	$11be			* IBGM5:Night2000

setbl
	fdb	$9096			* ISSD:0
	fdb	$90bd			* ISSD:1
	fdb	$90d9			* ISSD:2
	fdb	$90ec			* ISSD:3
	fdb	$90ec			* ISSD:4
	fdb	$9145			* ISSD:5
	fdb	$9160			* ISSD:6
	fdb	$918a			* ISSD:7
	fdb	$91ab			* ISSD:8
	fdb	$91d6			* ISSD:9
	fdb	$91f7			* ISSD:A
	fdb	$930d			* ISSD-11
	fdb	$9cac

	END
