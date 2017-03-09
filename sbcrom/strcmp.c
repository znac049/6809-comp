#include "monitor.h"
#include "string.h"

int strcmp(char *a, char *b) {
  char c1, c2;

  while ((c1 = *a++) && (c2 = *b++)) {
    if (c1 < c2)
      return -1;

    if (c1 > c2)
      return 1;
  }

  // We've hit the end of one or other string with no difference so far
  if (c1 == EOS) {
    if (c2 == EOS) {
      // Both strings match
      return 0;
    }

    return -1;
  }

  return 1;
}
