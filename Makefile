SRC=newmon.asm serio.asm sdio.asm

INSTALLDIR=/cygdrive/c/Users/bob/OneDrive/Projects/multicomp/ROMS/6809

all:		newmon.hex

newmon.hex:	newmon.s19
		m2i <newmon.s19 >newmon.hex

newmon.s19:	$(SRC)
		lwasm --6809 --format=srec --output=newmon.s19 newmon.asm

clean:
		rm *~ *.hex *.s19 *.lst

install:	newmon.hex newmon.vhd
		cp newmon.hex $(INSTALLDIR)/newmon.hex
		cp newmon.vhd $(INSTALLDIR)/newmon.s19
