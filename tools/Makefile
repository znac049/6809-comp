INSTALL_DIR=/usr/local/coco/bin

all: dr2i m2i

-include .depend

dr2i: dr2i.o intelHex.o
	gcc -o dr2i dr2i.o intelHex.o

m2i: m2i.c
	gcc -o m2i m2i.c

install: all
	cp m2i dr2i $(INSTALL_DIR)

clean:
	rm -f *.o dr2i m2i *~ .depend *#

depend:
	$(CC) -MM *.c >.depend
