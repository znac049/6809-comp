#include "uart.h"

void initUart() {
  volatile char *uart = (char *) UART0_ADDR;

  // reset the device
  uart[UART_CR] = 0x03;

  // clock div 16
  uart[UART_CR] = 0x95;
}

char getChar() {
  volatile char *uart = (char *) UART0_ADDR;

  while ((uart[UART_SR] & CHAR_AVAILABLE) != CHAR_AVAILABLE) {
    ;
  }

  return uart[UART_DATA];
}

void putChar(char c) {
  volatile char *uart = (char *) UART0_ADDR;

  while ((uart[UART_SR] & DATA_EMPTY) != DATA_EMPTY) {
    ;
  }

  uart[UART_DATA] = c;
}
