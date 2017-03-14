*
* Simple 6809 Monitor
*
* Copyright(c) 2016, Bob Green
*


*******************************************************************
* lsnCmd - execute the 'lsn' command
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*
lsnCmd		ldy	arg.p
		lda	,y
		cmpa	#0
		beq	lsnNoArg

* An argument was provided, it should be a valid LSN
     	        ldx	#lsn.p
		clra
		bsr	atoq
* fall through and print the new value

lsnNoArg	leax	lsnMsg,pcr
		bsr	pStr
		ldx	#lsn.p
		bsr	pQuad
		bsr	pNL

		leax	lbaMsg,pcr
		bsr	pStr
		ldx	#lsn.p
		ldy	#lba.p
		bsr	LSN2LBA
		ldx	#lba.p
		bsr	pQuad
		bsr	pNL

lsnDone		rts

lsnMsg		fcn	"LSN="


