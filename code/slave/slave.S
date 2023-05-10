;-----------------------
; SLAVE CODE 
;-----------------------
; Bernanda - 2106708463
;-----------------------

#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

main:
  RCALL init_serial
  LDI R17, (1<<SPE)
  OUT SPCR, R17      ; enable SPI as slave

again:
  ;-------------------------------------------------------
  ; SPI reading
  ;-------------------------------------------------------
  l1:
    IN R18, SPSR
    SBRS R18, SPIF   ; wait for byte reception
    RJMP l1

  IN R16, SPDR       ; i/p byte from data register
  RCALL ASCII_MSD    ; Mendapatkan ASCII dari MSD
  RCALL LCD_buffer
  STS UDR0, R16

  RCALL ASCII_LSD    ; Mendapatkan ASCII dari LSD
  RCALL LCD_buffer   ; Subroutine untuk mengecek FLAG UDRE0
  STS UDR0, R16      ; print LSD

  LDI R16, '|'       ;
  RCALL LCD_buffer   ; Subroutine untuk mengecek FLAG UDRE0
  STS UDR0, R16   

  RJMP again

init_serial:
  CLR R24
  STS UCSR0A, R24   ; clear UCSR0A register
  STS UBRR0H, R24   ; clear UBRR0H register  
  LDI R24, 103      ; store in UBRR0L 103 value
  STS UBRR0L, R24   ; to set baud rate 9600
  LDI R24, 1<<RXEN0 | 1<<TXEN0   ;enable RXB & TXB
  STS UCSR0B, R24
  LDI R24, 1<<UCSZ00 | 1<<UCSZ01 ;asynch, no parity, 1 stop, 8 bits
  STS UCSR0C, R24
  RET

LCD_buffer:
  LDS R28, UCSR0A
  SBRS R28, UDRE0 ;test data buffer if data can be sent
  RJMP LCD_buffer
  RET

ASCII_MSD: ;Proses mendapatkan ASCII dari MSD
  MOV R23, R16      ;save copy of result
  ANDI R16, 0xF0    ;extract & swap high-nibble
  SWAP R16
  SUBI R16, -48     ;R16 = R16 - (48) = R16 + 48
  MOV R28, R16      ;save a copy of high-byte result
  SUBI R28, 58      ;if +ve    
  BRPL A_F_D1       ;branch & add 7 to get ASCII A to F
lo1: 
  RET

ASCII_LSD: ;Proses mendapatkan ASCII dari LSD
  MOV R16, R23      ;restore copy of result
  ANDI R16, 0x0F    ;extract low-nibble
  SUBI R16, -48     ;R16 = R16 - (48) = R16 + 48
  MOV R28, R16      ;save a copy of high-byte result
  SUBI R28, 58      ;if +ve
  BRPL A_F_D0       ;branch & add 7 to get ASCII A to F
lo2: 
  RET

A_F_D1:
  SUBI R16, -7      ;R16 = R16 - (7) = R16 + 7
  RJMP lo1
A_F_D0:
  SUBI R16, -7      ;R16 = R16 - (7) = R16 + 7
  RJMP lo2
  
delay_sec: ;1s delay
LDI R20, 255
l4: LDI R21, 255
l5: LDI R22, 82
l6: DEC R22
BRNE l6
DEC R21
BRNE l5
DEC R20
BRNE l4
RET
   