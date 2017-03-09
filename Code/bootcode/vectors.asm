;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
		pragma	autobranchlength
		pragma	cescapes

		include "const.asm"

RESET		extern
swiHand		extern

	
		section CSEG

*******************************************************************
* doNothing - null interrupt handler
*
;--------------------------------------------------------------------------------
;
; Null interrupt handler
;
doNothing	rti


		section VECTORS

		fdb	doNothing		; Reserved
		fdb	doNothing		; SWI3
		fdb	doNothing		; SWI2
		fdb	doNothing		; FIRQ
		fdb	doNothing		; IRQ
		fdb	swiHand			; SWI
		fdb	doNothing		; NMI
		fdb	RESET			; Hard reset vector
