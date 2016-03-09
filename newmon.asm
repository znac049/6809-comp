;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;

ROMBeg		equ $E000		;
ROMSize		equ 8192

CR			equ 13
LF			equ 10
EOS			equ 0

SDCard		equ		$ffd8
sdData		equ		0
sdCtrl		equ		1
sdStatus	equ		1
sdLBA0		equ		2
sdLBA1		equ		3
sdLBA2		equ		4
sdLBA3      equ     5

Acia		equ		$FFD0
acCtrl      equ     0
acStatus    equ     0 
acData      equ     1


; Offsets into RAM
sdBuff      equ     0               ; Sector buffer - 512 bytes
partStart   equ     sdBuff+512      ; 4 bytes - LBA of first sector in partition
partSize    equ     partStart+4     ; 4 bytes - # sectors in partition
LBA_t       equ     partSize+4      ; 4 bytes - LBA to read/write
FAT_LBA_t   equ     LBA_t+4         ; 4 bytes - LBA of start of FAT table #1
Root_LBA_t  equ     FAT_LBA_t+4     ; 4 bytes - LBA of start of root directory
maxRootEnts equ     Root_LBA_t+4    ; 2 bytes - max number of root directory entries

; Offsets into the MBR
MbrSig		equ 510

			org		ROMBeg



;
; Hard reset
;
RESET
            lds     #$800           ; Safe starting point for stack
            
; Init serial IO
			leau	Acia,pcr

			lda		#$03			; Reset device
			sta		acCtrl,u

			lda		#$95			; div 16
			sta		acCtrl,u
            
            
; next thing is find some RAM for our initial stack
;
; Assumptions:
;  1. Ram is a single contiguous chunk
;  2. Ram size is in whole Kbytes
			ldx		#0
			lda		#$5a
            
            lds     #$1000

testRam
			sta		,x				; Write byte and see if...
			cmpa	,x				; ...we can read it back

			bne		noRam			; No ram at the location just tested

			tfr		x,y				; Stash memory start in Y

ramOk		leax	1,x			    ; Now see how far the memory extends...
			sta		,x				; Write byte and see if...
			cmpa	,x				; ...we can read it back

			beq		ramOk			; branch if we read ok

; we have hit the end of memory
			tfr		x,s				; Setup the system stack
			leau	-1,x

			leax	WelcomeMsg,pcr
			lbsr	pStr			; say hello

			leax	memMsg,pcr		; Report on memory
			lbsr	pStr

			tfr		y,d				; print memory start
			lbsr	p4hex

			lda		#'-
			lbsr	pChar

			tfr		u,d
			lbsr	p4hex

			lbsr	pNL
            
cmdLoop 	lbsr	pNL

			leax	cmdPrompt,pcr
			lbsr	pStr

			lbsr	gChar			; get a command

			cmpa	#CR
			beq		cmdLoop

			cmpa	#'b				; b-oot command?
			bne		notBoot
			bsr		doBoot
			bra		cmdLoop

notBoot 	cmpa	#'m				; m-emory test
			bne		notMemTest
			lbsr	doMemTest
			bra		cmdLoop

notMemTest	lbsr	pNL
			leax	badCmdMsg,pcr
			lbsr	pStr
			bra		cmdLoop

            
;--------------------------------------------------------------------------------
; noRam - didn't find any ram
;
; on entry:
;
; trashes: everything
;
; returns: nothing
;
noRam		leax	noRamMsg,pcr
			lbsr	pStr
idle		bra		idle


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
            lbsr    pStr
            
			lbsr	loadMBR
			lbsr	pNL
; Check the MBR is valid
			leax	mbrSigMsg,pcr
			lbsr	pStr

			leau    sdBuff,pcr		; point at the real read buffer

			ldd		MbrSig,u		; Look for the Mbr signature
			lbsr	p4hex			; print signature
			lbsr	pNL

