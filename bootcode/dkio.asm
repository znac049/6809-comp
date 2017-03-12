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
*  trashes: nothing
*
*  returns: X - byte *LSN
*

dkReadLSN	pshs	a,y

		ldy	#lba.p
		bsr	LSN2LBA
		bsr	sdRdBlock

* We only want half of it - os9 LSNs are 256 bytes and SD
* blocks are 512.

		lda	3,y	; check lowest byte of LSN for odd/even
		anda	#$01
		beq	evenLSN
		leax	256,x
		andcc	#$fe	; Clear carry
evenLSN		puls	y,a,pc

	
	
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
