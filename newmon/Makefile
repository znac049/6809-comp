SRC=newmon.asm serio.asm sdio.asm fat16.asm output.asm

INSTALLDIR=/cygdrive/c/Users/bob/OneDrive/Projects/multicomp/ROMS/6809

all:		newmon.hex

newmon.hex:	newmon.srec
		m2i <newmon.srec >newmon.hex

newmon.s19:	$(SRC)
		lwasm --6809 --format=obj --output=newmon.o newmon.asm
		lwlink --entry=RESET --format=srec --output=newmon.srec newmon.o

clean:
		rm *~ *.hex *.s19 *.lst

install:	newmon.hex newmon.vhd
		cp newmon.hex $(INSTALLDIR)/newmon.hex
		cp newmon.vhd $(INSTALLDIR)/newmon.s19
