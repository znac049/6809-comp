SRCS=		$(wildcard *.asm)

.PHONY:		all clean test

all:		bootram.s9

bootram.s9:	$(SRCS)
		lwasm --format=srec --map=bootram.map --list=bootram.lst --output=bootram.s9 bootram.asm
		sed -i -e '/^S0/d' -e '/^S5/d' -e '/^S9/d' bootram.s9

clean:
		rm -f *~ *.hex *.s9 *.srec *.lst *.bin *.o *.out a.out


