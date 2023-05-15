;-----------------------
; Bernanda - 2106708463
;-----------------------

#define __SFR_OFFSET 0x00
#include "avr/io.h"
.global main

;==================================================================

main:
  ;---------------------------------------------------------
  ; Init SPI 7SEG MAX7219
  ;---------------------------------------------------------
  .equ  SCK, 5
  .equ  MOSI, 3
  .equ  SS, 2
  RCALL SPI_MAX7219_init
  RCALL MAX7219_disp_good 
  RCALL init_serial

  ;---------------------------------------------------------
  ; Init Sensor Photoresistor
  ;---------------------------------------------------------
  CBI DDRC, 0           ; pin PC0 (ADC0) as input for ldr
  LDI R20, 0b11100000   ; Internal 2.56, Left, ADC0
  STS ADMUX, R20        ; berikan nilai ke ADMUX
  LDI R20, 0b10000111   ; enable ADEN dan CLK128
  STS ADCSRA, R20  

  ;---------------------------------------------------------
  ; Init Sensor HCSR04
  ;---------------------------------------------------------
  SBI   DDRB, 1         ; pin PB1 as o/p (Trigger)
  CBI   DDRB, 0         ; pin PB0 as i/p (Echo)

  ;---------------------------------------------------------
  ; Init Aktuator LED
  ;---------------------------------------------------------
  LDI R21, 0xF0
  OUT DDRD, R21         ; port D[7:4] is o/p

  ;---------------------------------------------------------
  ; Init Aktuator Buzzer
  ;---------------------------------------------------------
  SBI DDRD, 3        ; for buzzer

  ;---------------------------------------------------------
  ; Init I2C LCD1602 (UNUSED)
  ;---------------------------------------------------------
  ; RCALL I2C_init        ;initialize TWI module
  ; RCALL LCD_init          ;subroutine to initialize LCD
  ; RCALL delay_ms2

again: 
  ;---------------------------------------------------------
  ; Reading Sensor Photoresistor
  ;---------------------------------------------------------
  LDI R20, 0b11000111   ; memulai konversi
  STS ADCSRA, R20       ; dengan menyalakan ADSC
  wait_ldr : 
    LDS R20, ADCSRA     ; cek ADIF (set atau tidak)
    SBRS R20, 4         ; skip jump saat konversi selesai
    RJMP wait_ldr       ; loop jika belum
  ;-----------------------------------------------------------
  LDI R17, 0xD7         ; set ADIF lagi
  STS ADCSRA, R17       ; untuk meng-clears ADIF
  ;-----------------------------------------------------------
  LDS R16, ADCL         ; Load isi ADCL ke R16
  LDS R17, ADCH         ; Load isi ADCH ke R17

  ;-----------------------------------------------------------
  ; Action for LED
  ;---------------------------------------------------------
  CPI R17, 0x69        ; Bandingkan R17 dengan value 
  BRSH led_off
  led_on: 
    LDI R21, 0xF0
    OUT PORTD, R21
    RCALL MAX7219_disp_dark
    RJMP continue
  led_off:
    LDI R21, 0x0
    OUT PORTD, R21
    RCALL MAX7219_disp_good
  continue:

  MOV R16, R17
  RCALL ASCII_MSD    ; Mendapatkan ASCII dari MSD
  RCALL LCD_buffer
  STS UDR0, R16

  RCALL ASCII_LSD    ; Mendapatkan ASCII dari LSD
  RCALL LCD_buffer   ; Subroutine untuk mengecek FLAG UDRE0
  STS UDR0, R16      ; print LSD

  LDI R16, '|'       ;
  RCALL LCD_buffer   ; Subroutine untuk mengecek FLAG UDRE0
  STS UDR0, R16   

  ;---------------------------------------------------------
  ; Reading Sensor HCSR04
  ;---------------------------------------------------------
  RCALL hcsr_read
  ;RCALL byte_to_decimal
  MOV R16, R28
  
  ;---------------------------------------------------------
  ; Action for Buzzer
  ;---------------------------------------------------------
  CPI R16, 0xF
  BRSH buzzer_off
  buzzer_on:
    SBI PORTD, 3          ;turn on the PD2
    RCALL MAX7219_disp_close  
    RJMP continue2
  buzzer_off:
    CBI PORTD, 3          ;turn off the PD2
    RCALL MAX7219_disp_good
  continue2:

  RCALL delay_ms2
  RJMP again

