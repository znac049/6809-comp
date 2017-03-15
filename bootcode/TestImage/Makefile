DISKNAME=Bilbo
#DISKSIZE=10000
DISKSIZE=640
IMAGEFILE=cfdisk0-0.dsk

all: format copy

boot.bin: boot.asm
	lwasm --format=raw --output=boot.bin boot.asm

altboot.bin: altboot.asm
	lwasm --format=raw --output=altboot.bin altboot.asm

copy:	boot.bin altboot.bin
	os9 copy boot.asm $(IMAGEFILE),boot.asm
	os9 copy altboot.asm $(IMAGEFILE),altboot.asm
#	os9 copy hamlet.txt $(IMAGEFILE),hamlet.txt
	os9 gen -b=altboot.bin $(IMAGEFILE)

format:
	os9 format -e -n$(DISKNAME) -l$(DISKSIZE) $(IMAGEFILE)
