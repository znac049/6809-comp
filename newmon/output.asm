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

pStrNext	lda	,x+
		beq	pStrEnd

		bsr	pChar
		bra	pStrNext

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
            
pnStrNext	lda	,x+

		bsr	pChar
		decb
		beq     pnStrEnd
		bra	pnStrNext

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
		bsr	p4hex			; print upper word
		ldd     ,x
		bsr	p4hex			; print lower word

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

		bsr	p2hex			; print upper byte
		tfr	b,a
		bsr	p2hex			; print lower byte

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

		lsra				; upper nibble first
		lsra
		lsra
		lsra

		bsr	p1hex			; print upper nibble
		puls	a
		bsr	p1hex			; print lower nibble

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
		blt	p1hexNum

		suba	#10
		adda	#'A
		bra	p1hexPr

p1hexNum	adda	#'0

p1hexPr 	bsr	pChar

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

		lda	#CR
		bsr	pChar

		lda	#LF
		bsr	pChar

		puls	a,pc

