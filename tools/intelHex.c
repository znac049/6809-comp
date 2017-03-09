#include <stdio.h>
#include <stdlib.h>

#include "intelHex.h"

#define IHEX_BUFLEN 16

static unsigned char outBuff[IHEX_BUFLEN];
static int outInd = 0;
static int outAddr = 0;

void ihexReset() {
  outInd = 0;
  outAddr = 0;
}

void ihexFlush() {
  if (outInd) {
    int xsum = outInd + (outAddr >> 8) + (outAddr & 0xff) + 0;
    int i;

    printf(":%02x%04x00", outInd, outAddr);

    for (i=0; i<outInd; i++) {
      printf("%02x", outBuff[i]);
      xsum = xsum + outBuff[i];
    }

    xsum = -(xsum & 0xff);
    xsum = xsum & 0xff;

    printf("%02x\n", xsum);

    outAddr += outInd;
    outInd = 0;
  }
}

void ihexFinish() {
  ihexFlush();

  printf(":00000001FF\n");
}

void ihexPut(int addr, char val) {
  if (addr < 0) {
    return;
  }

  if (addr != (outAddr + outInd)) {
    ihexFlush();
    outAddr = addr;
  }

  if (outInd >= IHEX_BUFLEN) {
    ihexFlush();
  }

  outBuff[outInd] = val;
  outInd++;
}
