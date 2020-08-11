/*
 * Door Code.c
 *
 * Created: 29-Jul-19 7:56:54 PM
 * Author : Edward Omondi
 */ 

#include <avr/io.h>
#define F_CPU 1000000UL
#include <util/delay.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <stdlib.h>

#define RS 5
#define RW 6
#define E 7

int hrs,mins,secs=0,overflow=0;
char show_hr[2],show_min[2],show_sec[2];
int min_pressed, hr_pressed;

char Check_key()
{
	unsigned char keypad[3][4] = {	{'1','4','7','*'},
									{'2','5','8','0'},
									{'3','6','9','#'}};
									//{'/','0','-','+'}};
	unsigned char colloc, rowloc;
	
	while(1)
	{
		DDRB = 0xF0;				//set port direction as input-output
		PORTB = 0xFF;
		
		do
		{
			PORTB &= 0x0F;			//mask PORT for column read only
			asm("NOP");
			colloc = (PINB & 0x0F);	//read status of column
		}
		while(colloc != 0x0F);
		
		do
		{
			do
			{
				_delay_ms(20);             /* 20ms key debounce time */
				colloc = (PINB & 0x0F); /* read status of column */
			}
			while(colloc == 0x0F);        /* check for any key press */
			_delay_ms (20);	            /* 20 ms key debounce time */
			colloc = (PINB & 0x0F);
		}
		while(colloc == 0x0F);
		
		//now check for rows
		PORTB = 0xEF;				//check for pressed key in 1st row PORTB = 0b1110 1111
		asm("NOP");
		colloc = (PINB & 0x0F);
		if(colloc != 0x0F)
		{
			rowloc = 0;
			break;
		}
		
		PORTB = 0xDF;				//check for pressed key in 2nd row PORTB = 0b1101 1111
		asm("NOP");
		colloc = (PINB & 0x0F);
		if(colloc != 0x0F)
		{
			rowloc = 1;
			break;
		}
		
		PORTB = 0xBF;				//check for pressed key in 3rd row PORTB = 0b1011 1111
		asm("NOP");
		colloc = (PINB & 0x0F);
		if(colloc != 0x0F)
		{
			rowloc = 2;
			break;
		}
		
		PORTB = 0x7F;				//check for pressed key in 4th row PORTB = 0b0111 1111
		asm("NOP");
		colloc = (PINB & 0x0F);
		if(colloc != 0x0F)
		{
			rowloc = 3;
			break;
		}
	}
	if(colloc == 0x0E)				//0000 1110
	return(keypad[rowloc][0]);
	else if(colloc == 0x0D)			//0000 1101
	return(keypad[rowloc][1]);
	else if(colloc == 0x0B)			//0000 1011
	return(keypad[rowloc][2]);
	else							//0000 0111
	return(keypad[rowloc][3]);
}

void Send_A_Command(unsigned char command)
{
	PORTA = command;
	PORTD &= ~(1<<RS);
	PORTD |= (1<<E);
	_delay_ms(50);
	PORTD &= ~(1<<E);
	PORTD = 0;
}

void Send_A_Character(unsigned char character)
{
	PORTA = character;
	PORTD |= (1<<RS);
	PORTD |= (1<<E);
	_delay_ms(50);
	PORTD &= ~(1<<E);
	PORTD = 0;
}

void Send_A_String(char *stringOfChar)
{
	while(*stringOfChar>0)
	{
		Send_A_Character(*stringOfChar++);
	}
}

void LCD_Initialise()
{
	Send_A_Command(0x01); //Clear Screen
	_delay_ms(1);
	Send_A_Command(0x38); //2 lines and 5×7 matrix (8-bit mode)
	_delay_ms(1);
	Send_A_Command(0x0E); //Display on, cursor blinking
	_delay_ms(1);
}

void showtime()
{ 
	itoa(hrs/10,show_hr,10);
	Send_A_String(show_hr);
	itoa(hrs%10,show_hr,10);
	Send_A_String(show_hr);
	Send_A_String (":");
	itoa(mins/10,show_min,10);
	Send_A_String(show_min);
	itoa(mins%10,show_min,10);
	Send_A_String(show_min);	
	Send_A_String (":");
	itoa(secs/10,show_sec,10);
	Send_A_String(show_sec);
	itoa(secs%10,show_sec,10);
	Send_A_String(show_sec);
	Send_A_Command(0xC0);	
}

void setup()
{
	//timer1 setup
	TCNT1 = 0;			//count entire register
	TCCR1A = 0x00;
	TCCR1B = (1<<CS11);		//set the pre-scalar as 8
	TIMSK = (1 << TOIE1) ;   // Enable timer1 overflow interrupt(TOIE1)
	PORTD |= (1<<PD2) | (1<<PD3);

	//interrupt setup
	GICR = 1<<INT0|1<<INT1;
	MCUCSR = 1<<ISC00|1<<ISC10;
	sei();
}

void last_time()
{
	itoa(hr_pressed/10,show_hr,10);
	Send_A_String(show_hr);
	itoa(hr_pressed%10,show_hr,10);
	Send_A_String(show_hr);
	Send_A_String (":");
	itoa(min_pressed/10,show_min,10);
	Send_A_String(show_min);
	itoa(min_pressed%10,show_min,10);
	Send_A_String(show_min);
	Send_A_String (":");
	itoa(secs/10,show_sec,10);
	Send_A_String(show_sec);
	itoa(secs%10,show_sec,10);
	Send_A_String(show_sec);
	Send_A_Command(0x80);
}

ISR (TIMER1_OVF_vect)    // Timer1 ISR
{
	overflow++;
	if (overflow >= 2)
	{
		if (secs < 60)
		{
			secs++;
		}
		if (secs >= 60)
		{
			if (mins < 60)
			{
				mins++;
			}
			if (mins >= 60)
			{
				if (hrs<24)
				{
					hrs++;
				}
				if (hrs >= 24)
				{
					hrs = 0;
				}
				mins = 0;
			}
			secs = 0;
		}
		overflow = 0;
	}
	
	
}

ISR(INT0_vect)
{
	wdt_enable(WDTO_15MS);
}

ISR(INT1_vect)
{
	min_pressed = mins;
	hr_pressed = hrs;
	char key[4];			//character displayed
	int i;
	int key_p[4];			//key pressed
	PORTD |= (1<<PD2) | (1<<PD3);
	
	Send_A_Command(0x01);
	Send_A_String("Input Pin:");
	Send_A_Command(0xC0);
	
	for (i=0; i<=4; i++)
	{
		key[i] = Check_key();
		Send_A_Character('*');
		key_p[i] = key[i]-'0';
	}
	if (key_p[0]==0 && key_p[1]==0 && key_p[2]==0 && key_p[3]==0 && key_p[4]==0)
	{
		PORTC = 0b00000001;
		_delay_ms(5000);
		PORTC = 0b00000000;
		Send_A_Command(0x01);
	}
	else
	{
		PORTC =0b00000010;
		_delay_ms(1000);
		Send_A_Command(0x01);
	}
	return;
	wdt_enable(WDTO_1S);	
}

int main(void)
{
	
	DDRA = 0xFF;
	DDRC = 0xFF;
	DDRD = 0xF0;
  
	LCD_Initialise();
	setup();  
	
	while (1)
	{
		showtime();
		last_time();
	}
}


