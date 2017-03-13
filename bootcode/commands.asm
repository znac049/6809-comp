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

		fdb	loadCmd
		fcn	"load"
		fdb	loadUsage

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

		ldx	#secBuff
		ldy	#lsn.p
		clra
		clrb
		std	,y	; Set LSN=0
		std	2,y	;
		bsr	dkReadLSN
		bcs	badRead

		tfr	x,u	; u = LSN buffer

		leax	boot1Msg,pcr
		bsr	pStr

* Copy the root LSN
		ldy	#rootLSN.p
		leax	DD.rootLSN,u
		clra
		ldb	,x
		std	,y
		ldd	1,x
		std	2,y

		leax	rootLSNMsg,pcr
		bsr	pStr
		ldx	#rootLSN.p
		bsr	pQuad.p
		bsr	pNL

* Copy the boot LSN
		ldy	#bootLSN.p
		leax	DD.bootLSN,u
		clra
		ldb	,x
		std	,y
		ldd	1,x
		std	2,y

		leax	bootLSNMsg,pcr
		bsr	pStr
		ldx	#bootLSN.p
		bsr	pQuad.p
		bsr	pNL

* Grab the boot size
       	   	ldd	bootSize,u
		std	bootSize

		leax	bootSizeMsg,pcr
		bsr	pStr
		bsr	p4hex
		bsr	pNL

* If boot size is zero, can't boot
     	        cmpd	#0
	       	beq	nonBoot

* Looking good. Read LSNs sequentially until 
* 'bootSize' bytes have been read. Load into
* memory at $2800.
		ldu	#$2800
bootLoop
		ldx	#secBuff
		ldy	#bootLSN.p
		bsr	dkReadLSN
		bsr	dkIncLSN

		ldd	bootSize
		subd	#256
		cmpd	#0
		bgt	bootLoop

		leax	bootLoadedMsg,pcr
		bsr	pStr
		bra	bootDone


nonBoot		leax	nonBootMsg,pcr
		bsr	pStr
		bra	bootDone


badRead		leax	badBootMsg,pcr
		bsr	pStr


bootDone	rts

	
	
bootMsg		fcn	"Attempting to boot from CF/SD\r\n"
boot1Msg	fcn	"LSN0 read ok.\r\nBoot LSN:"
nonBootMsg	fcn	"Non bootable disk (bootSize=0)\r\n"
badBootMsg	fcn	"Couldn't read LSN0.\r\n"
rootLSNMsg	fcn	"Root LSN: "
bootLSNMsg	fcn	"Boot LSN: "
bootSizeMsg	fcn	"Boot size: "
bootLoadedMsg	fcn	"Boot code loaded into memory at $2800\r\n"

		
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