; Dump partition table
			lda		#0
			leay	446,u			; Part #1
			lbsr	dPartInfo

			leay	16,y			; Part #2
			inca
			lbsr	dPartInfo

			leay	16,y			; Part #3
			inca
			lbsr	dPartInfo

			leay	16,y			; Part #4
			inca
			lbsr	dPartInfo

			lda		#1				; # of partitions to check
            ldx     #0
			leay	446,x			;
btChk		ldb		4,y				;
			cmpb	#6				; FAT16 partition?
            beq     itsFAT
			lbra	notFAT

; extract info about partition size
itsFAT      leay    8,y             ; First sector LBA
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
            leax    foundFATMsg,pcr
            lbsr    pStr
            
            adda    #'0
            lbsr    pChar
            
            lbsr    pNL
            
; Take a look at the FAT16 boot record
            leax    partStartMsg,pcr
            lbsr    pStr
            
            leax    partStart,pcr
            lbsr    pLBA
            lbsr    pNL
            
            leay    sdBuff,pcr
            lbsr    rdBlock
            
; Check it looks like a boot sector
            ldd     510,y
            lbsr    p4hex
            lbsr    pNL
            
            cmpd    #$55aa          ; Good sig?
            lbne     badBootBlk
            
            leax    volMsg,pcr
            lbsr    pStr
            
            leax    $2b,y           ; Volume label - 11 bytes
            ldb     #11
            lbsr    pnStr
            lbsr    pNL
            
; Calculate the LBA of start of FAT #1. Add in the number of reserved sectors to get the LBA of the start
; of FAT #1. #reserved is usually 1
            leax    FATStartMsg,pcr
            lbsr    pStr
            
            leax    FAT_LBA_t,pcr
            lbsr    clearLBA
            
            ldd     14,y            ; # reserved sectors
            exg     a,b
            std     ,x           
            lbsr    logToPhysLBA    
            
            lbsr    pLBA
            lbsr    pNL
            
; Calculate the LBA of the start of the root directory. This is:
;
;   (<number of sectors per FAT> * <number of FATs)) + <start of FAT #1 LBA>
;
            leax    Root_LBA_t,pcr  ; LBA of start of root directory
            lbsr    clearLBA
            
            ldd     22,y            ; # sectors per FAT
            exg     a,b
            std     ,x
            lda     #'z
            lbsr    pChar
            lbsr    pLBA
            lbsr    pNL
            
            ldd     17,y
            exg     a,b
            std     maxRootEnts,pcr
            
; 1 or 2 FATs?
            lda     16,y            ; # of FATs
            cmpa    #2
            beq     twoFATs
            cmpa    #1
            beq     oneFAT
            bra     badBootBlk
            
twoFATs:    ldd     22,y
            exg     a,b
            std     22,y            ; Truly horrible!
            addd    22,y
            std     ,x
            bcc     twoFATcc
            inc     3,x
twoFATcc    bra     FATSok
            
oneFAT:     ldd     22,y
            exg     a,b
            std     ,x
            bra     FATSok
                        
FATSok
            leay    FAT_LBA_t,pcr
            leax    Root_LBA_t,pcr
            lbsr    addLBAs
            bra     bootBlkOk
            
badBootBlk  leax    bootSecProb,pcr
            lbsr    pStr
            bra     bootOver
            
bootBlkOk   leax    rootStartMsg,pcr
            lbsr    pStr
            
            leax    Root_LBA_t,pcr
            lbsr    pLBA
            lbsr    pNL
            
; All good so far - look in the root directory for a boot file...
            ldy     maxRootEnts,pcr
            
chkDir:     leay    -1,y
            bne     chkDir
            
            leax    noFileMsg,pcr
            lbsr    pStr
            
bootOver
            rts
            
; - populate the DCB

notFAT		leay	16,y			;
			inca					; have we checked all partitions?
            cmpa    #5
			lblt	btChk
            

; No FAT16 partition found
			leax	noFATMsg,pcr
			lbsr	pStr

			rts


