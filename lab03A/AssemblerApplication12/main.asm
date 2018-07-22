;lab03 A
.include "m2560def.inc"
.def temp =r16
.def count=r17
.equ PATTERN1 = 0x5B
.equ PATTERN2 = 0xAA

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
.cseg
.org 0x0
ldi temp, 0b00001111
out PORTC, temp ; Write ones to all the LEDs
ser temp
out DDRC, temp ; PORTC is all outputs
out PORTF, temp ; Enable pull-up resistors on PORTF
clr temp
out DDRF, temp ; PORTF is all inputs
switch0:
sbic PINF, 0 ; Skip the next instruction if PB0 is pushed
rjmp switch1 ; If not pushed, check the other switch
rcall sleep_350ms
in temp, PORTC
cmp:
	cpi temp, 0
	breq over
dec temp
here:
out PORTC, temp
switch1:
sbic PINF, 1 ; Skip the next instruction if PB1 is pushed
rjmp switch0 ; If not pushed, check the other switch
rcall sleep_350ms
in temp,PORTC
cmp2:
	cpi temp, 0b00001111
	breq over2
inc temp
here2:
out PORTC, temp
rjmp switch0 ; Now check PB0 again

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
sleep_350ms:
	clr count 
	loop:
	cpi count, 70
	brne increase
	ret
increase:
	inc count
	rcall sleep_5ms
	rjmp loop
over:
	ldi temp,0b00001111
	rjmp here
over2:
	ldi temp,0
	rjmp here2