;==================================================================

;---------------------------------------------------------
; Subroutine for Serial Monitor
;---------------------------------------------------------
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

;---------------------------------------------------------
; Subroutine for SPI 7SEG MAX7219
;---------------------------------------------------------
SPI_MAX7219_init:
;-----------------
  LDI   R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
  OUT   DDRB, R17       ;set MOSI, SCK, SS as o/p
  ;--------------------------------------------------------
  LDI   R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
  OUT   SPCR, R17       ;enable SPI as master, fsck=fosc/16
  ;--------------------------------------------------------
  LDI   R17, 0x0A       ;set segment intensity (0 to 15)
  LDI   R18, 8          ;intensity level = 8
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x09       ;set decoding mode command
  LDI   R18, 0b00000011 ;decoding byte
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x0B       ;set scan limit command
  LDI   R18, 0x07       ;8 digits connected to MAX7219
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x0C       ;set turn ON/OFF command
  LDI   R18, 0x01       ;turn ON MAX7219
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  RET
;==============================================================

MAX7219_disp_good:
  LDI   R17, 0x08       ;select digit 7
  LDI   R18, 0x5E       ;data = G
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x07       ;select digit 6
  LDI   R18, 0x1D       ;data = o
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x06       ;select digit 5
  LDI   R18, 0x1D       ;data = o
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x05       ;select digit 4
  LDI   R18, 0x3D       ;data = d
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x04       ;select digit 1
  LDI   R18, 0x00       ;data = E
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x02       ;select digit 1
  LDI   R18, 0xFF       ;data = !
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x01       ;select digit 0
  LDI   R18, 0xFF       ;data = !
  RCALL send_bytes      ;send command & data to MAX7219
  ;-------------------------------------------------------
  
  RET

MAX7219_disp_dark:
;-----------------
  LDI   R17, 0x08       ;select digit 7
  LDI   R18, 0x3D       ;data = d
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x07       ;select digit 6
  LDI   R18, 0x7D       ;data = a
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x06       ;select digit 5
  LDI   R18, 0x05       ;data = r
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x05       ;select digit 4
  LDI   R18, 0x0D       ;data = c
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x02       ;select digit 1
  LDI   R18, 0xFF       ;data = !
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x01       ;select digit 0
  LDI   R18, 0xFF       ;data = !
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  RET

MAX7219_disp_close:
;-----------------
  LDI   R17, 0x08       ;select digit 7
  LDI   R18, 0x4E       ;data = C
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x07       ;select digit 6
  LDI   R18, 0x0E       ;data = L
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x06       ;select digit 3
  LDI   R18, 0x1D       ;data = o
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x05       ;select digit 2
  LDI   R18, 0x5B       ;data = s
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x04       ;select digit 1
  LDI   R18, 0x4F       ;data = E
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  RET
;==============================================================
send_bytes:
      CBI   PORTB, SS       ;enable slave device MAX7219
      OUT   SPDR, R17       ;transmit command
      ;--------------------------------------------------------
ls2:  IN    R19, SPSR
      SBRS  R19, SPIF       ;wait for byte transmission
      RJMP  ls2              ;to complete
      ;--------------------------------------------------------
      OUT   SPDR, R18       ;transmit data
      ;--------------------------------------------------------
ls3:  IN    R19, SPSR
      SBRS  R19, SPIF       ;wait for byte transmission
      RJMP  ls3              ;to complete
      ;--------------------------------------------------------
      SBI   PORTB, SS       ;disable slave device MAX7219
      RET