;--------------------------------------------------------------------------------
; dPartInfo - display info about a partition
;
; on entry:
;	A - partition number
;	Y - address of partition table entry
;
; trashes: nothing
;
; returns: nothing
;
dPartInfo	pshs	d,x

			lbsr	pNL

			leax	dPartHdr,pcr
			lbsr	pStr
			lbsr	p1hex
			lbsr	pNL

			lda		,y				; status. $80=bootable, $00=not bootable
			lbsr	p2hex
			lbsr	pNL

			lda		4,y				; Partition type
			lbsr	p2hex
			lbsr	pNL

			ldd		10,y				; LBA of first block
            exg     a,b
			lbsr	p4hex
			ldd		8,y
            exg     a,b
			lbsr	p4hex
			lbsr	pNL

			ldd		14,y			; LBA of last block
            exg     a,b
			lbsr	p4hex
			ldd		12,y
            exg     a,b
			lbsr	p4hex
			lbsr	pNL


			puls	x,d,pc

;--------------------------------------------------------------------------------
doMemTest	rts

;--------------------------------------------------------------------------------
;
; Null interrupt handler
;
Nothing		rti


;--------------------------------------------------------------------------------
; loadMBR - read the master boot record from the SD card
;
; on entry:
;
; trashes:
;
; returns:
;
MBRLBA      fdb     0,0                 ; LBA equivalent to $00000000

loadMBR 	pshs	x

			leax    MBRLBA,pcr
			leay    sdBuff,pcr	        ; read buffer pointer
			lbsr	rdBlock

			puls	x,pc				; ...and return

            
;--------------------------------------------------------------------------------
; gChar - fetch a character from the serial port
;
; on entry:
;
; trashes: nothing
;
; returns:
;	A - character read
;
gChar		pshs	x

			leax	Acia,pcr

gCharWait	lda		,x
			bita	#1				; rx register full?
			beq		gCharWait

			lda		1,x				; grab the character

			puls	x,pc


;--------------------------------------------------------------------------------
; pChar - print a character
;
; on entry:
;	 A - character to print
;
; trashes: nothing
;
; returns: nothing
;
pChar		pshs	x
			pshs	a

			leax	Acia,pcr

pCharWait	lda		,x
			bita	#2				; tx register empty?
			beq		pCharWait

			puls	a
			sta		1,x				; send the char

			puls	x,pc


;--------------------------------------------------------------------------------
; pStr - print EOS terminated string
;
; on entry:
;	 X - address of string
;
; trashes: nothing
;
; returns: nothing
;
pStr		pshs	a

pStrNext	lda		,x+
			beq		pStrEnd

			bsr		pChar
			bra		pStrNext

pStrEnd 	puls	a,pc


;--------------------------------------------------------------------------------
; pnStr - print n bytes of a string
;
; on entry:
;    B - number of bytes
;	 X - address of string
;
; trashes: B,X
;
; returns: nothing
;
pnStr		pshs	a

            cmpb    #0
            beq     pnStrEnd
            
pnStrNext   lda		,x+

			bsr		pChar
            decb
            beq     pnStrEnd
			bra		pnStrNext

pnStrEnd 	puls	a,pc


;--------------------------------------------------------------------------------
; pLBA - print a LBA as hex
;
; on entry:
;	 X - Pointer to LBA
;
; trashes: nothing
;
; returns: nothing
;
pLBA		pshs	d

            ldd     2,x
			bsr		p4hex	; print upper word
			ldd     ,x
			bsr		p4hex	; print lower word

			puls	d
			rts


;--------------------------------------------------------------------------------
; p4hex - print a word as hex
;
; on entry:
;	 D - word to print
;
; trashes: nothing
;
; returns: nothing
;
p4hex		pshs	d

			bsr		p2hex	; print upper byte
			tfr		b,a
			bsr		p2hex	; print lower byte

			puls	d
			rts


;--------------------------------------------------------------------------------
; p2hex - print a byte as hex
;
; on entry:
;	 A - byte to print
;
; trashes: nothing
;
; returns: nothing
;
p2hex  		pshs	a
			pshs	a

			lsra			; upper nibble first
			lsra
			lsra
			lsra

			bsr		p1hex	; print upper nibble
			puls	a
			bsr		p1hex	; print lower nibble

			puls	a,pc



