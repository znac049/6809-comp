*******************************************************************
* loadCmd - load a program from the console in MOtorola S record
*           format.
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*
loadCmd		leax	loadMsg,pcr
		bsr	pStr

srNext		bsr	gChar
		cmpa	#CR
		beq	srNext
		cmpa	#LF
		beq	srNext
		cmpa	#3		; Ctrl-C
		beq	srQuit
		cmpa	#'S'
		bne	srBadChar

* Nrxt byte is record type
       	        bsr     gChar

		DBGS	'C'
		
		cmpa    #'0'
		blt     srBadChar
		cmpa    #'9'
		bgt     srBadChar
		sta	srType

* Next two bytes are count
       	        bsr     g2hex
		bcs	srBadChar
		sta	srCount
		sta	srXSum		; Initialise checksum

* What comes next is record type specific

* ...Some records, we silently ignore
       		lda	srType
		cmpa	#'0'
		beq	srIgnore
		cmpa	#'5'
		beq	srIgnore
		cmpa	#'9'
		beq	srNine
		cmpa	#'1'
		beq	srOne
		bra	srNotSupported


* S9 record - sets start address and terminates
* next 4 bytes are the start address
srNine
		bsr	pNL
		bsr	pNL

		bsr	g4hex
		bcs	srBadChar
		std	srAddr

		DBGL	'A'

		adda	srXSum
		sta	srXSum
		addb	srXSum
		stb	srXSum

* Next byte will be the checksum
       	    	bsr     g2hex
		bcs	srBadChar
		tfr	a,b

		DBGS	'X'

		lda	srXSum
		coma
		sta	srXSum

		cmpb	srXSum
		beq	sr9OK

		leax	srBadXSumMsg,pcr
		bsr	pStr
		bsr	srSkip
		bra	srDone

sr9OK		leax	srLoadedMsg,pcr
		bsr	pStr

		ldd	srAddr
		bsr	p4hex

		bsr	pNL

		bsr	srSkip
		bra	srDone		; S9 record is always the last one, so quit loading

* S1 record - next 4 bytes are the load address
srOne		
		bsr	g4hex
		bcs	srBadChar
		std	srAddr

		adda	srXSum
		sta	srXSum
		addb	srXSum
		stb	srXSum

		ldd	srAddr
		bsr	p4hex
		lda	#CR
		bsr	pChar

* prepare to read the data bytes		
		ldy	srAddr
		ldb	srCount
		clra
		subd	#3		; count included address and xsum
		tfr	d,x

* Read loop starts here
sr1Next
		bsr	g2hex
		bcs	srBadChar

		tfr	a,b
		addb	srXSum
		stb	srXSum

		sta	,y+		; Deposit byte at correct address

		leax	-1,x		; Count--
		beq	sr1DataDone

		bra	sr1Next		


sr1DataDone
* Next byte will be the checksum
       	    	bsr     g2hex
		bcs	srBadChar
		tfr	a,b

		lda	srXSum
		coma
		sta	srXSum

		cmpb	srXSum
		beq	sr1OK

		leax	srBadXSumMsg,pcr
		bsr	pStr
		bsr	srSkip
		bra	srDone

sr1OK		bsr	srSkip
		bra	srNext		; wait for the next record


* User wants to quit
srQuit		bsr	srSkip
		bra	srDone


* Ignore this record - it's harmless
srIgnore        bsr    	srSkip
		bra	srNext		; wait for the next record

* We don't support all S records, in particular the ones that deal with
* a memory space bigger than 64K
srNotSupported	leax	srRecNotSupported,pcr
		bsr	pStr
		lda	srType
		bsr	pChar
		bsr	pNL
		bra	srDone2

srBadChar	leax	srBadFormatMsg,pcr
		bsr	pStr
srDone2		bsr	srSkip

srDone
		rts

* Skip the rest of the record
srSkip		bsr	gChar
		cmpa	#CR
		beq	srsDone
		cmpa	#LF
		bne	srSkip
srsDone		rts



	
	
loadMsg		fcn	"Ok, waiting for S records on console..."
loadUsage	fcn	" - load program in S record format via the console"
srBadFormatMsg	fcn	"\r\nUnexpected character while reading S record.\r\n"
srRecNotSupported
		fcn	"\r\nUnsupported S record type: "
srBadXSumMsg	fcn	"\r\nCalculated checksum does not match transmitted checksum!\r\n"
srLoadedMsg	fcn	"\r\nLoaded OK. Start address: "

		
