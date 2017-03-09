;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
		pragma	autobranchlength
		pragma	cescapes

		pragma	6809	; Just while we are testing with 6809 hardware

		include "const.asm"

	
		org	$400
	
temp		rmb	1
	
cmdFunc		rmb	2

line		rmb	MAXLINE
	
secBuff		rmb	SECSIZE

ramEnd		rmb    	2


lsn.p		rmb	4	; The CF sector number

rootLSN.p	rmb	4	; The start of the root directory
bootLSN.p	rmb	4	; The fisrt LSN of the boot file
bootSize	rmb	2	; Length in bytes of the boot file



		org	$c000
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

		bsr	quickMemCheck
		ldd	ramEnd
		bsr	p4hex
		bsr	pNL
				
****		bsr	cfInit		; See if we have a CF device

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
        	fcc     "Copyright (c) Bob Green, 2016\r\n\n"
		fcn	"Memory size: "

unknownCmd	fcn	"Unknown command.\r\n"


		include	"conio.asm"
		include "sdio.asm"
		include "cfio.asm"
		include "commands.asm"
		include "os9fs.asm"
		include "swihand.asm"
;

* Non-destructive memory check. Doesn't do the full works, just
* tests for simple write-read. If this monitor is running in RAM,
* make sure we don't overwrite!

quickMemCheck   ldd     #ROMBase
	       	cmpd  	Start
	       	bge   	InROM
	       	ldd   	Start
InROM
		std	ramEnd	; Do not test beyond this point
	
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
		stb	,x
	
		leax	1,x	; on to the next...
		cmpx	ramEnd
		bne	doQuickByte

doQuickEnd
		stx	ramEnd
	
		rts
