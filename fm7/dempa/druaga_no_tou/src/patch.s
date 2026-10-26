*
* The Tower of Druaga/FM77AV for hoot driver
*

* hoot I/O Port
SYSCALL			EQU	$0FD58
SYSCODE			EQU	$0FD59
SYSCOD2			EQU	$0FD5A
SYSCOD3			EQU	$0FD5B
STACK			EQU	$0FC80

FM_UPDATE		EQU	$4500
FM_WRITE		EQU	$4671
FM_REQUEST		EQU	$16B7
FM_CODE			EQU	$16B8
GAME_WAIT		EQU	$1F41
FM_WORK			EQU	$1DB0
FM_WORK_END		EQU	$1DE0
PSG_TABLE		EQU	$47D8
PSG_WAIT		EQU	$EFFD
PSG_POINTER		EQU	$EFFE
PSG_POINTER_LO		EQU	$EFFF

TICK_SOURCE		EQU	$BB43
TICK_SOURCE_END		EQU	$BB8E
WRITE_SOURCE		EQU	$4818
WRITE_SOURCE_END	EQU	$483A

PSG_UPDATE		EQU	$A400
PSG_RETURN		EQU	$A44A
PSG_WRITE		EQU	$A500

PSG_COUNTER		EQU	$A300
FM_INTERVAL		EQU	$A301
FM_COUNTER		EQU	$A302

	ORG	$A000

init
	orcc	#$50
	lds	#STACK
	ldx	#TICK_SOURCE
	ldu	#PSG_UPDATE

copy_tick
	lda	,x+
	sta	,u+
	cmpx	#TICK_SOURCE_END
	bne	copy_tick
	lda	#$39		*Change from RTI to RTS
	sta	PSG_RETURN
	ldx	#WRITE_SOURCE
	ldu	#PSG_WRITE

copy_write
	lda	,x+
	sta	,u+
	cmpx	#WRITE_SOURCE_END
	bne	copy_write
	lda	#$16
	tfr	a,dp
	ldx	#irq
	stx	$FFF8
	ldx	#dummy
	stx	$FFF6
	jsr	silence
	lda	#4
	sta	$FD02
	andcc	#$EF

loop
	lda	SYSCALL
	cmpa	#1
	beq	play
	cmpa	#2
	beq	stop
	bra	loop

*00-0A=FM,80-8D=PSG SE
play
	orcc	#$50
	lda	SYSCODE
	cmpa	#$80
	bhs	psg
	cmpa	#11
	bhs	ack
	jsr	silence
	lda	SYSCODE
	sta	FM_CODE
	cmpa	#4
	blo	normal
	cmpa	#8
	bhs	normal
	lda	GAME_WAIT
	suba	#$FF
	sta	FM_INTERVAL
	sta	FM_COUNTER

normal
	lda	#1
	sta	FM_REQUEST
	jsr	FM_UPDATE
	bra	ack

psg
	suba	#$80
	cmpa	#14
	bhs	ack
	ldb	#2
	mul
	ldx	#PSG_TABLE
	leax	d,x
	ldd	,x++
	std	PSG_POINTER
	clr	PSG_WAIT
	bra	ack

stop
	orcc	#$50
	jsr	silence

ack
	lda	#$FF
	sta	SYSCODE
	andcc	#$EF
	bra	loop

silence
	ldx	#FM_WORK

clear
	clr	,x+
	cmpx	#FM_WORK_END
	bne	clear
	clr	FM_REQUEST
	clr	PSG_WAIT
	clr	PSG_POINTER
	clr	PSG_POINTER_LO
	lda	#8
	sta	PSG_COUNTER
	sta	FM_INTERVAL
	sta	FM_COUNTER
	clra
	ldb	#$28
	jsr	FM_WRITE
	lda	#1
	jsr	FM_WRITE
	lda	#2
	jsr	FM_WRITE
	lda	#7
	ldb	#$3F
	jsr	PSG_WRITE
	lda	#8
	clrb
	jsr	PSG_WRITE
	lda	#9
	jsr	PSG_WRITE
	lda	#10
	jsr	PSG_WRITE
	rts

irq
	lda	$FD03
	lda	PSG_COUNTER
	suba	#1
	sta	PSG_COUNTER
	bne	fm_tick
	lda	#8
	sta	PSG_COUNTER
	jsr	PSG_UPDATE

fm_tick
	lda	FM_COUNTER
	suba	#1
	sta	FM_COUNTER
	bne	dummy
	lda	FM_INTERVAL
	sta	FM_COUNTER
	jsr	FM_UPDATE

dummy
	rti
	END
