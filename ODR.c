/*
 * ODR.c
 *
 * Created: 06-Jun-19 10:42:41 PM
 * Author : Edward Omondi
 */ 

#define F_CPU 1000000UL					//8MHz
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#define front	0b00001010
#define back	0b00000101
#define left	0b00001001
#define right	0b00000110
unsigned int TimerOverflow = 0;ISR(TIMER1_OVF_vect)
{
	TimerOverflow++;					//Track number of overflows
}

int main(void)
{
	unsigned int distance = 0;
	unsigned int t1 = 0;
	unsigned int t2 = 0;
	
    DDRB = 0x0F;						//Make wheel  pins output
	DDRD = 0x01;						//Make sensor pinD1 output
	//PORTD = 0b01000000;					//Make PD6 a 1 
	DDRC = 0xFF;
	_delay_ms(50);
	
	//set up timer1
	TCCR1A = 0;
	TIFR = (1<<ICF1);					//Clear the input capture flag
	TIFR = (1<<TOV1);					//Clear Timer Overflow flag
	TCCR1B |= (1<<ICES1)|(1<<CS10);		//Clock with no prescaling, time capture on a high  
	
	sei();
	TIMSK = (1 << TOIE1);				// Enable Timer1 overflow interrupts 
	
    while (1) 
    {		
		PORTB = front;					//Drive robot infront
		
		//send a pulse to the sensor
		PORTD |= (1<<PIND0);
		_delay_ms(100);
		PORTD &= ~(1<<PIND0);
		_delay_ms(100);
		
		//Get time for first rising edge 
		while ((TIFR & (1 << ICF1)) == 0);
		{
			t1 = ICF1 + (65535 * TimerOverflow);//Store value in t1
			TCNT1 = 0;				//Clear Timer counter
			TIFR = (1<<ICF1);			//Clear ICP flag (Input Capture flag)
			TIFR = (1<<TOV1);			//Clear Timer Overflow flag
			TimerOverflow = 0;			//Reset Timer overflow count
		}
		
		//Get time for second rising edge
		while ((TIFR & (1 << ICF1)) == 0);
		{
			t2 = ICR1 + (65535 * TimerOverflow);//Store value in t2
			TCNT1 = 0;					//Clear Timer counter
			TIFR = 1<<ICF1;				//Clear ICP flag (Input Capture flag)
			TIFR = 1<<TOV1;				//Clear Timer Overflow flag
			TimerOverflow = 0;			//Clear Timer overflow count
		}
		
		distance = (t1-t2)/ 466.47;		//Distance to object
		
		if (distance<=5)
		{
			PORTB = left;
			PORTC = 0xFF;				//turn the robot left
			_delay_ms(2000);			//Turn for 2 secs
			PORTC= 0x00;				
		}
    }
}

