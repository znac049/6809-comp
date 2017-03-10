;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;

*******************************************************************
* doNothing - null interrupt handler
*
;--------------------------------------------------------------------------------
;
; Null interrupt handler
;
doNothing	rti


		org	$fff0

		fdb	doNothing		; Reserved
		fdb	doNothing		; SWI3
		fdb	doNothing		; SWI2
		fdb	doNothing		; FIRQ
		fdb	doNothing		; IRQ
		fdb	swiHand			; SWI
		fdb	doNothing		; NMI
		fdb	RESET			; Hard reset vector
