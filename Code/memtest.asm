
		org	$400

		leax	endofCode,pcr

loop:
		ldb	,x
		pshs	b

* Display address being tested
		tfr	x,d	
		sta	$ff71
		stb	$ff73
		lsrd
		lsrd
		lsrd
		lsrd
		sta	$ff70
		sta	$ff72
		
		lda	#$55
		sta	,x
		eora	,x
		bne	badRead

		lda	#$aa
		sta	,x
		eora	,x
		bne	badRead

		puls	b
		stb	,x

		leax	1,x
		cmpx	#$c000
		bne	loop

badRead		nop

endofCode		