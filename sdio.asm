SDCard		equ	$ffd8
sdData		equ	0
sdCtrl		equ	1
sdStatus	equ	1
sdLBA0		equ	2
sdLBA1		equ	3
sdLBA2		equ	4
sdLBA3		equ     5



;--------------------------------------------------------------------------------
; dirent - FAT16 directory entry
;
dirent		struct
name		rmb	8
ext		rmb	3
attrib		rmb	1
reserved	rmb	1
creation	rmb	5
accessed	rmb	2
reserved2	rmb	2
lastwrite	rmb	4
cluster		rmb	2
size		rmb	4
		endstruct

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
	
		leau	SDCard,pcr		; base of sd controller

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

		leau	SDCard,pcr		; base of sd controller

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


