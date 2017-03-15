;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
	

*******************************************************************
* dkInit - initialise the disk subsystem
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*

dkInit
		rts


	
*******************************************************************
* dkReadLSN - read block of data from the CF device
*
* on entry: X - byte *rdBuff - Read buffer address
*	    Y - byte *LSN
*
*  returns: X - byte *buff
*

dkReadLSN	pshs	a,y

* Local vars
		pshs	y
		pshs	x

		tfr	y,x	; X -> LSN

		ldy	#lba.p
		bsr	LSN2LBA

		ldx	2,s
		bsr	pQuad
		lda	#'>'
		bsr	pChar
		ldx	#lba.p
		bsr	pQuad
		bsr	pNL
		
		ldx	,s	
		ldy	#lba.p
		bsr	sdRdBlock

* We only want half of it - os9 LSNs are 256 bytes and SD
* blocks are 512.

		ldx	,s	; X -> *buff
		ldy	2,s	; y -> LSN
		lda	3,y	; check lowest byte of LSN for odd/even
		anda	#$01
		beq	evenLSN
		leax	256,x
		andcc	#$fe	; Clear carry
evenLSN
		leas	4,s	; Ditch local vars
		puls	y,a,pc

	
	
*******************************************************************
* dkWriteLSN - write a block of data to disk
*
* on entry: X - byte *wrBuff -  Write buffer address
*    	    Y - byte *LSN
*
*  trashes: nothing
*
*  returns: nothing
*

dkWriteLSN
		rts

	
	
*******************************************************************
* dkIncLSN - Increment the LSN by 1
*
* on entry: Y - byte *LSN
*
*  trashes: nothing
*
*  returns: nothing
*

dkIncLSN	pshs	d
		ldd	2,x
		addd	#1
		std	2,x
		bne	noLSNWrap
		ldd	,x
		addd	#1
		std	,x
noLSNWrap	puls	d,pc
