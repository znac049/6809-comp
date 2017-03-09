;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
	
*******************************************************************
* cfWait - wait for CF to be ready
*
* on entry: X - base of CF 
*
*  trashes: A
*
*  returns: nothing
*

cfWait		lda	CF.Status,x
		anda	#$80	; Check BUSY flag
		bne	cfWait
		rts


	
*******************************************************************
* cfInit - initialise the CF subsystem
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*

cfInit		pshs	a,x
		leax	CFBase,pcr
		lda	#CMD.DIAG       ; The device won't accept any other commands
					; until DIAG has been run
		sta	CF.Command,x

		lda	CF.Error,x	; Read diag status code
		cmpa	#$80		; No CF devices
		beq	noCF
		cmpa	#$01
		bne	secPres
		leax	priCFMsg,pcr
		bsr	pStr
		bra	cfiCont

secPres		leax	secCFMsg,pcr
		bsr	pStr
		bra	cfiCont

noCF		leax	noCFMsg,pcr
		bsr	pStr
	
cfiCont		leax	CFBase,pcr
		bsr	cfWait

*		lda	#CMD.RESET 	; Reset
*		sta	CF.Command,x
*		bsr	cfWait

		lda	#$E0		; LBA mode, Not sure why $E0 instead of $40
		sta	CF.LSN3,x

		lda	#$01		; 8-bit transfers
		sta	CF.Features,x
		lda	#CMD.SETFEATURES
		sta	CF.Command,x
		bsr	cfWait
	
		puls	x,a,pc

	
noCFMsg		fcn	"No CF devices present\r\n"
priCFMsg	fcn	"CF #0 present\r\n"
secCFMsg	fcn	"CF #1 present\r\n"


	
*******************************************************************
* cfRead - read a single sector from disk
*
* on entry: X - Read buffer address
*
*  trashes: nothing
* 
*  returns: nothing
*

cfRead		pshs	a,x,y

		leay	CFBase,pcr

		lda	#$20	; Read sector with retry command
		sta	CF.Command,y

		bsr	cfReadBuff

		puls	y,x,a,pc


	
*******************************************************************
* cfReadBuff - read block of data from the CF device
*
* on entry: X - Read buffer address
*	    Y - Address of CF device
*
*  trashes: nothing
*
*  returns: nothing
*

cfReadBuff	pshs	a,b,x
		ldb	#0
	
cfRdNext
cfRdWait	lda	CF.Status,y
		anda	#SR.DRQMask
		beq	cfRdWait

		lda	CF.Data,y
		sta	,x+

		decb
		bne	cfRdNext

		puls	x,b,a,pc

	
	
*******************************************************************
* cfWrite - write a block of data to disk
*
* on entry: X - Write buffer address
*
*  trashes: nothing
*
*  returns: nothing
*

cfWrite		pshs	a,b,x,y

		leay	CFBase,PCR

		lda	#$30	; Write sector with retry command
		sta	CF.Command,Y

cfWrNext
cfWrWait	lda	CF.Status,Y
		anda	#$04	; DRQ -
		beq	cfWrWait

		ldb	#0	; loop counter - 256 bytes
		lda	,X+
		sta	CF.Data,Y

		decb
		bne	cfWrNext

		puls	y,x,b,a,pc

	
	
*******************************************************************
* cfSetLSN - 
*
* on entry: X - address of LSN (4 bytes)
*
*  trashes: nothing
*
*  returns: nothing
*

cfSetLSN	pshs	a,b,y

		leay	CFBase,PCR
		ldd	2,x
		stb	CF.LSN0,y
		sta	CF.LSN1,y
		ldd	,x
		stb	CF.LSN2,y
		anda	#$0f
		ora	#$40		; LBA mode, drive 0
		sta	CF.LSN3,y

		puls	y,b,a,pc

	
	
*******************************************************************
* cfInfo - get CF device info and display it
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*

cfInfo		pshs	a,b,x,y
	
		ldx	#CFBase
		bsr	cfWait
		lda	#CMD.IDENTIFY
		sta	CF.Command,x
		tfr	x,y
		ldx	#secBuff
		bsr	cfReadBuff
		ldy	#secBuff
* Serial #
		leax	cfiSerMsg,pcr
		bsr	pStr
		leax	20,y
		ldb	#20
		bsr	pnpStr
		bsr	pNL

* Firmware
		leax	cfiFWMsg,pcr
		bsr	pStr
		leax	46,y
		ldb	#8
		bsr	pnpStr
		bsr	pNL

* Model #
		leax	cfiModelMsg,pcr
		bsr	pStr
		leax	54,y
		ldb	#40
		bsr	pnpStr
		bsr	pNL

		puls	y,x,b,a,pc

	
	
cfiSerMsg	fcn	"  Serial: "
cfiFWMsg	fcn	"Firmware: "
cfiModelMsg	fcn	"   Model: "
