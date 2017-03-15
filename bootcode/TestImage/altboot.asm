		pragma	6809

Uart0Base	equ	$FF00
StatusReg	equ	0
DataReg		equ	1



		org	$2800

		jmp	start
		fcb	'B','G'

start		orcc	#$ff	; disable interrupts
		lds	#$2800	; safe stack

		ldu	#spinner
		
next		lda	,u
		cmpa	#0
		bne	fishOk

		ldu	#spinner
		lda	,u

fishOk		bsr	pChar

		lda	#13
		bsr	pChar

		bsr	bigDelay

		leau	1,u

		bra	next	; loop forever

spinner		fcn	"/-\|"

pChar		pshs	b,x

		ldx	#Uart0Base

@wait		ldb	StatusReg,x
		bitb	#2		; tx register empty?
		beq	@wait
		
		sta	DataReg,x	; send the char

		puls	x,b,pc


bigDelay	ldy	#1
big_loop	bsr	delay
		leay	-1,y
		bne	big_loop
		rts


delay		ldx	#0
delay_loop	leax	1,x
		bne	delay_loop
		rts
