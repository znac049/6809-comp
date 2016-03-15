
codeseg		struct
sig		rmb	1
len		rmb	2
addr		rmb	2
		endstruct
	
;--------------------------------------------------------------------------------
; doBoot - attempt to boot from SD card
;
; on entry:
;
; trashes: everything
;
; returns: nothing
;
doBoot:
; attempt to read the real MBR...
		leax    ldMBRMsg,pcr
		bsr	pStr

		leay	sdBuff,pcr		; MBR buffer
		bsr	loadMBR
		beq	MBRok

MBRok:	
		bsr	pNL
; Check the MBR is valid
		leax	mbrSigMsg,pcr
		bsr	pStr

		leau    sdBuff,pcr		; point at the real read buffer

		ldd	mbr.sig,u		; Look for the Mbr signature
		bsr	p4hex			; print signature
		bsr	pNL

		lda	#1			; # of partitions to check
		ldx     #0
		leay	446,x			;
btChk		ldb	4,y			;
		cmpb	#6			; FAT16 partition?
		beq     itsFAT
		lbra	notFAT

; extract info about partition size
itsFAT		leay    8,y			; First sector LBA
		ldd     ,y++
		exg     a,b
		std     partStart
		ldd     ,y++
		exg     a,b
		std     partStart+2
            
		ldd     ,y++
		exg     a,b
		std     partSize
		ldd     ,y
		exg     a,b
		std     partSize+2
            
; We've found a FAT16 partition
		leax	foundFATMsg,pcr
		bsr	pStr
            
		adda	#'0
		bsr	pChar
            
		bsr	pNL
            
; Take a look at the FAT16 boot record
		leax	partStartMsg,pcr
		bsr	pStr
            
		leax	partStart,pcr
		bsr	pLBA
		bsr	pNL
            
		leay	sdBuff,pcr
		bsr	rdBlock
            
; Check it looks like a boot sector
		ldd     510,y
		bsr	p4hex
		bsr	pNL
            
		cmpd    #$55aa			; Good sig?
		lbne    badBootBlk
            
		leax	volMsg,pcr
		bsr	pStr
            
		leax    $2b,y			; Volume label - 11 bytes
		ldb     #11
		bsr	pnStr
		bsr	pNL
            
; Calculate the LBA of start of FAT #1. Add in the number of reserved sectors to get the LBA of the start
; of FAT #1. #reserved is usually 1
		leax    FATStartMsg,pcr
		bsr	pStr
            
		leax    FATLBA,pcr
		bsr	clearLBA
            
		ldd     14,y			; # reserved sectors
		exg     a,b
		std     ,x           
		bsr	logToPhysLBA    
            
		bsr	pLBA
		bsr	pNL
            
; Calculate the LBA of the start of the root directory. This is:
;
;   (<number of sectors per FAT> * <number of FATs)) + <start of FAT #1 LBA>
;
		leax    RootLBA,pcr		; LBA of start of root directory
		bsr	clearLBA
            
		ldd     22,y			; # sectors per FAT
		exg     a,b
		std     ,x
		bsr	pLBA
		bsr	pNL
            
		ldd     17,y
		exg     a,b
		std     maxRootEnts,pcr
            
; 1 or 2 FATs?
		lda     16,y			; # of FATs
		cmpa    #2
		beq     twoFATs
		cmpa    #1
		beq     oneFAT
		bra     badBootBlk
            
twoFATs:	ldd     22,y
		exg     a,b
		std     22,y			; Truly horrible!
		addd    22,y
		std     ,x
		bcc     twoFATcc
		inc     3,x
twoFATcc	bra     FATSok
            
oneFAT:		ldd     22,y
		exg     a,b
		std     ,x
		bra     FATSok
                        
FATSok
		leay    FATLBA,pcr
		leax    RootLBA,pcr
		bsr	addLBAs
		bra     bootBlkOk
            
badBootBlk	leax    bootSecProb,pcr
		bsr	pStr
		bra     bootOver
            
bootBlkOk	leax    rootStartMsg,pcr
		bsr	pStr
            
		leax    RootLBA,pcr
		bsr	pLBA
		bsr	pNL
            
; All good so far - look in the root directory for a boot file...
		ldy     maxRootEnts,pcr
            
chkDir:		leay    -1,y
		bne     chkDir
            
		leax    noFileMsg,pcr
		bsr	pStr
            
bootOver
		rts
            
; - populate the DCB

notFAT		leay	16,y			;
		inca				; have we checked all partitions?
		cmpa    #5
		lblt	btChk
            

; No FAT16 partition found
		leax	noFATMsg,pcr
		bsr	pStr

		rts


