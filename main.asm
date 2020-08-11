
; interrupts.asm
; Created: 5/12/2019 8:46:26 PM
; Author : Lenny,Ivy,Edward,Steve
; Replace with your application code

.include"m32def.inc"
.org $000
rjmp main
.org $002
rjmp int_0
.org $004
rjmp int_1
.org $006
rjmp int_2
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


int_1:  ;ISR for uploading 10 8-bit data serially
ldi r16,(1<<txen)|(1<<rxen);transmitter and reciver enable in UCSRB
out ucsrb,r16
ldi r16,(1<<ucsz1)|(1<<ucsz0)|(1<<ursel);initialize UCSRC for 8- bit data transmission
out ucsrc,r16
ldi r16,0x33;set baud rate of 9600bps in UBRRL
out ubrrl,r16
ldi r16,0xff
out ddrc,r16
sei;enable global interrupt
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ldi zh,high(loc1<<1) ;initialize z pointer
ldi zl,low(loc1<<1)
call prog
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
delay_ten_sec: ;delay of 5 seconds for 16Mhz and 10 seconds for 8Mhz
ldi r21,0xa
time:
ldi r20,0xfa
again:
ldi r18,0x64
loop:
ldi r17,0x6b
repeat:
dec r17
brne repeat
dec r18
brne loop
dec r20
brne again
dec r21
brne time
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
rjmp stop
stop:
reti
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
prog:
lpm r16,z+
cpi r16,0
breq check
call trx
rjmp prog
check:
ret
trx:
nop
nop
sbis ucsra,udre;skip next line if  udre bit in ucsra is set
rjmp trx
out udr,r16
ret
loc1:
.db "1","2","3","4","5","6","7","8","9","10",0

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
int_2:           ;serial control of a stepper motor
ldi r16,(1<<rxen);receiver enable in UCSRB
out ucsrb,r16
ldi r16,(1<<ucsz1)|(1<<ucsz0)|(1<<ursel);initialize UCSRC for 8- bit data transmission
out ucsrc,r16
ldi r16,0x33;set baud rate of 9600bps in UBRRL
out ubrrl,r16
sei;enable global interrupt
ldi r16,0xf0; make portD output for stepper
out ddrd,r16
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
scan:;scan for reception from terminal and turn in full steps according to inputs a, b,c,d from the user. Stop is letter s.
sbis ucsra,rxc
rjmp scan
rjmp motion
motion:
in r17,udr
ldi r16,0x61; ASCII  letter a
ldi r18,0x62; ASCII  letter b
ldi r19,0x63;ASCII  letter c
ldi r20,0x64;ASCII  letter d
ldi r21,0x73
step_1:;letter a pressed
cp r17,r16
brne step_2
ldi r22,0x90
out portd,r22
step_2:;letter b pressed
cp r17, r18
brne step_3
ldi r22,0xc0
out portd,r22
step_3:;letter c pressed
cp r17,r19
brne step_4
ldi r22,0x60
out portd,r22
step_4:;letter d pressed
cp r17,r20
brne halt
ldi r22,0x30
out portd,r22
halt:; return from the interrupt and resume main
cp r17,r21
brne scan
rjmp return
rjmp scan
rjmp return
return:
reti


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
int_0:		;interrupt sevice routine for pwm control of a dc motor
sbi ddrb,3 ;set pin B3 (oc0)pin as output
ldi r17,0x65
out tccr0,r17;phase correct mode,non-inverted,no prescaler
cbi ddrb,0;set pin B0 as input pin
cbi ddrb,6;set pin B6 as input pin
cbi ddrb,7;set pin B7 as input pin
sbi portb,0
sbi portb,6
sbi portb,7
ldi r17,0x1A
out ocr0,r17;initialize ocr0 to 225 for 10% duty cycle
cycle:;read port B to check for reset
ldi r16,0xcc
ldi r18,0x8d
ldi r20,0x4d
in r17,pinb;read status of pin B7
cp r17,r20
brne run
ldi r17,0xe1;90% duty cycle
out ocr0,r17
run:
cp r17,r18
brne cont
ldi r17,0x1A;10% duty cycle
out ocr0,r17
cont:
cp r17,r16
brne cycle;loop  if pin still high
ldi r17,0x00
out tccr0,r17;stop pwm
reti


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
main:;Main program and interrupt initialisation
ldi r16,high(ramend)	;initialise stack
out sph,r16
ldi r16,low(ramend)
out spl,r16
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
cbi ddrd,2;pin D2 is input
cbi ddrd,3;pin D3 is input
sbi portd,2;pins D2 and D3 set to high
sbi portd,3

cbi ddrb,2;pin B2 is input
sbi portb,2;pin B2 is high
ldi r18,0xe0;enable the int0 and int 1 and int2 interrupts
out gicr,r18
ldi r19,0x0c;configure int0 as low level triggered and int1 as rising edge trigerred
out mcucr,r19
ldi r20,0x00;int_2 is falling edge triggered
out mcucsr,r20
sei;enable global interrupt
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

normal_operation:
.equ en=PA3    ;enable pin
.equ rs=PA2		;register select pin
.equ rw=PA1		;write select pin
start:
ldi r16, 0xff  
out ddra, r16 ;configure port A as output
out ddrc, r16 ;configure port C as output
ldi r16,0x00    ; initialize both ports to low
out porta,r16
out portc,r16
call lcdinit

ldi zh,high(mesg<<1) ;initialize z pointer
ldi zl,low(mesg<<1)
call dsplystr
rjmp start
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
lcdinit:
ldi r16,0x01; clear lcd command
call cmndwrt
ldi r16,0x06; shift cursor right command
call cmndwrt
ldi r16,0x38; using 2 lines,8-bit mode command
call cmndwrt
ldi r16,0x0c; display on, cursor off command
call cmndwrt
ret

dsplystr:
lpm r16,z+
cpi r16,0
breq checking
call datawrt
rjmp dsplystr

checking:
 ret
 ;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

cmndwrt:
cbi porta,en
cbi porta,rs
cbi porta,rw
out portc,r16
sbi porta,en
call delay
cbi porta,en
ret
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

datawrt:
cbi porta,en
sbi porta,rs
cbi porta,rw
out portc,r16
sbi porta,en
call delay
cbi porta,en
ret
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


delay:;delay of 1/8 sec for 8Mhz
ldi r20,0x1f
_again:
ldi r18,0x64
_loop:
ldi r17,0x6b
_repeat:
dec r17
brne _repeat
dec r18
brne _loop
dec r20
brne _again
ret
mesg:
 .db	"Members Mechatronics_2019",0
		


;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------












