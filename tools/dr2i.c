#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>

#include "intelHex.h"

#define OK 0
#define ERR -1
#define EOS '\0'

#define MAXNAME 255

#define MEMSIZE 65536

int base = MEMSIZE-1;
int mem[MEMSIZE];
int lowestAddr = 0xffff;
int highestAddr = 0;

int verboseflag = 0;
char sourcefile[MAXNAME];
int rebase=0;

int valof(char c) {
  if ((c >= '0') && (c <= '9')) {
    return c-'0';
  }

  if ((c >= 'a') && (c <= 'f')) {
    return c-'a'+10;
  }

  if ((c >= 'A') && (c <= 'F')) {
    return c-'A'+10;
  }

  return -1;
}

int hexstr2num(char *str, int *val) {
  int res = 0;

  while (*str) {
    int v = valof(*str++);

    if (v == -1) {
      *val = 0;
      return -1;
    }

    res = (res<<4) + v;
  }

  *val = res;

  return 0;
}

int decstr2num(char *str, int *val) {
  int res = 0;

  while (*str) {
    int v = valof(*str++);

    if (v == -1) {
      *val = 0;
      return -1;
    }

    res = (res*10) + v;
  }

  *val = res;

  return 0;
}

int str2num(char *str, int *val) {
  int res = -1;

  if (str[0] == '$') {
    res = hexstr2num(&str[1], val);
  }
  else if (strncmp(str, "0x", 2) == 0) {
    res = hexstr2num(&str[2], val);
  }
  else {
    res = decstr2num(str, val);
  }

  return res;
}

int getWord(FILE *fd) {
  int c1 = fgetc(fd);
  int c2 = fgetc(fd);

  if ((c1 == EOF) || (c2 == EOF)) {
    return -1;
  }

  return (c1<<8) | c2;
}

void poke(int addr, int val) {
  mem[addr] = val & 0xff;

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

void parse_args(int argc, char **argv) {
  int c;

  sourcefile[0] = EOS;

  while (1) {
    static struct option long_options[] =
      {
	/* These options set a flag. */
	{"verbose", no_argument,       &verboseflag, 1},

	/* These options don’t set a flag.
	   We distinguish them by their indices. */
	{"rebase",  required_argument, 0, 'r'},
	{"file",    required_argument, 0, 'f'},
	{0, 0, 0, 0}
      };

    /* getopt_long stores the option index here. */
    int option_index = 0;

    c = getopt_long(argc, argv, "r:f:", long_options, &option_index);

    /* Detect the end of the options. */
    if (c == -1)
      break;

    switch (c) {
    case 'r':
      if (str2num(optarg, &rebase) != 0) {
	fprintf(stderr, "badly formed rebase address: %s\n", optarg);
	exit(1);
      }
      break;

    case 'f':
      strncpy(sourcefile, optarg, MAXNAME);
      break;

    case '?':
      /* getopt_long already printed an error message. */
      break;

    default:
      abort();
    }
  }

  /* Print any remaining command line arguments (not options). */
  if (optind < argc) {
    printf ("non-option ARGV-elements: ");
    while (optind < argc)
      printf ("%s ", argv[optind++]);
    putchar ('\n');
  }
}

int main(int argc, char **argv)
{
  int i;
  int segAddr;
  FILE *fdin = stdin;

  parse_args(argc, argv);

  if (sourcefile[0] != EOS) {
    fdin = fopen(sourcefile, "r");
    if (fdin == NULL) {
      fprintf(stderr, "Couldn't open file: '%s' - aborting\n", sourcefile);
      exit(1);
    }
  }
  
  for (i=0; i<MEMSIZE; i++) {
    mem[i] = -1;
  }

  while ((segAddr = processSegment(fdin)) != -1)
    ;

  if (fdin != stdin) {
    fclose(fdin);
  }

  ihexReset();

  for (i=lowestAddr; i<=highestAddr; i++) {
    int val = mem[i];

    if (val < 0) {
      val = 0x5a;
    }
    else {
      val = val & 0xff;
    }

    ihexPut(i-rebase, (char) val);
  }

  ihexFinish();
}
