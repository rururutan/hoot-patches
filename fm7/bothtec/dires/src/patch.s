*
* Dires/FM77AV for hoot driver
*
	ORG	$d000

SYSCALL	EQU	$0FD58
SYSCODE	EQU	$0FD59
SYSCOD2	EQU	$0FD5A
SYSCOD3	EQU	$0FD5B
STACK	EQU	$0FC80

init
	orcc	#$50			* FIRQ/IRQ disable

* stack
	lds	#STACK

	lda	#$00
	tfr	A,DP

	jsr	$7966

*	ldd	#$77F6
*	std	$FFF8			* irq

*	lda	#$04
*	sta	$FD02			* irq mask

	andcc	#$ef			* IRQ enable

loop
	lda	SYSCALL
	cmpa	#$01
	beq	play
	cmpa	#$02
	beq	stop
	bra	loop

play
	lda	SYSCODE
	cmpa	#$00
	beq	play_ttl
	cmpa	#$FF
	beq	sng_ext

	pshs	a
	jsr	$77F7			* stop
	jsr	$7966			* sound init
	puls	a

	deca
	lsla
	tfr	a,b
	clra
	ldu	#sngtbl
	jsr	[d,u]

	jsr	$75FD			* timer enable
	bra	execend

sngtbl
	fdb	$8607			* bgm1
	fdb	$8B23			* bgm2
	fdb	$8E54			* game over

play_ttl
	orcc	#$FF
	jsr	$1715			* sound init
	jsr	$205C			* data set
	jsr	$1E11			* timer-a enable
	andcc	#$EF
	bra	execend

sng_ext
	lda	SYSCOD2
	sta	$75C4
	bra	execend

stop
	jsr	$200B			* stop(ttl)
	jsr	$77F7			* stop(bgm)

execend
	lda	#$FF
	sta	SYSCODE
	bra	loop

	END
