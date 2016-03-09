INSTALLDIR=/cygdrive/c/Users/bob/OneDrive/Projects/multicomp/ROMS/6809

all:		newmon.hex

newmon.hex:	newmon.s19
		m2i <newmon.s19 >newmon.hex

newmon.s19:	newmon.asm
		as9 newmon.asm -s19 now l

clean:
		rm *~ *.hex *.s19 *.lst

install:	newmon.hex newmon.vhd
		cp newmon.hex $(INSTALLDIR)/newmon.hex
		cp newmon.vhd $(INSTALLDIR)/newmon.s19
