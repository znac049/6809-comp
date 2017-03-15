*
* Simple 6809 Monitor
*
* Copyright(c) 2016, Bob Green
*


*******************************************************************
* findCmd - look up command in command table
*
* on entry: X - address of command table
*
*  trashes: nothing
*
*  returns: D - address of handler function, else 0
*

findCmd
findLoop	ldd	,x++	; Get handler function address
		beq	noMatch	; 0 means no more entries
		tfr	d,y
		bsr	compareCmd
		cmpa	#0
		beq	findLoop

; We have a match
		tfr	y,d
*		bra	findEnd	;

noMatch		
findEnd		rts


	
*******************************************************************
* compareCmd - check command against a command table entry
*
* on entry: X - address of command table entry
*
*  trashes: nothing
*
*  returns: A - 1 if match, otherwise 0
* 	    X - address of next command table entry
*
compareCmd	pshs	b,y

		ldy	#line
		sty	arg.p

mcNext		lda	,x+	; command table char
		beq	mcHalfMatch
		cmpa	,y+	; line char
		beq	mcNext
; No match
		bra	mcNoMatch

; Command matches 
mcHalfMatch	lda	,y	; should be space or EOS
		beq	mcFullMatch
		cmpa	#' '
		beq	mcFullMatch
		bra	mcFail

mcFullMatch	cmpa	#' '
		bne	mcSuccess
		lda	,y+
		bra	mcFullMatch

mcSuccess	leay	-1,y
		sty	arg.p
		lda	#1
		bra	mcDone

;  Not matched - skip to end of command string
mcNoMatch	tsta
		beq	mcFail
		lda	,x+
		bra	mcNoMatch
	
mcFail		
		clra
		leax	2,x	; skip help message pointer
	
mcDone		puls	b,y,pc



*******************************************************************
* helpCmd - execute the 'help' command
*
* on entry: none
*
helpCmd		leax	helpMsg,pcr
		bsr	pStr

		leax	cmdTable,pcr

helpNext	ldd	,x++
		beq	helpDone
	
		lda	#' '
		bsr	pChar
		bsr	pChar

		bsr	pStr

helpSkip	lda	,x+
		bne	helpSkip

		ldd	,x++
		beq	noHelp

		pshs	x
		tfr	d,x
		bsr	pStr
		puls	x

noHelp		bsr	pNL

		bra	helpNext

helpDone	bsr	pNL
		rts

	
helpMsg		fcn	"Available commands:\r\n\n"


