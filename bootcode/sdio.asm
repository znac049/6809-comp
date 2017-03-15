;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
	

;--------------------------------------------------------------------------------
; sdRdBlock - read block from the SD card
;
; on entry:
;	X - byte *buff - read buffer
;	Y - byte *LBA
;
sdRdBlock	pshs	a,x,u,y,b
	
		leau	SDBase,pcr		; base of sd controller

rdWtRdy 	ldb	SD.Status,u		; Wait for SD card to be ready
		cmpb	#128
		bne	rdWtRdy

		bsr    	setLBA
            
		lda	#00			; $00 = read block command
		sta	SD.Ctrl,u		;

		ldy	#512			; number of bytes to read

rdWait 		ldb	SD.Status,u		; Wait for byte to be available
		cmpb	#224			; Byte ready
		bne	rdWait

		lda	SD.Data,u		; read the byte

		sta	,x+			; save byte to buffer
		leay	-1,y			; y--
		bne	rdWait			; loop until 512 bytes read

		puls	b,y,u,x,a,pc		; restore regs...and return



;--------------------------------------------------------------------------------
; sdWrBlock - read block from the SD card
;
; on entry:
;	X - byte *buff - write buffer
;	Y - byte *LBA
;
; returns:
;
sdWrBlock	pshs	u,x,y,a,b

		leau	SDBase,pcr		; base of sd controller

wrWtRdy 	ldb	SD.Status,u		; Wait for SD card to be ready
		cmpb	#128
		bne	wrWtRdy

		bsr     setLBA			; specify the sector to write
		lda	#01			; $01 = write block command
		sta	SD.Ctrl,u		;

		ldy	#512			; number of bytes to read

wrWait 		ldb	SD.Status,u		; Wait for byte to be available
		cmpb	#160			; Write buffer empty
		bne	wrWait

		lda	,x+			; read the byte
		sta	SD.Data,u		; Write it

		leay	-1,y			; y--
		bne	wrWait			; loop until 512 bytes written

		puls	b,a,y,x,u,pc		; restore regs...and return


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
;	Y - byte *LBA
;
; trashes: nothing
;
; returns: nothing
;
setLBA		pshs    x,a

		leax    SDBase,pcr
		lda     3,y
		sta     SD.LBA0,x
            
		lda	2,y
		sta     SD.LBA1,x
            
		lda     1,y
		sta     SD.LBA2,x
            
		lda     #00			; SD card only uses 3 bytes of LBA
		sta     SD.LBA3,x
            
		puls    x,a,pc			; restore...and return



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

		lda	,x
		lsra
		sta	,y

		lda	1,x
		rora
		sta	1,y

		lda	2,x
		rora
		sta	2,y

		lda	3,x
		rora
		sta	3,y		

		puls	a,pc