;==============================================================
byte_to_decimal:
;------------
      CLR   R26             ;set counter1, initial value 0
      CLR   R27             ;set counter2, initial value 0
      ;--------------------------------------------------------
ls4:  CPI   R28, 100        ;compare R28 with 100
Ret:  BRMI  ls5            ;jump when R28 < 100
      INC   R26             ;increment counter1 by 1
      SUBI  R28, 100        ;R28 = R28 - 100
      RJMP  ls4
      ;--------------------------------------------------------
ls5:  CPI   R28, 10         ;compare R28 with 10
      BRMI  dsp             ;jump when R28 < 10
      INC   R27             ;increment counter2 by 1
      SUBI  R28, 10         ;R28 = R28 - 10
      RJMP  ls5
      ;--------------------------------------------------------  
dsp:  MOV   R18, R27
      LDI   R17, 0x06       ;select digit 5 for MSD
      RCALL send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      MOV   R18, R28
      LDI   R17, 0x05       ;select digit 4 for LSD
      RCALL send_bytes      ;send command & data to MAX7219    
      ;--------------------------------------------------------
      RET
      
;---------------------------------------------------------
; Subroutine for reading HCSR04
;---------------------------------------------------------
hcsr_read:
  SBI   PORTB, 1
  RCALL delay_timer0
  CBI   PORTB, 1        ;send 10us high pulse to sensor
  RCALL echo_PW         ;compute Echo pulse width count
  RET

echo_PW:
    ;-------
    LDI   R20, 0b00000000
    STS   TCCR1A, R20     ;Timer 1 normal mode
    LDI   R20, 0b11000101 ;set for rising edge detection &
    STS   TCCR1B, R20     ;prescaler=1024, noise cancellation ON
    ;-----------------------------------------------------------
l1: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l1              ;loop until rising edge is detected
    ;------------------------------T-----------------------------
    LDS   R16, ICR1L      ;store count value at rising edge
    ;-----------------------------------------------------------
    OUT   TIFR1, R21      ;clear flag for falling edge detection
    LDI   R20, 0b10000101
    STS   TCCR1B, R20     ;set for falling edge detection
    ;-----------------------------------------------------------
l2: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l2              ;loop until falling edge is detected
    ;-----------------------------------------------------------
    LDS   R28, ICR1L      ;store count value at falling edge
    ;-----------------------------------------------------------
    SUB   R28, R16        ;count diff R28 = R28 - R16
    OUT   TIFR1, R21      ;clear flag for next sensor reading
    RET

;---------------------------------------------------------
; Subroutine for delay
;---------------------------------------------------------
delay_timer0:             ;10 usec delay via Timer 0
  ;------------
    CLR   R20
    OUT   TCNT0, R20      ;initialize timer0 with count=0
    LDI   R20, 20
    OUT   OCR0A, R20      ;OCR0 = 20
    LDI   R20, 0b00001010
    OUT   TCCR0B, R20     ;timer0: CTC mode, prescaler 8
    ;-----------------------------------------------------------
l0: IN    R20, TIFR0      ;get TIFR0 byte & check
    SBRS  R20, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  l0              ;else, loop back & check OCF0 flag
    ;-----------------------------------------------------------
    CLR   R20
    OUT   TCCR0B, R20     ;stop timer0
    ;-----------------------------------------------------------
    LDI   R20, (1<<OCF0A)
    OUT   TIFR0, R20      ;clear OCF0 flag
    RET

delay_short:
      NOP
      NOP
      RET

delay_us:
      LDI   R20, 90
l3:   RCALL delay_short
      DEC   R20
      BRNE  l3
      RET

delay_ms:
      LDI   R21, 40
l4:   RCALL delay_us
      DEC   R21
      BRNE  l4
      RET

delay_ms2:
;--------
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 80
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET

my_delay:
      LDI   R21, 255
l9:   LDI   R22, 255
l10:  LDI   R23, 40
l11:  DEC   R23
      BRNE  l8
      DEC   R22
      BRNE  l7
      DEC   R21
      BRNE  l6
      RET