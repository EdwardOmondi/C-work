/*
 * C.c
 *
 * Created: 23-May-19 7:11:55 PM
 * Author : Edward Omondi
 */ 

#define F_CPU 1000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#define RS PB5
#define RW PB6
#define E  PB7
#define get_bit(reg,bitnum) ((reg & (1<<bitnum))>>bitnum)

void send_a_command (unsigned char command);
void send_a_character(unsigned char character);

/*Interrupt Service Routines for INT0 INT1 and INT2*/
ISR (INT0_vect)
{
	//To be coded
}

ISR (INT1_vect)
{
	while (1)
	{
		for(int i=0;i<12;i++)		/* Rotate Stepper Motor clockwise with Half step sequence; Half step angle 3.75 */
		{
			PORTC = 0x09;
			_delay_ms(100);
			PORTC = 0x08;
			_delay_ms(100);
			PORTC = 0x0C;
			_delay_ms(100);
			PORTC = 0x04;
			_delay_ms(100);
			PORTC = 0x06;
			_delay_ms(100);
			PORTC = 0x02;
			_delay_ms(100);
			PORTC = 0x03;
			_delay_ms(100);
			PORTC = 0x01;
			_delay_ms(100);
		}
		PORTC = 0x09;				/* last one step to acquire initial position */
		_delay_ms(100);
		_delay_ms(1000);
		for(int i=0;i<12;i++)		/* Rotate Stepper Motor Anticlockwise with Half step sequence; Half step angle 3.75 */
		{
			PORTC = 0x09;
			_delay_ms(100);
			PORTC = 0x01;
			_delay_ms(100);
			PORTC = 0x03;
			_delay_ms(100);
			PORTC = 0x02;
			_delay_ms(100);
			PORTC = 0x06;
			_delay_ms(100);
			PORTC = 0x04;
			_delay_ms(100);
			PORTC = 0x0C;
			_delay_ms(100);
			PORTC = 0x08;
			_delay_ms(100);
		}
		PORTC = 0x09;
		_delay_ms(100);
		_delay_ms(1000);
	}
}

ISR (INT2_vect)
{
	PORTD = 0x00; 
	TCCR0 = 0x75;					//Configure TCCR0 
	TIMSK = 0x00;
	OCR0 = 255;						// Set OCR0 to 255 so that the duty cycle is initially 0 and the motor is not rotating

	while(1)
	{
		if (get_bit(PIND,5)==1)
		{
			OCR0 = 250;				//If button 1 is pressed, set OCR0=250 (duty cycle=5%).
		}
		if (get_bit(PIND,6)==1)
		{
			OCR0 = 130;				//If button 2 is pressed, set OCR0=102 (duty cycle=50%).
		}
		if (get_bit(PIND,7)==1)
		{
			OCR0 = 10;				//If button 3 is pressed, set OCR0=25 (duty cycle=95%).
		}
	}
}

void send_a_command (unsigned char command)
{
	PORTA = command;
	PORTB &= ~(1<<RS);
	PORTB |= (1<<E);
	_delay_ms(50);
	PORTB &= ~(1<<E);
	PORTA = 0;
}

void send_a_character (unsigned char character)
{
	PORTA = character;
	PORTB |= (1<<RS);
	PORTB |= (1<<E);
	_delay_ms(50);
	PORTB &= ~(1<<E);
	PORTA = 0;
}
int main(void)
{
	DDRA = 0xFF;
	DDRC = 0xFF;					/* Make PORTC as output PORT*/
	DDRB = 0xE8;
	DDRD = 0x00;
	
									/* Trigger INT0 and INT1 on rising edge */
	MCUCR |= (1<<ISC01) | (1<<ISC00) | (1<<ISC11) | (1<<ISC10);
									/*Trigger INT2 on rising edge*/
	MCUCSR |= (1<<ISC2);
									/* Enable INT0 INT1 and INT2*/
	GICR |= (1 << INT0) | (1 << INT1) | (1 << INT2);
	
	sei();							/* Enable Global Interrupts */
	
	while (1)
	{
		_delay_ms(50);
		send_a_command(0x01);		// sending all clear command
		send_a_command(0x38);		// 16*2 line LCD
		send_a_command(0x0E);		// screen and cursor ON
		
		send_a_character (0x4D);	// ASCII code for 'M'
		send_a_character (0x45);	// ASCII code for 'E'
		send_a_character (0x4D);	// ASCII code for 'M'
		send_a_character (0x42);	// ASCII code for 'B'
		send_a_character (0x45);	// ASCII code for 'E'
		send_a_character (0x52);	// ASCII code for 'R'
		send_a_character (0x53);	// ASCII code for 'S'
		
		send_a_command(0x14);		// move cursor right by one character
		
		send_a_character (0x4D);	// ASCII code for 'M'
		send_a_character (0x45);	// ASCII code for 'E'
		send_a_character (0x43);	// ASCII code for 'C'
		send_a_character (0x48);	// ASCII code for 'H'
		send_a_character (0x41);	// ASCII code for 'A'
		send_a_character (0x54);	// ASCII code for 'T'
		send_a_character (0x52);	// ASCII code for 'R'
		send_a_character (0x4F);	// ASCII code for 'O'
		send_a_character (0x4E);	// ASCII code for 'N'
		send_a_character (0x49);	// ASCII code for 'I'
		send_a_character (0x43);	// ASCII code for 'C'
		send_a_character (0x53);	// ASCII code for 'S'
		send_a_character (0x5F);	// ASCII code for '_'
		send_a_character (0x32);	// ASCII code for '2'
		send_a_character (0x30);	// ASCII code for '0'
		send_a_character (0x31);	// ASCII code for '1'
		send_a_character (0x39);	// ASCII code for '9'	
		
		_delay_ms(2000);	  
	}
	return 0;
}

