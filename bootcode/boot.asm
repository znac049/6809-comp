;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
		pragma	autobranchlength
		pragma	cescapes

		pragma	6809	; Just while we are testing with 6809 hardware

* Set to 1 if this is being assembled as a boot rom
BOOTROM		= 0


		include "const.asm"
 IFNE BOOTROM
		org	$0
 ELSE
		org	$400
 ENDC



		include "vars.asm"

 IFNE BOOTROM
		org	$e000
 ELSE
		org	$c000
 ENDC


*************************************************************

Start		equ	*

; Hard reset
;

RESET
		clra
		tfr	a,dp		; DP is page 0
             
; Minimal serial IO
*		ldx	#Uart0Base 
*		lda	#$03		; Master reset
*		sta	StatusReg,x
*		lda	#$15		; 8N1, div by 16
*		sta	StatusReg,x

		leas	Start,pcr	; Initial stack

		leax	WelcomeMsg,pcr
		bsr	pStr		; say hello

* See how much RAM we have
		bsr	quickMemCheck
		leax	MemoryMsg,pcr
		bsr	pStr
		ldd	ramEnd
		bsr	p4hex
		bsr	pNL
				
		bsr	dkInit		; Initialise disk(s)

		leax	CommandMsg,pcr
		bsr	pStr

cmdLoop		lda	#'.'
		bsr	pChar
		ldx	#line
		lda	#MAXLINE
		bsr	getLine

		leax	cmdTable,pcr
		bsr	findCmd

		cmpa	#0
		beq	unkCmd

		leax	cmdLoop,pcr
		pshs	x

		pshs	d		; Bit of stack magic
		puls	pc
	
unkCmd		leax	unknownCmd,pcr
		bsr	pStr
		bra	cmdLoop

	
WelcomeMsg	fcc	"\r\n\n6809/6309 SBC.\r\n\n"
        	fcn     "Copyright (c) Bob Green, 2016\r\n\n"

MemoryMsg	fcn	"Memory size: "

CommandMsg	fcn	"Type 'help' for a list of commands\r\n\n"

unknownCmd	fcn	"Unknown command.\r\n"


* Non-destructive memory check. Doesn't do the full works, just
* tests for simple write-read. If this monitor is running in RAM,
* make sure we don't overwrite!
quickMemCheck   ldd     #ROMBase
	       	cmpd  	Start
	       	bge   	InROM
	       	ldd   	Start
InROM
		std	ramEnd	; Do not test beyond this point

		DBGL	'R'
	
		ldx	#0	; Address to start testing from

		orcc	#$ff	; no interrupts while we test, in case
				; any of the interrupt handlers use RAM
				; that we are temporarily changing.


		lda	#$55
doQuickByte	
		ldb	,x	; Take copy of ram at X
		pshs	b
	
* Display the address being tested
		tfr	x,d	

		sta	$ff71
		stb	$ff73
		
		lsra
		lsra
		lsra
		lsra
		sta	$ff70
		
		lsrb
		lsrb
		lsrb
		lsrb
	
		stb	$ff72

		lda	#$55
		sta	,x	; Write our test pattern
		eora	,x	; result should be 0
		bne	doQuickEnd

		puls	b	; restore old value
		stb	,x+
	
		cmpx	ramEnd
		bne	doQuickByte

doQuickEnd
		stx	ramEnd
	
		rts


* Pull in all the other good stuff(tm)

       	      	include "lib.asm"
		include	"conio.asm"
		include "dkio.asm"
		include "sdio.asm"
		include "cfio.asm"
		include "commands.asm"
		include "os9fs.asm"
		include "swihand.asm"
;

 IFNE BOOTROM

		include "vectors.asm"
 ENDC