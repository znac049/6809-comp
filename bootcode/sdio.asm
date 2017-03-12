;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
	

;--------------------------------------------------------------------------------
; sdRdBlock - read block from the SD card
;
; on entry:
;	Y - Pointer to read buffer
;	X - LBA_t*
;
; trashes: A,X
;
; returns:
;
sdRdBlock	pshs	u,y,b
	
		leau	SDBase,pcr		; base of sd controller

rdWtRdy 	ldb	SD.Status,u		; Wait for SD card to be ready
		cmpb	#128
		bne	rdWtRdy

		bsr    	setLBA
            
		lda	#00			; $00 = read block command
		sta	SD.Ctrl,u		;

		ldx	#512			; number of bytes to read

rdWait 		ldb	SD.Status,u		; Wait for byte to be available
		cmpb	#224			; Byte ready
		bne	rdWait

		lda	SD.Data,u		; read the byte

		sta	,y+			; save byte to buffer
		leax	-1,x			; x--
		bne	rdWait			; loop until 512 bytes read

		puls	b,y,u,pc		; restore regs...and return



;--------------------------------------------------------------------------------
; sdWrBlock - read block from the SD card
;
; on entry:
;	Y - Pointer to read buffer
;	X - LBA_t*
;
; trashes: A,X
;
; returns:
;
sdWrBlock	pshs	u,y,b

		leau	SDBase,pcr		; base of sd controller

wrWtRdy 	ldb	SD.Status,u		; Wait for SD card to be ready
		cmpb	#128
		bne	wrWtRdy

		bsr     setLBA			; specify the sector to write
		lda	#01			; $01 = write block command
		sta	SD.Ctrl,u		;

		ldx	#512			; number of bytes to read

wrWait 		ldb	SD.Status,u		; Wait for byte to be available
		cmpb	#160			; Write buffer empty
		bne	wrWait

		lda	,y+			; read the byte
		sta	SD.Data,u		; Write it

		leax	-1,x			; x--
		bne	wrWait			; loop until 512 bytes written

		puls	b,y,u,pc		; restore regs...and return


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

		leay    SDBase,pcr
		lda     1,x
		sta     SD.LBA0,y
            
		lda	,x
		sta     SD.LBA1,y
            
		lda     3,x
		sta     SD.LBA2,y
            
		lda     #00			; SD card only uses 3 bytes of LBA
		sta     SD.LBA3,y
		bsr	p2hex
            
		puls    y,a,pc			; restore...and return



;--------------------------------------------------------------------------------
; LSN2LBA - convert LSN to LBA
;
; on entry:
;	X - byte *LSN
;	Y - byte *LBA
;
; trashes: nothing
;
; returns: nothing
;
LSN2LBA		pshs	a
		
		codeme		
		
		puls	a,pc
