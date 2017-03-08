;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
	
*******************************************************************
* swiHand - handle a software interrupt BIOS call
*
* on entry: A - SWI function code
*
*  trashes: nothing
*
*  returns: function specific results
*

swiHand		ldu	10,s			; U points at the return address
	
		lda     ,u			; ld fn code
		
		leau	1,u			; Modify the return address to skip over
						; the fn byte following SWI instruction
		stu	10,s			; Put the modified return address back on the stack
            
		cmpa    #0
		blt     SWIDone
		cmpa    #SWIMax
		bge     SWIDone
            
		asla				; Calculate offset into jump table
		leau    SWITable,pcr
		ldd     a,u
		jmp     d,u

	
SWITable	fdb     SWI0-SWITable
		fdb     SWI1-SWITable
SWIend		equ	*
SWIMax		equ	(SWIend-SWITable)/2
SWIDone		rti				; Function code was out of bounds - just return

SWI0:		lda     #'A
		bsr    pChar
		rti

SWI1:		lda     #'Z
		rti
