;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;

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

mcFullMatch	lda	#1
		bra	mcDone

;  Not matched - skip to end of command string
mcNoMatch	tsta
		beq	mcFail
		lda	,x+
		bra	mcNoMatch
	
mcFail		clra
		leax	2,x	; skip help message pointer
	
mcDone		puls	b,y,pc



cmdTable	fdb	bootCmd
		fcn	"boot"
		fdb	0

		fdb	cfInfoCmd
		fcn	"cfinfo"
		fdb	cfinfoUsage

		fdb	helpCmd
		fcn	"help"
		fdb	0

		fdb	0


*******************************************************************
* bootCmd - execute the 'boot' command
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*
bootCmd		leax	bootMsg,pcr
		bsr	pStr

		ldx	#CFBase
		bsr	cfWait
		lda	#CMD.IDENTIFY
		sta	CF.Command,x
		tfr	x,y
		ldx	#secBuff
		bsr	cfReadBuff
		
		rts

	
	
bootMsg		fcn	"BOOT command not implemented yet!\r\n"


		
*******************************************************************
* cfInfoCmd - execute the 'cfinfo' command
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*
cfInfoCmd	leax	cfinfoMsg,pcr
		bsr	pStr
		bsr	cfInfo

		rts

	
cfinfoMsg	fcn	"Querying CF devices...\r\n"
cfinfoUsage	fcn	" - display info about CF disk(s), if present"


	
*******************************************************************
* helpCmd - execute the 'help' command
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
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
