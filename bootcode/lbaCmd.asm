*
* Simple 6809 Monitor
*
* Copyright(c) 2016, Bob Green
*


*******************************************************************
* lbaCmd - execute the 'lba' command
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*
lbaCmd		ldy	arg.p
		lda	,y
		cmpa	#0
		beq	lbaNoArg

* An argument was provided, it should be a valid LBA
     	        ldx	#lba.p
		clra
		bsr	atoq
* fall through and print the new value


lbaNoArg	leax	lbaMsg,pcr
		bsr	pStr
		ldx	#lba.p
		bsr	pQuad
		bsr	pNL

lbaDone		rts

lbaMsg		fcn	"LBA="


