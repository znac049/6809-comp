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

		ldx	#lsn.p
		bsr	clearQuad
		tfr	x,y

		ldx	#secBuff

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
		bsr	pQuad
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
		bsr	pQuad
		bsr	pNL

* Grab the boot size
       	   	ldd	DD.bootSize,u
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

		
