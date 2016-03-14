;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;

		pragma	autobranchlength
		pragma	cescapes

ROMBeg		equ	$E000		;
ROMSize		equ	8192

CR		equ	13
LF		equ	10


	
		section	codeseg
	
		org	ROMBeg

		include	"sdio.asm"
		include "output.asm"
		include "serio.asm"
		include	"fat16.asm"
		include "boot.asm"

;
; Hard reset
;
RESET
RESET		export
	
		lds     #$800			; Safe starting point for stack
            
; Init serial IO
		leau	Acia,pcr

		lda	#$03			; Reset device
		sta	acCtrl,u
	
		lda	#$95			; div 16
		sta	acCtrl,u
            
            
; next thing is find some RAM for our initial stack
;
; Assumptions:
;  1. Ram is a single contiguous chunk
;  2. Ram size is in whole Kbytes
		ldx	#0
		lda	#$5a
            
		lds     #$1000

testRam
		sta	,x			; Write byte and see if...
		cmpa	,x			; ...we can read it back

		bne	noRam			; No ram at the location just tested

		tfr	x,y			; Stash memory start in Y

ramOk		leax	1,x			; Now see how far the memory extends...
		sta	,x			; Write byte and see if...
		cmpa	,x			; ...we can read it back
		beq	ramOk			; branch if we read ok

; we have hit the end of memory
		tfr	x,s			; Setup the system stack
		leau	-1,x

		leax	WelcomeMsg,pcr
		bsr	pStr			; say hello

		leax	memMsg,pcr		; Report on memory
		bsr	pStr

		tfr	y,d			; print memory start
		bsr	p4hex

		lda	#'-
		bsr	pChar

		tfr	u,d
		bsr	p4hex

		bsr	pNL
            
cmdLoop 	bsr	pNL

		leax	cmdPrompt,pcr
		bsr	pStr

		bsr	gChar			; get a command

		cmpa	#CR
		beq	cmdLoop

		cmpa	#'b			; b-oot command?
		bne	notBoot
		bsr	doBoot
		bra	cmdLoop

notBoot 	cmpa	#'m			; m-emory test
		bne	notMemTest
		bsr	doMemTest
		bra	cmdLoop

notMemTest	bsr	pNL
		leax	badCmdMsg,pcr
		bsr	pStr
		bra	cmdLoop

            
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
			bsr	pStr
idle		bra		idle


;--------------------------------------------------------------------------------
; doMemTest - test memory command
;
; on entry:
;
; trashes: everything
;
; returns: nothing
;
doMemTest	rts


;--------------------------------------------------------------------------------
;
; Null interrupt handler
;
Nothing		rti


;--------------------------------------------------------------------------------
; swiVec - handle a software interrupt BIOS call
;
; on entry:
;
; trashes: nothing
;
; returns: nothing
;
swiVec		ldu	10,s			; U points at the return address
	
		lda     ,u			; ld fn code
		
		leau	1,u			; Modify the return address to skip over
						; the fn byte following SWI instruction
		stu	10,s			; Put the modified return address back on the stack
            
		cmpa    #0
		blt     SWIOOB
		cmpa    #1
		bgt     SWIOOB
            
		asla				; Calculate offset into jump table
		leau    SWITable,pcr
		ldd     a,u
		jmp     d,u
            
SWITable:	fdb     SWI0-SWITable
		fdb     SWI1-SWITable
            
SWIOOB:		rti				; Function code was out of bounds - just return

SWI0:		lda     #'A
		bsr    pChar
		rti

SWI1:		lda     #'Z
		;bsr    pChar
		rti

		section	strseg
            
WelcomeMsg	fcc	"\r\n\n6809 monitor.\r\n\n"
        	fcn     "Copyright (c) Bob Green, 2016\r\n"


mbrSigMsg	fcn	"MBR signature: "


memMsg		fcn	"RAM: "


noRamMsg	fcn	"Couldn't find any ram!"


cmdPrompt	fcn	"> "


badCmdMsg	fcn	"Unrecognised command.\r\n"


noFATMsg	fcn	"No FAT16 partition found to boot from.\r\n"

            
dPartHdr	fcn	"Partition number "

            
foundFATMsg 	fcn     "Found FAT16B partition (type 6) in partition slot #"

            
bootSecMsg  	fcn     "FAT16 Boot sector:\r\n"

            
bootSecProb 	fcn     "Bad FAT16 boot block\r\n"

            
volMsg      	fcn     "Volume label: "

            
ldMBRMsg    	fcn     "Loading MBR..."

            
partStartMsg	fcn     "Partition start LBA: "

            
FATStartMsg	fcn     "FAT #1 start LBA: "

            
rootStartMsg	fcn     "Root directory start LBA: "

            
noFileMsg   	fcn     "No boot file found\r\n"


            

;--------------------------------------------------------------------------------
; Pad out rest of ROM
;Empty		equ	ROMBeg+ROMSize-16
	
;		fill	$FF,Empty-*

		section	vecseg

		fdb	Nothing				; Reserved
		fdb	Nothing				; SWI3
		fdb	Nothing				; SWI2
		fdb	Nothing				; FIRQ
		fdb	Nothing				; IRQ
		fdb	swiVec				; SWI
		fdb	Nothing				; NMI
		fdb	RESET				; Hard reset vector
