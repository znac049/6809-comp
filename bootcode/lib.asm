*
* Straight from the CMOC source code, see http://sarrazip.com/dev/cmoc.html
*


* Divide X by D, unsigned; return quotient in X, remainder in D.
*  	      
div16		pshs	x,b,a
	 	ldb 	#16
	      	pshs	b
	      	clra
		clrb
		pshs	b,a

* 0,S=16-bit quotient; 2,S=loop counter;
* 3,S=16-bit divisor; 5,S=16-bit dividend

d16010	     	lsl     6,s		; shift MSB of dividend into carry
	     	rol     5,s		; shift carry and MSB of dividend, into carry
		rolb			; new bit of dividend now in bit 0 of B
		rola
		cmpd	3,s		; does the divisor "fit" into D?
		blo	d16020		; if not
		subd	3,s
		orcc	#1		; set carry
		bra	d16030
d16020		andcc	#$FE		; reset carry
d16030		rol	1,s		; shift carry into quotient
		rol	,s

		dec	2,s		; another bit of the dividend to process?
		bne 	d16010  	; if yes
		
		puls	x		; quotient to return
		leas	5,s
		rts



* Divide X by D, signed; return quotient in X, remainder in D.
* Non-zero remainder is negative iff dividend is negative.
*
sdiv16	   	pshs	x,b,a
		clr	,-s		; counter: number of negative arguments (0..2)
		clr	,-s		; boolean: was dividend negative?
		tsta			; is divisor negative?
		bge	sdiv16_10	; if not
		inc	1,s
		coma			; negate divisor
		comb
		addd	#1
		std	2,s
sdiv16_10
		ldd	4,s		; is dividend negative?
		bge	sdiv16_20	; if not
		inc	,s
		inc	1,s
		coma			; negate dividend
		comb
		addd	#1
		std	4,s
sdiv16_20
		ldd	2,s		; reload divisor
		ldx	4,s		; reload dividend
		bsr	div16

* Counter is 0, 1 or 2. Quotient negative if counter is 1.
	        lsr	1,s		; check bit 0 of counter (1 -> negative quotient)
		bcc	sdiv16_30	; quotient not negative
		exg	x,d		; put quotient in D and remainder in X
		coma			; negate quotient
		comb
		addd	#1
		exg	x,d		; return quotient and remainder in X and D

sdiv16_30
* Negate the remainder if the dividend was negative.
	        tst	,s		; was dividend negative?
		beq	sdiv16_40	; if not
		coma			; negate remainder
		comb
		addd	#1
sdiv16_40
		leas	6,s
		rts

