/*
 * Code.c
 *if (bit_is_clear(PINB, 1))
 * Created: 22-Jul-19 8:59:30 PM
 * Author : Edward Omondi
 */ 

#include <avr/io.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>

#define RS 5
#define RW 6
#define E 7

long int j;

void Send_A_Command(unsigned char command)
{
	PORTD = command;
	PORTC &= ~(1<<RS);
	PORTC |= (1<<E);
	_delay_ms(50);
	PORTC &= ~(1<<E);
	PORTD = 0;
}

void Send_A_Character(unsigned char character)
{
	PORTD = character;
	PORTC |= (1<<RS);
	PORTC |= (1<<E);
	_delay_ms(50);
	PORTC &= ~(1<<E);
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

void First_message()
{
	Send_A_String("Hi");
	
	Send_A_Command (0xC0);	//New line
	
	Send_A_String("Input the time:");
}

void Error_message1()
{
	Send_A_String("Sorry. Please start again");
}

void Error_message2()
{
	Send_A_String("Wrong button");
}

char Check_key()
{
	unsigned char keypad[4][4] = {	{'7','4','1',' '},
									{'8','5','2','0'},
									{'9','6','3','='},
									{'/','*','-','+'}};
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

void timer_initialise()
{
	TCNT1 = 41000;			//set timer register at 2^16-count timefor a second (31249)
	
	TCCR1A = 0x00;
	TCCR1B = (1<<CS12);		//set the pre-scalar as 256
	TIMSK = (1 << TOIE1) ;   // Enable timer1 overflow interrupt(TOIE1)
	sei();
}

/*void WDT_ON()
{
	WDTCR = (1<<WDE)|(1<<WDP2)|(1<<WDP1);// watchdog timer with 1 sec
}

void WDT_OFF()
{
	WDTCR = (1<<WDTOE)|(1<<WDE);
	WDTCR = 0x00;
}*/

ISR (TIMER1_OVF_vect)    // Timer1 ISR
{
	j--;
	TCNT1 = 41000;   // for 1 sec at 16 MHz
	PORTA ^= (1 << 1);
	if(j<=0)
	{
		PORTA |= (1<<0);
		Send_A_Command(0x01);
		Send_A_String("Time's up");
		wdt_enable(WDTO_15MS);
	}
}

int main(void)
{
	MCUCSR = (1<<JTD);					//disabling JTAG to enable  use of PORTC
	MCUCSR = (1<<JTD);	
	
	DDRA = 0xFF;
	DDRB = 0xf0;
	DDRC |= (1<<E) | (1<<RW) | (1<<RS);
	DDRD = 0xFF;
			
	char key[6];			//character displayed
	int i;
	int key_p[6];			//key pressed
	int min,sec;
	
	sei();
	
	key[0] = Check_key();
	LCD_Initialise();
	if (key[0] == ' ')
	{
		First_message();
		_delay_ms(10);
		Send_A_Command(0x01);	
		for (i=1; i<=4; i++)
		{
			key[i] = Check_key();
			
			if (i == 3)
			{
				Send_A_Character(':');
			}
			Send_A_Character(key[i]);
		}
		key[5] = Check_key();
		if (key[5]=='+')
		{
			for (i=1; i<=4; i++)
			{
				key_p[i] = key[i]-'0';
			}
			
			min = key_p[1]*10+key_p[2];
			sec  = key_p[3]*10+key_p[4];
			j = min*60+sec;
			
			timer_initialise();	
			
			if (j<=0)
			{
				_delay_ms(100);
				wdt_enable(WDTO_1S);
			}
				
			
		}else
		{
		Error_message2();
		wdt_enable(WDTO_1S);
		}
			
	}else
	{
		Error_message1();
		wdt_enable(WDTO_1S);
	} 	
	
}


