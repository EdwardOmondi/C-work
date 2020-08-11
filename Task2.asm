;
; Task 2.asm
;
; Created: 06-Mar-19 5:48:39 AM
; Author : Edward Omondi
;ATmega32 UART interfacing with Computer via RS232 and MAX232

.include "m32def.inc"
.equ    fclk                = 16000000      ; system clock frequency (for delays)

; register usage
.def    temp                = R16           ; temporary storage

; LCD interface 
.equ    lcd_D7_port         = PORTD         ; lcd D7 connection
.equ    lcd_D7_bit          = PORTD7
.equ    lcd_D7_ddr          = DDRD

.equ    lcd_D6_port         = PORTD         ; lcd D6 connection
.equ    lcd_D6_bit          = PORTD6
.equ    lcd_D6_ddr          = DDRD

.equ    lcd_D5_port         = PORTD         ; lcd D5 connection
.equ    lcd_D5_bit          = PORTD5
.equ    lcd_D5_ddr          = DDRD

.equ    lcd_D4_port         = PORTD         ; lcd D4 connection
.equ    lcd_D4_bit          = PORTD4
.equ    lcd_D4_ddr          = DDRD

.equ    lcd_D3_port         = PORTD         ; lcd D3 connection
.equ    lcd_D3_bit          = PORTD3
.equ    lcd_D3_ddr          = DDRD

.equ    lcd_D2_port         = PORTD         ; lcd D2 connection
.equ    lcd_D2_bit          = PORTD2
.equ    lcd_D2_ddr          = DDRD

.equ    lcd_D1_port         = PORTD         ; lcd D1 connection
.equ    lcd_D1_bit          = PORTD1
.equ    lcd_D1_ddr          = DDRD

.equ    lcd_D0_port         = PORTD         ; lcd D0 connection
.equ    lcd_D0_bit          = PORTD0
.equ    lcd_D0_ddr          = DDRD

.equ    lcd_E_port          = PORTB         ; lcd Enable pin
.equ    lcd_E_bit           = PORTB1
.equ    lcd_E_ddr           = DDRB

.equ    lcd_RS_port         = PORTB         ; lcd Register Select pin
.equ    lcd_RS_bit          = PORTB0
.equ    lcd_RS_ddr          = DDRB

; LCD module information
.equ    lcd_LineOne         = 0x00          ; start of line 1
.equ    lcd_LineTwo         = 0x40          ; start of line 2
.equ   lcd_LineThree        = 0x14          ; start of line 3

; LCD instructions
.equ    lcd_Clear           = 0b00000001    ; replace all characters with ASCII 'space'
.equ    lcd_Home            = 0b00000010    ; return cursor to first position on first line
.equ    lcd_EntryMode       = 0b00000110    ; shift cursor from left to right on read/write
.equ    lcd_DisplayOff      = 0b00001000    ; turn display off
.equ    lcd_DisplayOn       = 0b00001100    ; display on, cursor off, don't blink character
.equ    lcd_FunctionReset   = 0b00110000    ; reset the LCD
.equ    lcd_FunctionSet8bit = 0b00111000    ; 8-bit data, 2-line display, 5 x 7 font
.equ    lcd_SetCursor       = 0b10000000    ; set cursor position

; ****************************** Reset Vector *******************************
.org    0x0000
    jmp     start                           ; jump over Interrupt Vectors, Program ID etc.

/*.org	URXCaddr
	rjmp	URXC_INT_Handler		;jump to interrupt subroutine
.org	40*/

;******************************* Program ID *********************************
.org    INT_VECTORS_SIZE

msg1:
.db         "Key in Letter:",0,0
msg2:
.db         "Mechatronic Engineering 2019",0,0
msg3:
.db         "You are enjoying AVR applications solutions",0

; ****************************** Main Program Code **************************
start:
; initialize the stack pointer to the highest RAM address
    ldi     temp,low(RAMEND)
    out     SPL,temp
    ldi     temp,high(RAMEND)
    out     SPH,temp

;initialization of the receiver interrupt enable,receiver and transmittor pin
	ldi		temp,(1<<RXEN)|(1<<RXCIE)|(1<<TXEN)
	out		UCSRB, temp
	ldi		temp, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;initialization in the 8-bit mode
	out		UCSRC, temp
	ldi		temp, 0x33
	out		UBRRL, temp
	ldi		temp, 0xFF
	out		DDRC, temp
	sei												;set interrupt flag

