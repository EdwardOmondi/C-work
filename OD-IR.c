/*
 * OD-IR.c
 *
 * Created: 01-Jul-19 5:34:19 PM
 * Author : Edward Omondi
 */ 

#define F_CPU 1000000UL	
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#define front 0b00000110	//go infront
#define back 0b00001001
#define left 0b00000101
#define right 0b00001010
#define stop 0x00

#define obj 0x00			//object detected
#define nl_obj 0x01			//no left object detected
#define nr_obj 0x02			//no right object detected

void gofront()
{
	PORTB = front;
	return;
}
void goback()
{
	PORTB = back;
	return;
}
void turnleft()
{
	PORTB = left;
	return;
}
void turnright()
{
	PORTB = right;
	return;
}

int main(void)
{
	DDRB = 0x0F;
	DDRA = 0x00;
	PORTA = 0x03;
	
	uint8_t l_sen = 0;
	uint8_t r_sen = 0;
	
	sei();
	
    while (1) 
    {
		l_sen = (PINA & nl_obj);
		r_sen = (PINA & nr_obj);
		
		if ((l_sen == obj)&& (r_sen == obj))
		{
			goback();
			_delay_ms(1000);
			turnleft();
			_delay_ms(500);
		}
		if ((l_sen == obj)&& (r_sen == nr_obj))
		{
			turnleft();
		}
		if ((l_sen == nl_obj)&& (r_sen == obj))
		{
			turnright();
		}
		if ((l_sen == nl_obj)&& (r_sen == nr_obj))
			gofront();
				
    }
}


	

