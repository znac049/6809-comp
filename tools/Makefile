INSTALL_DIR=/usr/local/coco/bin

all: dr2i m2i

dr2i: dr2i.c
	gcc -o dr2i dr2i.c

m2i: m2i.c
	gcc -o m2i m2i.c

install: all
	cp m2i dr2i $(INSTALL_DIR)