; configure the microprocessor pins for the data lines
    sbi     lcd_D7_ddr, lcd_D7_bit          ; 8 data lines - output
    sbi     lcd_D6_ddr, lcd_D6_bit
    sbi     lcd_D5_ddr, lcd_D5_bit
    sbi     lcd_D4_ddr, lcd_D4_bit
    sbi     lcd_D3_ddr, lcd_D3_bit
    sbi     lcd_D2_ddr, lcd_D2_bit
    sbi     lcd_D1_ddr, lcd_D1_bit
    sbi     lcd_D0_ddr, lcd_D0_bit

; configure the microprocessor pins for the control lines
    sbi     lcd_E_ddr,  lcd_E_bit           ; E line - output
    sbi     lcd_RS_ddr, lcd_RS_bit          ; RS line - output

; initialize the LCD controller as determined by the equates (LCD instructions)
    call    lcd_init_8d                     ; initialize the LCD display for an 8-bit interface

;display the question	
	ldi     ZH, high(msg1)        ; point to the information that is to be displayed
    ldi     ZL, low(msg1)			; point to where the information should be displayed
    ldi     temp, lcd_LineOne              
    call    lcd_write_string_8d
	
;compare the input value and  the set value
	/*cpi		UDR, 0x4e			;compare and go to the next task if equal
	brne	cas1				;goes to cas1

	cpi		UDR,  0x079			;compare and skip the next task if equal
	brne	cas2				;goes to cas2

	cpi		UDR,  0x05a			;compare and skip the next task if equal
	brne	cas3				;goes to cas3

; display the first case "N"
cas1:*/
    ldi     ZH, high(msg2)        ; point to the information that is to be displayed
    ldi     ZL, low(msg2)			; point to where the information should be displayed
    ldi     temp, lcd_LineTwo              
    call    lcd_write_string_8d
	;ret

; display the second case "y"
;cas2:
    ldi     ZH, high(msg3)       ; point to the information that is to be displayed
    ldi     ZL, low(msg3)			; point to where the information should be displayed
    ldi     temp, lcd_LineThree               
    call    lcd_write_string_8d
	;ret

	; display the third case "Z"
;cas3:
    /*ldi     ZH, high(msg2)       ; point to the information that is to be displayed
    ldi     ZL, low(msg2)			; point to where the information should be displayed
    ldi     temp, lcd_LineOne               
    call    lcd_write_string_8d
    ldi     ZH, high(msg3)       ; point to the information that is to be displayed
    ldi     ZL, low(msg3)			; point to where the information should be displayed
    ldi     temp, lcd_LineTwo               
    call    lcd_write_string_8d
	ret*/

; endless loop
here:
    rjmp    here

; ****************************** End of Main Program Code *******************

;******************************The transmitter subroutines*******************
/*URXC_INT_Handler:
	in		r17, UDR
	call	trnsmt
	reti

trnsmt:
	nop
	sbis	UCSRA, UDRE
	rjmp	trnsmt
	out		UDR, r17
	ret*/

; ============================== 8-bit LCD Subroutines ======================
; Name:     lcd_init_8d
; Purpose:  initialize the LCD module for a 8-bit data interface
; Entry:    equates (LCD instructions) set up for the desired operation
; Exit:     no parameters
; Notes:    uses time delays instead of checking the busy flag

lcd_init_8d:
; Power-up delay
    ldi     temp, 100                       ; initial 40 mSec delay
    call    delayTx1mS

; Reset the LCD controller.
    ldi     temp, lcd_FunctionReset         ; first part of reset sequence
    call    lcd_write_instruction_8d
    ldi     temp, 10                        ; 4.1 mS delay (min)
    call    delayTx1mS

    ldi     temp, lcd_FunctionReset         ; second part of reset sequence
    call    lcd_write_instruction_8d
    ldi     temp, 200                       ; 100 uS delay (min)
    call    delayTx1uS

    ldi     temp, lcd_FunctionReset         ; third part of reset sequence
    call    lcd_write_instruction_8d
    ldi     temp, 200                       ; this delay is omitted in the data sheet
    call    delayTx1uS

