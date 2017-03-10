DISKNAME=Bilbo
#DISKSIZE=10000
DISKSIZE=640
IMAGEFILE=cfdisk0-0.dsk

all: format copy

boot.bin: boot.asm
	lwasm --format=raw --output=boot.bin boot.asm

copy:	boot.bin
	os9 copy boot.asm $(IMAGEFILE),boot.asm
#	os9 copy hamlet.txt $(IMAGEFILE),hamlet.txt
	os9 gen -b=boot.bin $(IMAGEFILE)

format:
	os9 format -e -n$(DISKNAME) -l$(DISKSIZE) $(IMAGEFILE)
