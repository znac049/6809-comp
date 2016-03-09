Acia			equ	$FFD0
acCtrl			equ     0
acStatus		equ     0 
acData			equ     1


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
gChar			pshs	x

			leax	Acia,pcr

gCharWait		lda	,x
			bita	#1		; rx register full?
			beq	gCharWait
	
			lda	1,x		; grab the character

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
pChar			pshs	x
			pshs	a

			leax	Acia,pcr

pCharWait		lda	,x
			bita	#2		; tx register empty?
			beq	pCharWait
		
			puls	a
			sta	1,x		; send the char

			puls	x,pc


