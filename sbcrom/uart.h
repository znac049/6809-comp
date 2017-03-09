#ifndef _UART_H_
#define _UART_H_

#define UART0_ADDR 0xffd0

#define UART_CR 0
#define UART_SR 0
#define UART_DATA 1

// Bits in the UART status register
#define CHAR_AVAILABLE 0x01
#define DATA_EMPTY 0x02

extern void initUart();
extern char getChar();
extern void putChar(char);

#endif
