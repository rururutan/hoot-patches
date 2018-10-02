*
* Laydock/FM7 for hoot driver
*
	ORG	$0000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5a
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	ldu	#$0000
	lds	#STACK

* set vector
	ldx	#irq
	stx	$FFF8
	ldx	#irqdummy
	stx	$FFF6
	ldx	#irqdummy
	stx	$FFFA

	lda	#$FD
	tfr	A,DP

	jsr	$348A			* init
	jsr	$34F2			* set vector

*	ldx	#$5EDA
*	ldd	#$3D96
*	std	,X++
*	ldd	#$3E05
*	std	,X++
*	ldd	#$3E58
*	std	,X
*	jsr	$2DF2
*	jsr	$2E55
*	lda	#$FF
*	sta	$5E6F			* enable

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
	cmpa	#01
	beq	play_se

	jsr	$2DB8			* stop

	orcc	#$50			* FIRQ/IRQ disable

	lda	SYSCODE
	sta	SYSCODE			* file load

	ldx	#$5EDA			* sound work
	ldb	#$06
	ldu	#mustbl
	mul
	leau	b,u
	ldd	,u++
	std	,x++
	ldd	,u++
	std	,x++
	ldd	,u
	std	,x

	jsr	$2DF2
	jsr	$2E55
	lda	#$FF
	sta	$5E6F			* enable

	andcc	#$ef			* IRQ enable
	bra	execend

play_se
	orcc	#$50			* FIRQ/IRQ disable
	ldu	#$5EA4			* se work
	lda	SYSCODE
	ldx	#setbl
	lsla
	ldx	a,x
	jsr	$2F18			* se req
	andcc	#$ef			* IRQ enable
	bra	execend

stop
	jsr	$2DB8			* stop
	bra	execend

execend
	lda	#$ff
	sta	SYSCODE
	bra	loop

irq
	lda	$FD03
irqdummy
	rti

mustbl
	fdb	$4000,$406F,$40C2
	fdb	$4000,$4072,$40B6	* 3F6F/3FE1/4025
	fdb	$4000,$403E,$4066	* 40C1/40FF/4127
	fdb	$4000,$4048,$4179
	fdb	$4000,$405c,$40CF
	fdb	$4000,$4061,$40a6
	fdb	$4000,$4031,$4058
	fdb	$4000,$403E,$407D
	fdb	$4000,$4045,$41CF
	fdb	$4000,$4073,$417C

setbl
	fdb	$3CE9			* se data ptr (hit)
	fdb	$3CBE			* se data ptr (laser)
	fdb	$3CFE			* se data ptr (???)
	fdb	$3D09			* se data ptr (bomb2)
	fdb	$3D40			* se data ptr (???)
	fdb	$3D4A			* se data ptr (bomb)
	fdb	$3D89			* se data ptr (hit2)

	END
