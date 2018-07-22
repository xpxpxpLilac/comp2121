;lab03 D clock with timer0 interrupt
.include "m2560def.inc"
.equ PATTERN = 0b11000000
.equ MASK = 0b00111100
.def temp = r16
.def leds = r17
.def store = r18
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
	clear TempCounter
	lds r24,SecondCounter
	lds r25,SecondCounter+1
	adiw r25:r24,1
	sts SecondCounter, r24
	sts SecondCounter+1,r25
	rjmp EndIF
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
oneMinute:
	ldi r19, PATTERN
	and leds,r19
	ldi r19 , 0b01000000
	add leds,r19
	rjmp here










	