; Function Set instruction
    ldi     temp, lcd_FunctionSet8bit       ; set mode, lines, and font
    call    lcd_write_instruction_8d
    ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

; The next three instructions are specified in the data sheet as part of the initialization routine,
;   so it is a good idea (but probably not necessary) to do them just as specified and then redo them
;   later if the application requires a different configuration.

; Display On/Off Control instruction
    ldi     temp, lcd_DisplayOff            ; turn display OFF
    call    lcd_write_instruction_8d
    ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

; Clear Display instruction
    ldi     temp, lcd_Clear                 ; clear display RAM
    call    lcd_write_instruction_8d
    ldi     temp, 4                         ; 1.64 mS delay (min)
    call    delayTx1mS

; Entry Mode Set instruction
    ldi     temp, lcd_EntryMode             ; set desired shift characteristics
    call    lcd_write_instruction_8d
    ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

; This is the end of the LCD controller initialization but the display
;   has been left in the OFF condition.  

; Display On/Off Control instruction
    ldi     temp, lcd_DisplayOn             ; turn the display ON
    call    lcd_write_instruction_8d
    ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS
    ret

; ---------------------------------------------------------------------------
; Name:     lcd_write_string_8d
; Purpose:  display a string of characters on the LCD
; Entry:    ZH and ZL pointing to the start of the string
;           (temp) contains the desired DDRAM address at which to start the display
; Exit:     no parameters
; Notes:    the string must end with a null (0)
;           uses time delays instead of checking the busy flag

lcd_write_string_8d:
; preserve registers
    push    ZH                              ; preserve pointer registers
    push    ZL

; fix up the pointers for use with the 'lpm' instruction
    lsl     ZL                              ; shift the pointer one bit left for the lpm instruction
    rol     ZH

; set up the initial DDRAM address
    ori     temp, lcd_SetCursor             ; convert the plain address to a set cursor instruction
    call   lcd_write_instruction_8d         ; set up the first DDRAM address
    ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

; write the string of characters
lcd_write_string_8d_01:
    lpm     temp, Z+                        ; get a character
    cpi     temp,  0                        ; check for end of string
    breq    lcd_write_string_8d_02          ; done

; arrive here if this is a valid character
    call    lcd_write_character_8d          ; display the character
    ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS
    rjmp    lcd_write_string_8d_01          ; not done, send another character

; arrive here when all characters in the message have been sent to the LCD module
lcd_write_string_8d_02:
    pop     ZL                              ; restore pointer registers
    pop     ZH
    ret

; ---------------------------------------------------------------------------
; Name:     lcd_write_character_8d
; Purpose:  send a byte of information to the LCD data register
; Entry:    (temp) contains the data byte
; Exit:     no parameters
; Notes:    does not deal with RW (busy flag is not implemented)

lcd_write_character_8d:
    sbi     lcd_RS_port, lcd_RS_bit         ; select the Data Register (RS high)
    cbi     lcd_E_port, lcd_E_bit           ; make sure E is initially low
    call    lcd_write_8                     ; write the data
    ret

; ---------------------------------------------------------------------------
; Name:     lcd_write_instruction_8d
; Purpose:  send a byte of information to the LCD instruction register
; Entry:    (temp) contains the data byte
; Exit:     no parameters
; Notes:    does not deal with RW (busy flag is not implemented)

lcd_write_instruction_8d:
    cbi     lcd_RS_port, lcd_RS_bit         ; select the Instruction Register (RS low)
    cbi     lcd_E_port, lcd_E_bit           ; make sure E is initially low
    call    lcd_write_8                     ; write the instruction
    ret

; ---------------------------------------------------------------------------
; Name:     lcd_write_8
; Purpose:  send a byte of information to the LCD module
; Entry:    (temp) contains the data byte
;           RS is configured for the desired LCD register
;           E is low
;           RW is low
; Exit:     no parameters
; Notes:    use either time delays or the busy flag

