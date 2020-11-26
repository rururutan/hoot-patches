*
* 九玉伝/FM77AV
*
	ORG	$5000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
SYSCOD3	EQU	$0FD5B
SYSCOD4	EQU	$0FD5C
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

	lda	#$FD
	tfr	A,DP

	LDA   #$80
	STA   $FD93			; MMR on

*	ldd	#$0307			* op
*	ldd	#$02F0			* main bgm
*	ldd	#$030C
*	std	$9A9C			* timer value

	ldx	#$3372
	stx	$FFF8

*	jsr	$7d4e			* timer enable

	andcc	#$ef			* IRQ enable

	jsr	$04FA			* stop

loop
	lda	fplay
	cmpa	#$01
	bne	chkstat

	lda	$9A94			* play stat
	bne	chkstat

	lda	#$01
	jsr	$0463

chkstat
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	lda	SYSCOD3
	cmpa	#$00
	beq	play_bgm
	cmpa	#$01
	beq	play_se1
	cmpa	#$02
	beq	play_se2

play_bgm
	jsr	$04FA			* stop

	lda	SYSCOD4
	ldy	#tempotbl
	lsla				* x2
	ldx	A,Y
	stx	$9A9C			* timer value
	jsr	$7d4e			* timer enable

	orcc	#$50			* FIRQ/IRQ disable
	lda	SYSCODE
	sta	SYSCODE			* file load

	lda	SYSCOD2
	jsr	$0463			* play
	andcc	#$ef			* IRQ enable

	lda	#$01
	sta	fplay

	bra	loop

play_se1
	lda	SYSCODE
	jsr	$0234			* s.e
	bra	execend

play_se2
	lda	SYSCODE
	jsr	$0255			* s.e
	bra	execend


stop
	clra
	sta	fplay
	jsr	$04FA			* stop
	bra	execend

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

fplay
	fcb	$00

tempotbl
	fdb	$0307
	fdb	$02f0
	fdb	$030c

	END
