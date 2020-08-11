;
; Task 3.asm
;
; Created: 06-Mar-19 3:59:38 AM
; Author : Edward Omondi
;


; Replace with your application code
.INCLUDE "M32DEF.INC"

.def temp = R16
LDI	temp, HIGH(RAMEND)	;initialization os the stack pointer
OUT	SPH, temp
LDI	temp, LOW (RAMEND)
OUT SPL, temp

LDI temp, 0xFF			;defining port B as an output		
OUT DDRB, temp

LDI temp, 0x00			;defining port D as an input
IN DDRD, R20

OUT PORTB, 0x00			;putting voltage at port B=0

IN  temp, PinD			;putting valuesof the input into temp
OUT PortB, temp			;putting values of the input to the output

LOOP1:

LDI  temp, 0x66
OUT PORTB, temp
CALL DELAY

LDI temp, 0xCC
OUT PORTB, temp
CALL DELAY

LDI  temp, 0x99
OUT PORTB, temp
CALL DELAY

LDI  temp, 0x33
OUT PORTB, temp
CALL DELAY

RJMP LOOP1

DELAY:

PUSH temp
PUSH R21
LDI temp,0x10
RET

LOOP2:

LDI R21, 0x9F
RET

LOOP3:

DEC R21
BRNE LOOP3
DEC temp
BRNE LOOP2
POP R21
POP temp
RET

END:




