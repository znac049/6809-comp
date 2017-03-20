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

	
*******************************************************************
* printable - ensure char can be printed in ascii
*
* on entry: A - char to convert
*
*  returns: A - converted char
*

printable	cmpa	#' '
		blt	printable_not
		cmpa	#126
		blt	printable_ok
printable_not	lda	#'.'
printable_ok	rts



*******************************************************************
* atow - convert string to word
*
* on entry: Y - char *str  - string to convert
*	    A - max number of chars to convert. If zero, keep going
*	        until non convertable character found
*
*  returns: Y - the converted value
*  	    A - number of characters converted
*

atow		pshs	b,x
		

		leas	-4,s		; Local vars
		sta	2,s		; max chars to convert
		ldd	#0		; 
		std	,s		; result
		sta	3,s		; conversion count

atow_Next
		lda	,y+		; grab the next char in the string
		bsr	hexval
		bcs	atow_notHex
* valid conversion - shift it into the quad
  		tfr     d,x   	        ; temp
  		   
  		ldd     ,s
  		lslb
		rola

		lslb
		rola

		lslb
		rola

		lslb
		rola
		
		andb	#$f0
		std	,s

		tfr	x,d
		ora	1,s
		sta	1,s

		ldb	3,s		; count++
		incb
		stb	3,s

		tst	2,s		; If max is 0, just loop
		beq	atow_Next

		cmpb	2,s		; max chars?
		blt	atow_Next	; No, try for another

atow_notHex	
		ldy	,s		; return res
		lda	3,s
		leas	4,s		; Bin all local variables		

		puls	x,b,pc



