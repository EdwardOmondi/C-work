;
; Ext_Int_Ass.asm
;
; Created: 15-May-19 10:53:42 PM
; Author : Edward Omondi
;
; Replace with your application code
.include "m32def.inc"

.cseg
	.org 0x00
	rjmp main
	.org INT0addr
	rjmp INT0_vect

main:

	inc r17

	mov r17, (1 << INT0)
	mov GICR, r17

	clr r17
	mov r17, (1 << ISC00)
	mov MCUCR, r17

	mov r17, 0x01
	out DDRA,r17

	sei


    rjmp main

INT0_vect:

	inc r16

	mov r16, 0xFF
	out PORTA, r16

	clr r16
	out PORTA, r16
	