int main(int argc, char **argv)
{
  volatile char *uart = (char *)0xffe0;

  while ((uart[0] & 0x02) != 0x02)
    ;

  uart[1] = '!';
}
