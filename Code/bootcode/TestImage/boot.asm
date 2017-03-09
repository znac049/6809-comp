	pragma	6809

	org	$2800

	jmp	start
	fcb	'B','G'

start	orcc	#$ff	; disable interrupts
	lds	#$2800	; safe stack

	ldd	#0	; counter
	ldy	#$ff70	; 7 segment display base address

next

* Display the counter on the 7-segment display
	tfr	d,u
	sta	1,y
	stb	3,y

	lsra
	lsra
	lsra
	lsra
	sta	,y

	lsrb
	lsrb
	lsrb
	lsrb
	stb	2,y

	tfr	u,d
	addd	#1


* Simple delay - about 1sec at 1MHz
	tfr	d,u
	ldd	#1000
wait	subd	#1
	bne	wait
	tfr	u,d

	bra	next	; loop forever

