;lab03 C clock with software delay
.include "m2560def.inc"
.def temp = r16
.def leds = r17
.def store = r18
.def count = r20
.equ PATTERN = 0b11000000
.equ MASK = 0b00111100
.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
.cseg
.org 0x0000
jmp RESET
RESET:
	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL,temp
	ser temp
	out DDRC, temp
	rjmp main
main:
	ldi leds, 0xFF
	out PORTC,leds
	ldi leds,0b00000000
loop:
	rcall sleep_1000ms
	in leds, PORTC
	mov store, leds
	ldi r19, MASK
	and store,r19
	cpi store,MASK
	breq oneMinute
	inc leds
	here:
	out PORTC, leds
	rjmp loop
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
sleep_1000ms:
	clr count 
	sloop:
	cpi count, 200
	brne increase
	ret
increase:
	inc count
	rcall sleep_5ms
	rjmp sloop
oneMinute:
	ldi r19, PATTERN
	and leds,r19
	ldi r19 , 0b01000000
	add leds,r19
	rjmp here