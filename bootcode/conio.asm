;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;

*******************************************************************
* conInit - initialise the console subsystem
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*

conInit		pshs	a,x

		ldx	#Uart0Base

		lda	#$03	; Master reset
		sta	StatusReg,x

		puls	x,a,pc

	

*******************************************************************
* gChar - fetch a character from the serial port
*
* on entry: none
*
*  trashes: nothing
*
*  returns: A - character read
*

gChar		pshs	x

		ldx	#Uart0Base

@next		lda	StatusReg,x
		bita	#1		; rx register full?
		beq	@next

		lda	DataReg,x	; grab the character

		puls	x,pc


	
*******************************************************************
* pChar - print a character
*
* on entry: A - character to print
*
*  trashes: nothing
*
*  returns: nothing
*

pChar		pshs	b,x

		ldx	#Uart0Base

@wait		ldb	StatusReg,x
		bitb	#2		; tx register empty?
		beq	@wait
		
		sta	DataReg,x	; send the char

		puls	x,b,pc



*******************************************************************
* ppChar - print a character, replacing unprintables with '.'
*
* on entry: A - character to print
*
*  trashes: nothing
*
*  returns: A - the character that was actually printed
*

ppChar		pshs	b,x

		ldx	#Uart0Base

@wait		ldb	StatusReg,x
		bitb	#2		; tx register empty?
		beq	@wait

		cmpa	#' '
		blt	dot
		cmpa	#126
		bgt	dot

		bra	notDot

dot		lda	#'.'
notDot		sta	DataReg,x	; send the char

		puls	x,b,pc



*******************************************************************
* pStr - print EOS terminated string
*
* on entry: X - address of string
*
*  trashes: nothing
*
*  returns: nothing
*

pStr		pshs	a,x

pStrNext	lda	,x+
		beq	pStrEnd
		bsr	pChar
		bra	pStrNext

pStrEnd 	puls	x,a,pc


	
*******************************************************************
* pnStr - print n bytes of a string
*
* on entry: B - number of bytes
*	    X - address of string
*
*  trashes: B,X
*
* returns: nothing
*

pnStr		pshs	a

		cmpb    #0
		beq     pnStrEnd
            
pnStrNext	lda	,x+

		bsr	pChar
		decb
		beq     pnStrEnd
		bra	pnStrNext

pnStrEnd 	puls	a,pc

	

*******************************************************************
* pnpStr - print n bytes of a string using only printable chars
*
* on entry: B - number of bytes
*	    X - address of string
*
*  trashes: B,X
*
* returns: nothing
*

pnpStr		pshs	a

		tstb
		beq     pnpStrEnd
            
@next		lda	,x+
		bsr	ppChar
		decb
		beq     pnpStrEnd
		bra	@next

pnpStrEnd 	puls	a,pc

	

*******************************************************************
* pLBA - print a LBA as hex
*
* on entry: X - Pointer to LBA
*
*  trashes: nothing
*
*  returns: nothing
*

pLBA		pshs	d

		ldd     2,x
		bsr	p4hex			; print upper word
		ldd     ,x
		bsr	p4hex			; print lower word

		puls	d,pc


	
*******************************************************************
;--------------------------------------------------------------------------------
; p4hex - print a word as hex
;
; on entry:
;	 D - word to print
;
; trashes: nothing
;
; returns: nothing
;

p4hex		pshs	d

		bsr	p2hex			; print upper byte
		tfr	b,a
		bsr	p2hex			; print lower byte

		puls	d,pc

	

*******************************************************************
* p2hex - print a byte as hex
*
* on entry: A - byte to print
*
*  trashes: nothing
*
*  returns: nothing
*

p2hex  		pshs	a
		pshs	a

		lsra				; upper nibble first
		lsra
		lsra
		lsra

		bsr	p1hex			; print upper nibble
		puls	a
		bsr	p1hex			; print lower nibble

		puls	a,pc


	
*******************************************************************
* p1hex - print a nibble as hex
*
* on entry: A - nibble to print - low 4 bits
*
*  trashes: A
*
*  returns: nothing
*

p1hex		anda	#$0f
		cmpa	#10
		blt	p1hexNum

		suba	#10
		adda	#'A
		bra	p1hexPr

