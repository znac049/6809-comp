#include "monitor.h"
#include "sdio.h"

void initSD() {
  volatile char *sd = (char *) SD_ADDR;
}

int readBlock(lba_t *lba, char *buff) {
  volatile char *sd = (char *) SD_ADDR;
  int i;

  while (sd[SD_SR] != 128) {
    ;
  }

  sd[SD_CR] = SD_READ_CMD;

  for (i=0; i<512; i++) {
    while (sd[SD_SR] != 224) {
      ;
    }

    *buff++ = sd[SD_DATA];
  }

  return SUCCESS;
}
