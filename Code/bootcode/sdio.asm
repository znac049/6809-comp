;--------------------------------------------------------------------------------

sdCard		equ	$ffd8			; SD controller base address
sdData		equ	0			; data register
sdCtrl		equ	1
sdStatus	equ	1
sdLBA0		equ	2
sdLBA1		equ	3
sdLBA2		equ	4
sdLBA3		equ     5


;--------------------------------------------------------------------------------
; rdBlock - read block from the SD card
;
; on entry:
;	Y - Pointer to read buffer
;	X - LBA_t*
;
; trashes: A,X
;
; returns:
;
rdBlock		pshs	u,y,b
	
		leau	sdCard,pcr		; base of sd controller

rdWtRdy 	ldb	sdStatus,u		; Wait for SD card to be ready
		cmpb	#128
		bne	rdWtRdy

		bsr    setLBA
            
		lda	#00			; $00 = read block command
		sta	sdCtrl,u		;

		ldx	#512			; number of bytes to read

rdWait 		ldb	sdStatus,u		; Wait for byte to be available
		cmpb	#224			; Byte ready
		bne	rdWait

		lda	sdData,u		; read the byte

		sta	,y+			; save byte to buffer
		leax	-1,x			; x--
		bne	rdWait			; loop until 512 bytes read

		puls	b,y,u,pc		; restore regs...and return



;--------------------------------------------------------------------------------
; wrBlock - read block from the SD card
;
; on entry:
;	Y - Pointer to read buffer
;	X - LBA_t*
;
; trashes: A,X
;
; returns:
;
wrBlock 	pshs	u,y,b

		leau	sdCard,pcr		; base of sd controller

wrWtRdy 	ldb	sdStatus,u		; Wait for SD card to be ready
		cmpb	#128
		bne	wrWtRdy

		bsr     setLBA			; specify the sector to write
		lda	#01			; $01 = write block command
		sta	sdCtrl,u		;

		ldx	#512			; number of bytes to read

wrWait 		ldb	sdStatus,u		; Wait for byte to be available
		cmpb	#160			; Write buffer empty
		bne	wrWait

		lda	,y+			; read the byte
		sta	sdData,u		; Write it

		leax	-1,x			; x--
		bne	wrWait			; loop until 512 bytes written

		puls	b,y,u,pc		; restore regs...and return


;--------------------------------------------------------------------------------
; loadMBR - read the master boot record from the SD card. This is to be found
;	    on block #0. 
;
; on entry:
;	Y - address of buffer to read into
;
; trashes:
;
; returns:
;	CC.Z - indicates zero if MBR contains valid signature
;
MBRLBA		fqb     0			; LBA equivalent to $00000000

loadMBR 	pshs	x,d

		leax    MBRLBA,pcr
		bsr	rdBlock


		puls	x,d,pc			; ...and return

            
;--------------------------------------------------------------------------------
; clearLBA - reset the LBA
;
; on entry:
;	X - LBA_t*
;
; trashes: nothing
;
; returns: nothing
;
clearLBA	pshs    a

		lda     #0
		sta     ,x
		sta     1,x
		sta     2,x
		sta     3,x
                        
		puls    a,pc			; restore...and return


;--------------------------------------------------------------------------------
; setLBA - set the LBA to read/write
;
; on entry:
;	X - LBA_t*
;
; trashes: nothing
;
; returns: nothing
;
setLBA		pshs    y,a

		leay    sdCard,pcr
		lda     1,x
		sta     sdLBA0,y
            
		lda	,x
		sta     sdLBA1,y
            
		lda     3,x
		sta     sdLBA2,y
            
		lda     #00			; SD card only uses 3 bytes of LBA
		sta     sdLBA3,y
		bsr	p2hex
            
		puls    y,a,pc			; restore...and return

