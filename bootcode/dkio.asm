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
*  returns: nothing
*

dkReadLSN
		rts

	
	
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