lcd_write_8:
; set up the data bits
    sbi     lcd_D7_port, lcd_D7_bit         ; assume that the data bit is '1'
    sbrs    temp, 7                         ; check the actual data value
    cbi     lcd_D7_port, lcd_D7_bit         ; arrive here only if the data was actually '0'

    sbi     lcd_D6_port, lcd_D6_bit         ; repeat for each data bit
    sbrs    temp, 6
    cbi     lcd_D6_port, lcd_D6_bit

    sbi     lcd_D5_port, lcd_D5_bit
    sbrs    temp, 5
    cbi     lcd_D5_port, lcd_D5_bit

    sbi     lcd_D4_port, lcd_D4_bit
    sbrs    temp, 4
    cbi     lcd_D4_port, lcd_D4_bit

    sbi     lcd_D3_port, lcd_D3_bit
    sbrs    temp, 3
    cbi     lcd_D3_port, lcd_D3_bit

    sbi     lcd_D2_port, lcd_D2_bit
    sbrs    temp, 2
    cbi     lcd_D2_port, lcd_D2_bit

    sbi     lcd_D1_port, lcd_D1_bit
    sbrs    temp, 1
    cbi     lcd_D1_port, lcd_D1_bit

    sbi     lcd_D0_port, lcd_D0_bit
    sbrs    temp, 0
    cbi     lcd_D0_port, lcd_D0_bit

; write the data
                                            ; 'Address set-up time' (40 nS)
    sbi     lcd_E_port, lcd_E_bit           ; Enable pin high
    call    delay1uS                        ; implement 'Data set-up time' (80 nS) and 'Enable pulse width' (230 nS)
    cbi     lcd_E_port, lcd_E_bit           ; Enable pin low
    call    delay1uS                        ; implement 'Data hold time' (10 nS) and 'Enable cycle time' (500 nS)
    ret

; ============================== End of 8-bit LCD Subroutines ===============

; ============================== Time Delay Subroutines =====================
; Name:     delayYx1mS
; Purpose:  provide a delay of (YH:YL) x 1 mS
; Entry:    (YH:YL) = delay data
; Exit:     no parameters
; Notes:    the 16-bit register provides for a delay of up to 65.535 Seconds
;           requires delay1mS

delayYx1mS:
    call    delay1mS                        ; delay for 1 mS
    sbiw    YH:YL, 1                        ; update the the delay counter
    brne    delayYx1mS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delayTx1mS
; Purpose:  provide a delay of (temp) x 1 mS
; Entry:    (temp) = delay data
; Exit:     no parameters
; Notes:    the 8-bit register provides for a delay of up to 255 mS
;           requires delay1mS

delayTx1mS:
    call    delay1mS                        ; delay for 1 mS
    dec     temp                            ; update the delay counter
    brne    delayTx1mS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delay1mS
; Purpose:  provide a delay of 1 mS
; Entry:    no parameters
; Exit:     no parameters
; Notes:    chews up fclk/1000 clock cycles (including the 'call')

delay1mS:
    push    YL                              ; [2] preserve registers
    push    YH                              ; [2]
    ldi     YL, low (((fclk/1000)-18)/4)    ; [1] delay counter
    ldi     YH, high(((fclk/1000)-18)/4)    ; [1]

delay1mS_01:
    sbiw    YH:YL, 1                        ; [2] update the the delay counter
    brne    delay1mS_01                     ; [2] delay counter is not zero

; arrive here when delay counter is zero
    pop     YH                              ; [2] restore registers
    pop     YL                              ; [2]
    ret                                     ; [4]

; ---------------------------------------------------------------------------
; Name:     delayTx1uS
; Purpose:  provide a delay of (temp) x 1 uS with a 16 MHz clock frequency
; Entry:    (temp) = delay data
; Exit:     no parameters
; Notes:    the 8-bit register provides for a delay of up to 255 uS
;           requires delay1uS

delayTx1uS:
    call    delay1uS                        ; delay for 1 uS
    dec     temp                            ; decrement the delay counter
    brne    delayTx1uS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delay1uS
; Purpose:  provide a delay of 1 uS with a 16 MHz clock frequency
; Entry:    no parameters
; Exit:     no parameters
; Notes:    add another push/pop for 20 MHz clock frequency

delay1uS:
    push    temp                            ; [2] these instructions do nothing except consume clock cycles
    pop     temp                            ; [2]
    push    temp                            ; [2]
    pop     temp                            ; [2]
    ret                                     ; [4]

; ============================== End of Time Delay Subroutines ==============
