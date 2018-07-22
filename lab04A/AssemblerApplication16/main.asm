;lab04 A 
.include "m2560def.inc"

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro
.equ PAT = 0b00110000
.equ PATTERN = 0b11000000
.equ MASK = 0b00111100
.def temp = r16
.def leds = r17
.def store = r18
.def second0 = r20
.def second1 = r21
.def minute0 = r22
.def minute1 = r23

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data1
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro clear
ldi YL, low(@0)
ldi YH, high(@0)
clr temp
st Y+,temp
st Y,temp
.endmacro
.dseg
SecondCounter: .byte 2
TempCounter: .byte 2
.cseg
.org 0x0000
jmp RESET
jmp DEFAULT
jmp DEFAULT
.org OVF0addr
jmp Timer0OVF
DEFAULT:reti

RESET:
	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL,temp
	ser temp
	out DDRC, temp

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	rjmp main
Timer0OVF:
	in temp, SREG
	push temp
	push YH
	push YL
	push r25
	push r24
	lds r24,TempCounter
	lds r25,TempCounter+1
	adiw r25:r24,1
	cpi r24,low(7812)
	ldi temp,high(7812)
	cpc r25,temp
	brne NotSecond
	
	in leds, PORTC
	mov store, leds
	ldi r19, MASK
	and store,r19
	cpi store,MASK
	breq oneMinute
	inc leds
	
	here:
	out PORTC,leds

	cpi second0,0b00111001
	breq zero
	inc second0
	section:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data1 minute1
	do_lcd_data1 minute0
	do_lcd_data ':'
	do_lcd_data1 second1
	do_lcd_data1 second0
	 
	clear TempCounter
	lds r24,SecondCounter
	lds r25,SecondCounter+1
	adiw r25:r24,1
	sts SecondCounter, r24
	sts SecondCounter+1,r25
	rjmp EndIF
oneMinute:
	ldi r19, PATTERN
	and leds,r19
	ldi r19 , 0b01000000
	add leds,r19
	rjmp here
zero:
	ldi second0,PAT
	cpi second1,0b00110101
	breq zero1
	inc second1
	rjmp section
zero1:
	ldi second1,PAT
	cpi minute0,0b00111001
	breq zero2
	inc minute0
	rjmp section
zero2:
	ldi minute0,PAT
	inc minute1
	rjmp section
NotSecond:
	sts TempCounter, r24
	sts TempCounter+1,r25
EndIF:
	pop r24
	pop r25
	pop YL
	pop YH
	pop temp
	out SREG,temp
	reti
main:
	ldi second0,PAT
	ldi second1,PAT
	ldi minute0,PAT
	ldi minute1,PAT
	ldi leds, 0xFF
	out PORTC,leds
	ldi leds,0b00000000
	clear TempCounter
	clear SecondCounter
	ldi temp,0b00000000
	out TCCR0A,temp     ;set mode 000- normal mode
	ldi temp,0b00000010
	out TCCR0B,temp     ;set prescaler - 8
	ldi temp, 1<<TOIE0  ;time overflow from 3 kinds of overflow cmpA,cmpB,time overflow
	sts TIMSK0,temp     ;apply to mask
	sei					;every timer overflow trigger an interrupt, when the times of interrupt is equal
						;to 7812(that is the times should happen in a second) add 1s

loop:rjmp loop

lcd_command:
	out PORTF, r16
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	nop
	nop
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
        nop
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret
.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret