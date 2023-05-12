;-----------------------
; MASTER CODE 
;-----------------------
; Bernanda - 2106708463
;-----------------------

#define __SFR_OFFSET 0x00
#include "avr/io.h"
.global main

main:
  .equ SCK, 5
  .equ MOSI, 3
  .equ SS, 2

  ;--------------------------------------------------------------
  ; SPI for HCSR04
  ;--------------------------------------------------------------
  LDI R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
  OUT DDRB, R17         ; set MOSI, SCK, SS as o/p
  LDI R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
  OUT SPCR, R17         ; enable SPI as master, fsck=fosc/16, mode 0
  
  SBI   DDRB, 1         ; pin PB1 as o/p (Trigger)
  CBI   DDRB, 0         ; pin PB0 as i/p (Echo)

  ;--------------------------------------------------------------
  ; ADC for photoresistor + I2C
  ;--------------------------------------------------------------
  CBI DDRC, 0           ; pin PC0 (ADC0) as input for ldr
  LDI R20, 0b11100000   ; Internal 2.56, Left, ADC0
  STS ADMUX, R20        ; berikan nilai ke ADMUX
  LDI R20, 0b10000111   ; enable ADEN dan CLK128
  STS ADCSRA, R20  
  RCALL I2C_init        ;initialize TWI module

  ; testing only
  SBI DDRD, 2           ;pin PD2 as output for testing

again:
  ;--------------------------------------------------------
  ; I2C for ldr
  ;--------------------------------------------------------
  LDI R20, 0b11000111   ; memulai konversi
  STS ADCSRA, R20       ; dengan menyalakan ADSC
  wait_ldr : 
    LDS R20, ADCSRA       ; cek ADIF (set atau tidak)
    SBRS R20, 4           ; skip jump saat konversi selesai
    RJMP wait_ldr         ; loop jika belum
  ;-----------------------------------------------------------
  LDI R17, 0xD7         ; set ADIF lagi
  STS ADCSRA, R17       ; untuk meng-clears ADIF
  ;-----------------------------------------------------------
  LDS R16, ADCL         ; Load isi ADCL ke R16
  LDS R17, ADCH         ; Load isi ADCH ke R17
  
  RCALL I2C_start     ;transmit START condition
  LDI R27, 0b10010000 ;SLA(1001000) + W(0)
  RCALL I2C_write     ;write slave address SLA+W
  MOV R27, R17
  RCALL I2C_write
  RCALL I2C_stop      ;transmit STOP condition
  
  CPI R17, 0xC         ; Bandingkan R17 dengan value 
  BRSH led_off
  led_on: 
    SBI PORTD, 2
    RJMP continue
  led_off:
    CBI PORTD, 2

  continue:

  ;--------------------------------------------------------
  ; SPI for HCSR04
  ;--------------------------------------------------------
  RCALL hcsr_read
  MOV R16, R28
  CBI PORTB, SS       ;enable slave device
  OUT SPDR, R17       ;transmit byte to slave
  loop: 
    IN R28, SPSR
    SBRS R28, SPIF    ;wait for byte transmission
    RJMP loop         ;to complete
  SBI PORTB, SS       ;disable slave device
  ;--------------------------------------------------------
  
  ;---------------------------
  ; For testing
  ;---------------------------
  ;CPI R16, 0xF
  ;BRSH off
  ;on:
  ;  SBI PORTD, 2          ;turn on the PD2  
  ;  RJMP continue
  ;off:
  ;  CBI PORTD, 2
  ;continue:

  RCALL delay_ms
  RJMP again          ;repeat transmission

;================================================================
; HCSR and SPI sub routine
;================================================================
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
    ;-----------------------------------------------------------
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

;===============================================================
; I2C sub routines
;===============================================================
I2C_init:
  LDI R21, 0
  STS TWSR, R21   ;prescaler 1
  LDI R21, 35     ;division factor = 35
  STS TWBR, R21   ;
  LDI R21, (1<<TWEN)
  STS TWCR, R21   ;enable TWI
  RET
I2C_start:
  LDI R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
  STS TWCR, R21         ;transmit START condition
  wt1:
    LDS R21, TWCR
    SBRS R21, TWINT     ;TWI interrupt = 1?
    RJMP wt1            ;no, wait for end of transmission
  RET
I2C_write:
  STS TWDR, R27         ;copy DATA in R27 into data register
  LDI R21, (1<<TWINT)|(1<<TWEN)
  STS TWCR, R21         ;transmit R27
  wt2:
    LDS R21, TWCR
    SBRS R21, TWINT
    RJMP wt2            ;wait for end of transmission
  RET
I2C_stop:
  LDI R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
  STS TWCR, R21         ;transmit STOP condition
  RET


;===============================================================
;delay subroutines
;===============================================================
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

delay_ms:
;--------
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 50
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET

delay_sec: ;4 sec delay via timer1
  ;-------------------------------------------------------
  .EQU value, 36
  LDI R20, hi8(value)
  STS TCNT1H, R20
  LDI R20, lo8(value)
  STS TCNT1L, R20 ;initialize counter TCNT1 = 3036
  ;-------------------------------------------------------
  LDI R20, 0b00000000
  STS TCCR1A, R20
  LDI R20, 0b00000101
  STS TCCR1B, R20 ;normal mode, prescaler = 1024
  ;-------------------------------------------------------
  l3: IN R20, TIFR1 ;get TIFR1 byte & check
  SBRS R20, TOV1 ;if TOV1=1, skip next instruction
  RJMP l3 ;else, loop back & check TOV1 flag
  ;-------------------------------------------------------
  LDI R20, 1<<TOV1
  OUT TIFR1, R20 ;clear TOV1 flag
  ;-------------------------------------------------------
  LDI R20, 0b00000000
  STS TCCR1B, R20 ;stop timer0
  RET