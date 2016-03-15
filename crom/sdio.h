#ifndef _SDIO_H_
#define _SDIO_H_

#define SD_ADDR 0xffd8
#define SD_DATA 0
#define SD_CR 1
#define SD_SR 1
#define SD_LBA0 2
#define SD_LBA1 3
#define SD_LBA2 4
#define SD_LBA3 5

#define SD_READ_CMD 0

typedef struct {
  char lba[4];
} lba_t;

extern void initSD();
extern int readBlock(lba_t *, char *s);

#endif
