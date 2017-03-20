;
; Simple 6809 Monitor
;
; Copyright(c) 2016, Bob Green
;
temp		rmb	1
	
cmdFunc		rmb	2

line		rmb	MAXLINE
arg.p		rmb	2	; pointer into command line after the
				; command has been extracted
	
ramEnd		rmb    	2

dumpAddr	rmb	2	; Next address to dump

lsn.p		rmb	4	; The os9 sector number
lba.p		rmb	4	; SD card block number

rootLSN.p	rmb	4	; The start of the root directory
bootLSN.p	rmb	4	; The fisrt LSN of the boot file
bootSize	rmb	2	; Length in bytes of the boot file

* S Records
srType		rmb	1	; The type of the most recent record read
srCount		rmb	1	; The count of the most recent record read
srAddr		rmb	2	; The address to load the next data byte into
srXSum		rmb	1	; The calculated checksum

* Virtual disk subsystem
secBuff		rmb	512

