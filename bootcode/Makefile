SRCS=		$(wildcard *.asm)
EMULATE=	/home/bob/bin/em09

.PHONY:		all clean emu

all:		boot.s9

boot.s9:	$(SRCS)
		lwasm --format=srec --map=boot.map --list=boot.lst --output=boot.s9 boot.asm

clean:
		rm -f *~ *.hex *.s9 *.srec *.lst *.bin *.o *.out a.out

emu:		boot.s9
		conv --input-file=boot.s9 --from-format=srec --output-file=boot.bin --to-format=raw --start-address=0xe000 --end-address=0xffff
		$(EMULATE) -s gtron -b boot.bin

