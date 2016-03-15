OBJ=crt0.o monitor.o uart.o sdio.o

CC=gcc09
LD=ld09

ROM_BASE='*'
LDFLAGS=-Tvec 

mon:	$(OBJ)
	$(LD) -o mon $(LDFLAGS) $(OBJ)

crt0.o: crt0.S
	$(CC) -o crt0.o crt0.S -c

clean:
	rm *.o mon *~
