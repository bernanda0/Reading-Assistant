;-----------------------
; Bernanda - 2106708463
;-----------------------

#define __SFR_OFFSET 0x00
#include "avr/io.h"
.global main

msg_distance:
  .ascii "Distance: "
  .byte 0
msg_dark:
  .ascii "Too dark"
  .byte 0
msg_close:
  .ascii "Too close"
  .byte 0
;==================================================================

main:
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
  SBI DDRB, 2        ; for buzzer
  ;---------------------------------------------------------
  ; Init I2C LCD1602
  ;---------------------------------------------------------
  RCALL I2C_init        ;initialize TWI module
  RCALL LCD_init          ;subroutine to initialize LCD
  RCALL delay_ms2

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
  CPI R17, 0xC         ; Bandingkan R17 dengan value 
  BRSH led_off
  led_on: 
    LDI R21, 0xF0
    OUT PORTD, R21
    RJMP continue
  led_off:
    LDI R21, 0x0
    OUT PORTD, R21
  continue:

  ;---------------------------------------------------------
  ; Reading Sensor HCSR04
  ;---------------------------------------------------------
  RCALL hcsr_read

  ;---------------------------------------------------------
  ; Action for Buzzer
  ;---------------------------------------------------------
  CPI R28, 0xF
  BRSH buzzer_off
  buzzer_on:
    SBI PORTB, 2          ;turn on the PD2  
    RJMP continue2
  buzzer_off:
    CBI PORTB, 2          ;turn off the PD2
  continue2:

  ;---------------------------------------------------------
  ; Action for LCD
  ;---------------------------------------------------------
  print_msg:
  LDI R30, lo8(msg_distance)
  LDI R31, hi8(msg_distance) ;Z points to string message
  agn:
    LPM R17, Z+       ;load char of string onto R18
    CPI R17, 0        ;check if R18=0 (end of string)
    BREQ ext          ;if yes, exit
    RCALL send_char   ;else, send char to LCD
    RJMP agn          ;loop back & get next character
  ext:

  RCALL delay_ms
  RCALL delay_ms
  
  RJMP again

;==================================================================

;---------------------------------------------------------
; Subroutine for I2C LCD
;---------------------------------------------------------
send_char:
  MOV R23, R17    ;save copy of result
  ANDI R17, 0xF0  ;extract high-nibble
  OR R17, 1       ;RS = 1 for data
  RCALL send4bits ;send high-nibble

  MOV R17, R23    ;restore copy of result
  ANDI R17, 0x0F  ;extract & swap low-nibble
  SWAP R17        ;swap nibbles
  OR R17, 1       ;RS = 1 for data
  RCALL send4bits ;send low-nibble

send4bits:
  MOV R16, R17
  MOV R18, R17

  RCALL I2C_cycle       ; send data in R17
  
  OR R16, 0b00000100
  MOV R17, R16
  RCALL I2C_cycle       ; send dat EN = 1
  RCALL delay_short

  LDI R19, 0b00000100
  COM R19
  AND R18, R19
  MOV R17, R18
  RCALL I2C_cycle       ; send data EN = 0
  RCALL delay_us

  RET

I2C_cycle:
  RCALL I2C_start     ;transmit START condition
  LDI R27, 0x40       ;
  RCALL I2C_write     ;write slave address SLA+W
  MOV R27, R17        ;!!! R17 !!!!
  RCALL I2C_write
  RCALL I2C_stop      ;transmit STOP condition 
  RET

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

LCD_init:
    LDI   R16, 0x33         ;init LCD for 4-bit data
    RCALL command_wrt       ;send to command register
    RCALL delay_ms
    LDI   R16, 0x32         ;init LCD for 4-bit data
    RCALL command_wrt
    RCALL delay_ms
    LDI   R16, 0x28         ;LCD 2 lines, 5x7 matrix
    RCALL command_wrt
    RCALL delay_ms
    LDI   R16, 0x0C         ;disp ON, cursor OFF
    RCALL command_wrt
    LDI   R16, 0x01         ;clear LCD
    RCALL command_wrt
    RCALL delay_ms
    LDI   R16, 0x06         ;shift cursor right
    RCALL command_wrt
    RET 
    
command_wrt:
    MOV   R27, R16
    ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
    OUT   PORTD, R27        ;o/p high nibble to port D
    CBI   PORTB, 1          ;RS = 0 for command
    SBI   PORTB, 0          ;EN = 1
    RCALL delay_short       ;widen EN pulse
    CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
    RCALL delay_us          ;delay in micro seconds
    ;----------------------------------------------------
    MOV   R27, R16
    SWAP  R27               ;swap nibbles
    ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
    OUT   PORTD, R27        ;o/p high nibble to port D
    SBI   PORTB, 0          ;EN = 1
    RCALL delay_short       ;widen EN pulse
    CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
    RCALL delay_us          ;delay in micro seconds
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
l7: LDI   R23, 128
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET
