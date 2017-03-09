OBJ=crt0.o monitor.o uart.o sdio.o strlen.o strcmp.o

CC=gcc09
LD=ld09

LDFLAGS=-Tvec

all:	mon

-include .depend

mon:	$(OBJ)
	$(LD) -o mon $(LDFLAGS) $(OBJ)

crt0.o: crt0.S
	$(CC) -o crt0.o crt0.S -c

clean:
	rm -f *.o mon *~ .depend

depend:
	$(CC) -MM *.c >.depend
