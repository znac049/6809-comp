SRCS=		$(wildcard *.asm)

.PHONY:		all clean test

all:		boot.s9

boot.s9:	$(SRCS)
		lwasm --format=srec --map=boot.map --list=boot.lst --output=boot.s9 boot.asm

clean:
		rm -f *~ *.hex *.s9 *.srec *.lst *.bin *.o *.out a.out