;--------------------------------------------------------------------------------
; p1hex - print a nibble as hex
;
; on entry:
;	 A - nibble to print - low 4 bits
;
; trashes: A
;
; returns: nothing
;
p1hex		anda	#$0f
			cmpa	#10
			blt		p1hexNum

			suba	#10
			adda	#'A
			bra		p1hexPr

p1hexNum	adda	#'0

p1hexPr 	bsr		pChar

			rts

;--------------------------------------------------------------------------------
; pNL
;
; on entry:
;
; trashes: nothing
;
; returns: nothing
;
pNL 		pshs	a

			lda		#CR
			bsr		pChar

			lda		#LF
			bsr		pChar

			puls	a,pc

;--------------------------------------------------------------------------------
; clearLBA - reset the LBA
;
; on entry:
;	X - LBA_t*
;
; trashes: nothing
;
; returns: nothing
;
clearLBA    pshs    a

            lda     #0
            sta     ,x
            sta     1,x
            sta     2,x
            sta     3,x
                        
            puls    a,pc                ; restore...and return


;--------------------------------------------------------------------------------
; addLBAs - add two LBAs together
;
; on entry:
;	X - LBA_t* #1
;   Y - LBA_t* #2
;
; trashes: Y
;
; returns:
;   X - LBA_t* #1 - now #1 + #2
;
addLBAs     pshs    d

            lbsr    pLBA
            lda     #'+
            lbsr    pChar
            pshs    x
            tfr     y,x
            lbsr    pLBA
            lda     #'=
            lbsr    pChar
            lbsr    pNL
            puls    x
            
            ldd     ,x
            addd    ,y
            std     ,x
            bcc     abNoOv
       
            ldd     2,x
            addd    #1
            std     2,x
            
abNoOv:     ldd     2,x
            addd    2,y
            std     2,x

            puls    d,pc              ; restore...and return


;--------------------------------------------------------------------------------
; logToPhysLBA - convert the logical sector to a physical sector
;
; on entry:
;	X - LBA_t*
;
; trashes: nothing
;
; returns: nothing
;
logToPhysLBA
            pshs    y

            leay    partStart,pcr
            lbsr    addLBAs
                        
            puls    y,pc                ; restore...and return


;--------------------------------------------------------------------------------
; setLBA - set the LBA to read/write
;
; on entry:
;	X - LBA_t*
;
; trashes: nothing
;
; returns: nothing
;
setLBA      pshs    y,a

            leay    SDCard,pcr
            lda     1,x
            sta     sdLBA0,y
            lbsr    p2hex
            
            lda     #'-
            lbsr    pChar
            
            lda     ,x
            sta     sdLBA1,y
            lbsr    p2hex
            
            lda     #'-
            lbsr    pChar
            
            lda     3,x
            sta     sdLBA2,y
            lbsr    p2hex
            
            lda     #'-
            lbsr    pChar
            
            lda     #00                 ; SD card only uses 3 bytes of LBA
            sta     sdLBA3,y
            lbsr    p2hex
            lbsr    pNL
            
            puls    y,a,pc              ; restore...and return

;--------------------------------------------------------------------------------
; rdBlock - read block from the SD card
;
; on entry:
;	Y - Pointer to read buffer
;	X - LBA_t*
;
; trashes: A,X
;
; returns:
;
rdBlock 	pshs	u,y,b

			leau	SDCard,pcr			; base of sd controller

rdWtRdy 	ldb		sdStatus,u			; Wait for SD card to be ready
			cmpb	#128
			bne		rdWtRdy

            bsr    setLBA
            
			lda		#00					; $00 = read block command
			sta		sdCtrl,u			;

			ldx		#512				; number of bytes to read

rdWait 		ldb		sdStatus,u			; Wait for byte to be available
			cmpb	#224				; Byte ready
			bne		rdWait

			lda		sdData,u			; read the byte

			sta		,y+					; save byte to buffer
			leax	-1,x				; x--
			bne		rdWait				; loop until 512 bytes read

			puls	b,y,u,pc			; restore regs...and return



