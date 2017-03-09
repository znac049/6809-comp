#include "monitor.h"
#include "uart.h"

void putStr(char *s) {
  while (*s) {
    putChar(*s++);
  }
}

void init() {
  initUart();
}

int readLine(char *buff, int maxLine) {
  int insertInd = 0;
  char c = getChar();

  if (maxLine <= 0) {
    return 0;
  }

  maxLine--;

  while (1) {
    switch (c) {
    case LF:
    case CR:
      // Don't add the terminator to the string
      putChar(CR);
      putChar(LF);
      return insertInd;
      break;

    case BS:
    case DEL:
      if (insertInd) {
	putChar(BS);
	putChar(' ');
	putChar(BS);
	insertInd--;
      }
      break;

    default:
      if (insertInd >= maxLine) {
	putChar(BELL);
      }
      else {
	// Ignore control characters...
	if ((c >= ' ') && (c < DEL)) {
	  buff[insertInd] = c;
	  insertInd++;
	  buff[insertInd] = EOS;

	  putChar(c);
	}
      }
      break;
    }
  }

  return 0;
}

char *shift(char **s) {
  char *res = *s;

  return res;
}

int main(int argc, char **argv) {
  char line[80];
  char *ap;
  char *cmd;
  int numRead;

  init();

  while (1) {
    putStr("-> ");
    numRead = readLine(line, sizeof(cmd));

    if (numRead) {
      ap = line;
      cmd = shift(&ap);

      strlen(cmd);
    }
  }
}
