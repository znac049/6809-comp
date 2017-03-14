;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;


*******************************************************************
* hexval - convert hex encoded char to value
*
* on entry: A - Ascii char to convert
*
*  returns: A - decoded byte value
*  	    CC.C - set if error detected
*

hexval		cmpa	#'0'
		blt	hexval_BadChar
		cmpa	#'9'
		ble	hexval_Num
* Not a number - is it A-F or a-f
      	       	anda    #$df		; Convert to upper case
		cmpa	#'A'
		blt	hexval_BadChar
		cmpa	#'F'
		bgt	hexval_BadChar

* It's in the range A-F
       	      	suba	#'A'
		adda	#10
		bra	hexval_Done

* Its a number
hexval_Num	suba	#'0'
		bra	hexval_Done

hexval_BadChar	orcc	#$01		; Set carry bit
		bra	hexval_Ret

hexval_Done	andcc	#$fe		; Clear carry bit

hexval_Ret	puls 	pc

	
