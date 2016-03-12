SDCard		equ	$ffd8
sdData		equ	0
sdCtrl		equ	1
sdStatus	equ	1
sdLBA0		equ	2
sdLBA1		equ	3
sdLBA2		equ	4
sdLBA3		equ     5

;--------------------------------------------------------------------------------
; pte - partition table entry
;
pte		struct
stat		rmb	1
startchs	rmb	3
type		rmb	1
endchs		rmb	3
startlba	rmb	4
endlba		rmb	4
		endstruct

;--------------------------------------------------------------------------------
; mbr - master boot record
;
mbr		struct
code1		rmb	218
zero		rmb	2
phys		rmb	1
secs		rmb	1
mins		rmb	1
hours		rmb	1
code2		rmb	216
dsig		rmb	4
prot		rmb	2
pt		pte
pt2		pte
pt3		pte
pt4		pte
sig		rmb	2			; Expect $55AA
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


