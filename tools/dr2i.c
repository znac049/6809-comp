#include <stdio.h>
#include <stdlib.h>

#define OK 0
#define ERR -1

#define MEMSIZE 65536

int base = MEMSIZE-1;
int mem[MEMSIZE];
int lowestAddr = 0xffff;
int highestAddr = 0;

int getWord(FILE *fd) {
  int c1 = fgetc(fd);
  int c2 = fgetc(fd);

  if ((c1 == EOF) || (c2 == EOF)) {
    return -1;
  }

  return (c1<<8) | c2;
}

void poke(int addr, int val) {
  mem[addr] = val;

  if (addr < lowestAddr) {
    lowestAddr = addr;
  }

  if (addr > highestAddr) {
    highestAddr = addr;
  }
}

int processSegment(FILE *fd) {
  int c = fgetc(fd);
  int len = 0;
  int addr = 0;
  int res;
  int i;
  

  if (c == 0xff) {
    len = getWord(fd);
    addr = getWord(fd);

    if ((len != 0) || (addr == -1)) {
      fprintf(stderr, "Badly formatted END segment.\n");
      exit(1);
    }

    res = -1;
  }
  else if (c != 0) {
    fprintf(stderr, "Badly formatted CHUNK type.\n");
    exit(1);
  }
  else {
    len = getWord(fd);
    addr = getWord(fd);

    fprintf(stderr, "len=%04x, addr=%04x\n", len, addr);

    if ((len == -1) || (addr == -1)) {
      fprintf(stderr, "Badly formatted CHUNK segment.\n");
      exit(1);
    }

    if (addr < base) {
      base = addr;
    }
    
    for (i=0; i<len; i++) {
      c = fgetc(fd);

      if (c == EOF) {
	fprintf(stderr, "Unexpected EOF.\n");
	exit(1);
      }

      poke(addr+i, c);

      res = addr;
    }
  }

  return res;
}
int main(int argc, char **argv)
{
  int i;
  int segAddr;
  
  for (i=0; i<MEMSIZE; i++) {
    mem[i] = -1;
  }

  while ((segAddr = processSegment(stdin)) != -1) {
    printf("%04x\n", segAddr);
  }

  printf("Mem: 0x%04x - 0x%04x\n", lowestAddr, highestAddr);
}
