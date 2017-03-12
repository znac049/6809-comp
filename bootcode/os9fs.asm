;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;



*******************************************************************
* OS9 Filesystems


* ID Block (LSN 0)
*
DD			struct
	
totSectors		rmb	3
numTracks		rmb	1
map			rmb	2
sectorsPerCluster	rmb	2
rootLSN			rmb	3
owner			rmb	2
attribs			rmb	1
id			rmb	2
format			rmb	1
spt			rmb	2
unused1			rmb	2
bootLSN			rmb	3
bootSize		rmb	2
created			rmb	5
volName			rmb	32
options			rmb	32
			
			endstruct


* File Descriptor
*
FD		struct

attribs		rmb	1
owner		rmb	2
modified	rmb	5
linkCount	rmb	1
size		rmb	4
created		rmb	3
segments	rmb	240

		endstruct


*******************************************************************
* os9Check - check a disk to see if it has an OS9 filesystem on it.
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*
os9check	
		rts


*******************************************************************
* loadboot - 
*
* on entry: none
*
*  trashes: nothing
*
*  returns: nothing
*
loadboot	
		ldx	#lsn.p
		ldd	#0
		std	,x
		std	2,x

		bsr	cfSetLSN

		ldx	#secBuff
		bsr	cfRead

* Get details of the OS-9 root directory
		ldy	#rootLSN.p
	
		ldd	DD.rootLSN,x
		std	,y++
		ldb	DD.rootLSN+2,x
		clra
		std	,y

* Get details of the boot file
		ldy	#bootLSN.p
	
		ldd	DD.bootLSN,x
		std	,y++
		ldb	DD.bootLSN+2,x
		clra
		std	,y

		rts