;--------------------------------------------------------------------------------
; wrBlock - read block from the SD card
;
; on entry:
;	Y - Pointer to read buffer
;	X - LBA_t*
;
; trashes: A,X
;
; returns:
;
wrBlock 	pshs	u,y,b

			leau	SDCard,pcr			; base of sd controller

wrWtRdy 	ldb		sdStatus,u			; Wait for SD card to be ready
			cmpb	#128
			bne		wrWtRdy

            bsr     setLBA              ; specify the sector to write
			lda		#01					; $01 = write block command
			sta		sdCtrl,u			;

			ldx		#512				; number of bytes to read

wrWait 		ldb		sdStatus,u			; Wait for byte to be available
			cmpb	#160				; Write buffer empty
			bne		wrWait

			lda		,y+					; read the byte
			sta		sdData,u			; Write it

			leax	-1,x				; x--
			bne		wrWait				; loop until 512 bytes written

			puls	b,y,u,pc			; restore regs...and return


;--------------------------------------------------------------------------------
; swiVec - handle a software interrupt BIOS call
;
; on entry:
;
; trashes: nothing
;
; returns: nothing
;
swiVec		ldu		10,s				; U points at the return address

            lda     ,u                  ; ld fn code
            
			leau	1,u					; Modify the return address to skip over
										; the fn byte following SWI instruction
			stu		10,s				; Put the modified return address back on the stack
            
            cmpa    #0
            blt     SWIOOB
            cmpa    #1
            bgt     SWIOOB
            
            asla                        ; Calculate offset into jump table
            leau    SWITable,pcr
            ldd     a,u
            jmp     d,u
            
SWITable:   fdb     SWI0-SWITable
            fdb     SWI1-SWITable
            
SWIOOB:     rti                         ; Function code was out of bounds - just return

SWI0:       lda     #'A
            lbsr    pChar
            rti

SWI1:       lda     #'Z
            ;lbsr    pChar
            rti

            
WelcomeMsg	fcb		CR,LF,LF
			fcc		"6809 monitor."
            fcb     CR,LF,LF
            fcc     "Copyright (c) Bob Green, 2016"
			fcb		CR,LF,EOS

mbrSigMsg	fcc		"MBR signature: "
			fcb		EOS

memMsg		fcc		"RAM: "
			fcb		EOS

noRamMsg	fcc		"Couldn't find any ram!"
			fcb		EOS

cmdPrompt	fcc		"> "
			fcb		EOS

badCmdMsg	fcc		"Unrecognised command."
			fcb		CR,LF,EOS

noFATMsg	fcc		"No FAT16 partition found to boot from."
			fcb		CR,LF,EOS
            
dPartHdr	fcc		"Partition number "
			fcb		EOS
            
foundFATMsg fcc     "Found FAT16B partition (type 6) in partition slot #"
            fcb     EOS
            
bootSecMsg  fcc     "FAT16 Boot sector:"
            fcb     CR,LF,EOS
            
bootSecProb fcc     "Bad FAT16 boot block"
            fcb     CR,LF,EOS
            
volMsg      fcc     "Volume label: "
            fcb     EOS
            
ldMBRMsg    fcc     "Loading MBR..."
            fcb     EOS
            
partStartMsg
            fcc     "Partition start LBA: "
            fcb     EOS
            
FATStartMsg fcc     "FAT #1 start LBA: "
            fcb     EOS
            
rootStartMsg
            fcc     "Root directory start LBA: "
            fcb     EOS
            
noFileMsg   fcc     "No boot file found"
            fcb     CR,LF,EOS

            
zzz         fdb     $dead
            
            

;--------------------------------------------------------------------------------
; Pad out rest of ROM
Empty		equ		ROMBeg+ROMSize-16
			fill	$FF, Empty-*

			fdb		Nothing				; Reserved
			fdb		Nothing				; SWI3
			fdb		Nothing				; SWI2
			fdb		Nothing				; FIRQ
			fdb		Nothing				; IRQ
			fdb		swiVec				; SWI
			fdb		Nothing				; NMI
			fdb		RESET				; Hard reset vector