p1hexNum	adda	#'0

p1hexPr 	bsr	pChar

		rts


	
*******************************************************************
* pNL
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*

pNL 		pshs	a

		lda	#CR
		bsr	pChar

		lda	#LF
		bsr	pChar

		puls	a,pc



*******************************************************************
* pQuad.p - print a long (32-bit) number by reference
*
* on entry: X address of quad
*
*  trashes: nothing
*
*  returns: nothing
*

pQuad.p		pshs	d

		ldd	,x
		bsr	p4hex
		ldd	2,x
		bsr	p4hex

		puls	d,pc



*******************************************************************
* readLine - read a line from the console, terminated by CR or LF.
*		BS/DEL are treated as DEL. Control characters are
*		ignored.
*
* on entry: X - address of buffer
* 	    A - max chars to read
*
*  trashes: nothing
*
*  returns: A - number of chars read
*

getLine		pshs	b,x
		sta	temp
		clrb

glNextChar	bsr	gChar
		anda 	#$7F      		
		cmpa 	#BS
		beq 	backsp
		cmpa 	#DEL
		beq 	backsp
	
		cmpa 	#CR
		beq 	newline
		cmpa 	#LF
		beq 	newline
	
		cmpa	#' '
		blo	glNextChar	; Ignore control characters.
		cmpb	temp
		beq	glNextChar	; Ignore char if line full.
		bsr	pChar		; Echo the character.
		sta	,x+		; Store it in memory.
		incb
		bra	glNextChar
	
backsp		tstb            	; Recognize BS and DEL as backspace key.
		beq 	glNextChar	; ignore if line already zero length.
		lda 	#BS
		bsr 	pChar
		lda 	#' '
		bsr 	pChar
		lda 	#BS		; Send BS,space,BS. This erases last
		bsr 	pChar 		; character on most terminals.
		leax 	-1,x		; Decrement address.
		decb
		bra 	glNextChar
	
newline		clr	,x
        	bsr 	pNL             
		tfr 	b,a		; Move length to A
	
		puls 	b,x,pc



*******************************************************************
* g4hex - read four hex bytes
*
* on entry: nothing
*
*  trashes: nothing
*
*  returns: D - decoded word value
*  	    CC.C - set if error detected
*

g4hex		bsr	g2hex
		bcs	g4hBad

		tfr	a,b
		bsr	g2hex
		bcs	g4hBad

		exg	a,b
		bra	g4hDone

g4hBad		orcc	#$01		; Set the carry bit
		bra	g4hRet

g4hDone		andcc	#$fe		; Clear the carry bit

g4hRet		puls 	pc


	
*******************************************************************
* g2hex - read two hex bytes
*
* on entry: nothing
*
*  trashes: nothing
*
*  returns: A - decoded byte value
*  	    CC.C - set if error detected
*

g2hex		pshs	b

		bsr	g1hex
		bcs	g2hBad
		tfr	a,b

		bsr	g1hex
		bcs	g2hBad
		lsrb
		lsrb
		lsrb
		lsrb
		pshs	b
		ora	,s
		puls	b

		bra	g2hDone

g2hBad		orcc	#$01		; Set carry bit
		bra	g2hRet

g2hDone		andcc	#$fe		; Clear carry bit

g2hRet		puls 	b,pc


	
*******************************************************************
* g1hex - read a hex byte
*
* on entry: nothing
*
*  trashes: nothing
*
*  returns: A - decoded byte value
*  	    CC.C - set if error detected
*

g1hex		bsr	gChar
		cmpa	#'0'
		blt	g1hBadChar
		cmpa	#'9'
		blt	g1hNum
* Not a number - is it A-F or a-f
      	       	anda    #$df		; Convert to upper case
		cmpa	#'A'
		blt	g1hBadChar
		cmpa	#'F'
		bgt	g1hBadChar

* It's in the range A-F
       	      	suba	#('A'-10)
		bra	g1hDone

* Its a number
g1hNum		suba	#'0'
		bra	g1hDone

g1hBadChar	orcc	#$01		; Set carry bit
		bra	g1hRet

g1hDone		andcc	#$fe		; Clear carry bit

g1hRet		puls 	pc

	
