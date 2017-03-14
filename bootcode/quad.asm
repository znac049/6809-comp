*
* Simple 6809 Monitor
*
* Copyright(c) 2016, Bob Green
*



*******************************************************************
* clearQuad - initialise a quad to 0
*
* on entry: X - char *quad - address of quad
*
clearQuad	pshs	d
		ldd	#0
		std	,x
		std	2,x
		puls	d,pc


*******************************************************************
* shiftQuadL - shift quad left one bit
*
* on entry: X - char *quad - address of quad
*
shiftQuadL	pshs	a
		
		andcc	#$fe	; clear carry

		lda	3,x
		rola
		sta	3,x

		lda	2,x
		rola
		sta	2,x

		lda	1,x
		rola
		sta	1,x

		lda	,x
		rola
		sta	,x
		
		puls	a,pc


*******************************************************************
* atoq - convert string to quad
*
* on entry: X - char *quad - address of quad
*    	    Y - char *str  - string to convert
*	    A - max number of chars to convert. If zero, keep going
*	        until non convertable character found
*
*  returns: A - number of characters converted
*

atoq		pshs	x,y,b
		pshs	a		; The two pushes are deliberate

		bsr	clearQuad	; reset the quad to 0
		ldb	#0		; char count

atoq_Next
		lda	,y+		; grab the next char in the string
		bsr	hexval
		bcs	atoq_notHex
* valid conversion - shift it into the quad
  		bsr     shiftQuadL
		bsr	shiftQuadL
		bsr	shiftQuadL
		bsr	shiftQuadL
		ora	3,x
		sta	3,x

		addb	#1

		tst	,s		; Did we specify a max ?
		beq	atoq_Next	; No max - try for another

		cmpb	,s		; have we converted the max?
		bne	atoq_Next	; No, try for another

atoq_notHex
		puls	x,y,b,a,pc



*******************************************************************
* pQuad - print a long (32-bit) number
*
* on entry: X - char *quad - address of quad
*

pQuad		pshs	d

		ldd	,x
		bsr	p4hex
		ldd	2,x
		bsr	p4hex

		puls	d,pc



*******************************************************************
* gQuad - read a long (32-bit) number
*
* on entry: X - char *quad - address of quad
*

gQuad		
		rts
