#include <stdio.h>
#include <malloc.h>
#include <string.h>

#define CR  '\r'
#define LF  '\n'
#define EOS '\0'

#define OK 0
#define TOOSHORT -1
#define BADFORMAT -2
#define UNIMPLEMENTED -3
#define BADXSUM -4

struct RECORD {
  int addr;
  int count;
  uint8_t bytes[255];
};

struct RECORD record;

char toLower(char c)
{
  if ((c >= 'A') && (c <= 'Z')) {
    c = c - 'A' + 'a';
  }

  return c;
}

char *strToLower(char *str)
{
  char *res = str;
  
  while (*str) {
    *str = toLower(*str);
    str++;
  }
  
  return res;
}

void stripTerm(char *line, int len)
{
  if (len > 0) {
    len--;

    if (line[len] == LF) {
      line[len] = EOS;

      if (len > 0) {
	len--;

	if (line[len] == CR) {
	  line[len] = EOS;
	}
      }
    }
  }
}

int hexVal(char c)
{
  if ((c >= '0') && (c <= '9')) {
    return c - '0';
  }

  if ((c >= 'a') && (c <= 'f')) {
    return c - 'a' + 10;
  }

  if ((c >= 'A') && (c <= 'F')) {
    return c - 'A' + 10;
  }

  return -1;
}

int convert(char *line, int nChars)
{
  int res = 0;
  int nibble;
  int i;

  for (i=0; i<nChars; i++) {
    nibble = hexVal(line[i]);

    if (nibble == -1) {
      return -1;
    }

    res = (res << 4) | nibble;
  }

  return res;
}

int processSrec(char *line)
{
  int len = strlen(line);
  char recType;
  int count;
  int addr;
  int val;
  int i;
  char *payload;
  int calcSum = 0;
  int xSum;

  // S Records are all at least 10 bytes long
  if (len < 10) {
    return TOOSHORT;
  }

  // Must start with 'S'
  if (line[0] != 'S') {
    return BADFORMAT;
  }

  recType = line[1];

  switch (recType) {
  case '1':
    count = convert(&line[2], 2);
    addr = convert(&line[4], 4);

    if ((count < 3) || (addr == -1)) {
      return BADFORMAT;
    }

    record.count = count-3;
    record.addr  = addr - 0xe000;

    payload = &line[8];
    for (i=0; i<record.count; i++) {
      val = convert(&payload[i+i], 2);
      if (val == -1) {
	return BADFORMAT;
      }

      record.bytes[i] = val;
    }
 
    payload = &line[2];

    xSum = convert(&payload[count+count], 2);
    count--;
    for (i=0; i<=count; i++) {
      int bv = convert(payload, 2);

      payload += 2;
      calcSum += bv;
    }

    calcSum = (~calcSum & 0xff);
    if (calcSum != xSum) {
      printf("\n%08x != %02x\n", calcSum, xSum);

      return BADXSUM;
    }
    
    //printf("\n%d bytes starting at address $%04x - xSum=%02x\n\n\n", record.count, record.addr, ~calcSum & 0xff);
    
    break;

  case '9':
    count = convert(&line[2], 2);
    addr = convert(&line[4], 4);

    record.count = 0;
    record.addr = addr;

    if ((count < 3) || (addr == -1)) {
      return BADFORMAT;
    }

    break;
    
  default:
    return UNIMPLEMENTED;
  }
  
  return OK;
}

int writeIntel() {
  int i;
  int calcSum = record.count;

  if (record.count == 0) {
    printf(":00000001FF\n");
  }
  else {
    calcSum += ((record.addr >> 8) & 0xff);
    calcSum += (record.addr & 0xff);
  
    printf(":%02X%04X00", record.count, record.addr);

    for (i=0; i<record.count; i++) {
      printf("%02X", record.bytes[i]);
      calcSum += record.bytes[i];
    }

    printf("%02X\n", (-(calcSum & 0xff)) & 0xff);
  }


  return OK;
}

void copy() {
  char *line = NULL;
  size_t len;
  int res;

  while ((res = getline(&line, &len, stdin)) != -1) {
    stripTerm(line, res);
    
    res = processSrec(line);
    if (res != OK) {
      fprintf(stderr, "got error %d while reading source file.\n", res);
      break;
    }

    writeIntel();
  }

  if (line != NULL) {
    free(line);
  }
}
  
int main(uint argc, char **argv)
{
  copy();
}

