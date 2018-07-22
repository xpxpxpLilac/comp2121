;lab03 B why it does twice??
.include "m2560def.inc" 
.def temp =r16 
.def count=r17


.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
.cseg 
.org 0x0 
jmp RESET 
.org INT0addr    ; INT0addr is the address of EXT_INT0  
jmp EXT_INT0 
.org INT1addr    ; INT1addr is the address of EXT_INT1 
jmp EXT_INT1 ;
; AssemblerApplication17.asm
RESET: 
	ldi temp, low(RAMEND) 
	out SPL, temp 
	ldi temp, high(RAMEND) 
	out SPH, temp 
	ser temp 
	out DDRC, temp			;portc is output
	ldi temp,0b00001111 
	out PORTC, temp
	clr temp 
	out DDRD, temp			;portD is input
	out PORTD, temp 
	ldi temp, (2 << ISC10) | (2 << ISC00) 
	sts EICRA, temp 
	in temp, EIMSK 
	ori temp, (1<<INT0) | (1<<INT1) 
	out EIMSK, temp  
	sei 
	jmp main 

EXT_INT0: 
	rcall sleep_350ms 
	push temp 
	in temp, SREG 
	push temp 
	in temp, PORTC
	cpi temp, 0b00000000
	breq pb0_over
	dec temp
load:
	out PORTC, temp 
	pop temp 
	out SREG, temp 
	pop temp 
	reti 
 
EXT_INT1: 
	rcall sleep_350ms
	rcall sleep_350ms
	push temp 
	in temp, SREG 
	push temp 
	in temp, PORTC
	cpi temp,0b00001111
	breq pb1_over
	inc temp
load2: 
	out PORTC, temp 
	pop temp 
	out SREG, temp 
	pop temp 
	reti 
main:                   ; main - does nothing but increment a counter 
	clr temp 
loop: 
	inc temp 
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
sleep_350ms:
	clr count 
	d_loop:
	cpi count, 70
	brne increase
	ret
increase:
	inc count
	rcall sleep_5ms
	rjmp d_loop
pb0_over:
	ldi temp,0b00001111
	rjmp load
pb1_over:
	ldi temp,0b00000000
	rjmp load2