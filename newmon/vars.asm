sdBuff		equ	0		; 512 bytes

partStart	equ	sdBuff+512 	; 4 bytes - LBA
partSize	equ	partStart+4	; 4 bytes
FATLBA		equ	partSize+4	; 4 bytes
RootLBA		equ	FATLBA+4	; 4 bytes
maxRootEnts	equ	RootLBA+4	; 2 bytes
