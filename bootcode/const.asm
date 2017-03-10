DBGS		macro
		pshs	a

		lda	#' '
		bsr	pChar

		lda	#\1
		bsr	pChar

		lda	#'='
		bsr	pChar

		lda	,s
		bsr	p2hex
		
		lda	#' '
		bsr	pChar

		puls	a
		endm


DBGL		macro
		pshs	d

		lda	#' '
		bsr	pChar

		lda	#\1
		bsr	pChar

		lda	#'='
		bsr	pChar

		ldd	,s
		bsr	p4hex
		
		lda	#' '
		bsr	pChar

		puls	d
		endm


RAMBase		equ	$0000
ROMBase		equ	$E000
ROMSize		equ 	8192
Uart0Base	equ	$FF00
CFBase		equ	$FF10
RegBase		equ	$FF30
MMUBase		equ	$FF40
SDBase		equ	$FFD8

; mc6850 Uart registers
StatusReg	equ	0
DataReg		equ	1

; ATA CF device registers
; When CS0 is asserted (low)
CF.Data		equ	0	; R/W
CF.Error	equ	1	; Read
CF.Features	equ 	1	; Write
CF.SecCnt	equ	2	; R/W
CF.LSN0		equ	3	; R/W - bits  0-7
CF.LSN1		equ	4	; R/W - bits  8-15
CF.LSN2		equ	5	; R/W - bits 16-23
CF.LSN3		equ	6	; R/W - bits 24-27
CF.Status	equ	7	; Read
CF.Command	equ	7	; Write

; Status register
SR.BSYMask	equ	$80
SR.DRDYMask	equ	$40
SR.DFMask	equ	$20
SR.DSCMask	equ	$10
SR.DRQMask	equ	$08
SR.CORRMask	equ	$04
SR.IDXMask	equ	$02
SR.ERRMask	equ	$01

; Commands
CMD.RESET	equ	$04
CMD.IDENTIFY	equ	$EC
CMD.READLONG	equ	$22
CMD.WRITELONG	equ	$32
CMD.DIAG	equ	$90
CMD.IDENTIFYDEV	equ	$ec
CMD.SETFEATURES	equ	$EF

; When CS1 is asserted (low)
CF.AltStatus	equ	22	; Read
CF.DevControl	equ	22	; Write

; SD Controller registers
SD.Data		equ	0			; data register
SD.Ctrl		equ	1
SD.Status	equ	1
SD.LBA0		equ	2
SD.LBA1		equ	3
SD.LBA2		equ	4
SD.LBA3		equ     5



BS		equ	8
CR		equ	13
LF		equ	10
DEL		equ	127

MAXLINE		equ	128
SECSIZE		equ	512
