;lab05 A
.include "m2560def.inc"

.def temp = r16
.def leds = r17
.def hundred = r18
.def ten = r19
.def last = r20
.equ base = 10

.macro clear
ldi YL, low(@0)
ldi YH, high(@0)
clr temp
st Y+,temp
st Y,temp
.endmacro
.macro clear_byte
ldi YL, low(@0)
ldi YH, high(@0)
clr temp
st Y,temp
.endmacro
.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_data_im
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro convert_base
	lds temp, @0
	ldi r20,48
	add temp, r20
.endmacro
.macro get_hundred
	clr hundred
	loop1:
	ldi r16,0b01100100
	cp @0, r16
	brlo no_hundred
	sub @0,r16
	inc hundred
	rjmp loop1
no_hundred:nop
.endmacro
.macro get_ten
	clr ten
	loop2:
	ldi r16,0b00001010
	cp @0, r16
	brlo no_ten
	sub @0,r16
	inc ten
	rjmp loop2
no_ten:nop
.endmacro
.dseg
SecondCounter: .byte 2
TempCounter: .byte 2
digit0: .byte 1
digit1: .byte 1
digit2: .byte 1
Speed: .byte 1
.cseg
.org 0x0000
jmp RESET
jmp DEFAULT
jmp DEFAULT
.org INT2addr    ; INT1addr is the address of EXT_INT1 
jmp EXT_INT2
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
	ldi temp, (2 << ISC20)   ;enable external int2
	sts EICRA, temp 
	in temp, EIMSK 
	ori temp, (1<<INT2)
	out EIMSK, temp
	clear_byte Speed
	clear_byte digit0
	clear_byte digit1
	clear_byte digit2
	sei
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

EXT_INT2:
	push temp 
	in temp, SREG 
	push temp 
	lds r24,Speed
	inc r24
	sts Speed,r24
	pop temp 
	out SREG, temp 
	pop temp 
	reti 

NotSecond:
	sts TempCounter, r24
	sts TempCounter+1,r25
	rjmp EndIF
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
	cpi r24,low(781)
	ldi temp,high(781)
	cpc r25,temp
	brne NotSecond
		
	com leds
	out PORTC,leds
	clear TempCounter
	lds r24,SecondCounter
	lds r25,SecondCounter+1
	adiw r25:r24,1
	sts SecondCounter, r24
	sts SecondCounter+1,r25

	do_lcd_command 0b00000001
	lds r24,Speed
	lsr r24                    ;divide four
	lsl r24
	mov r16, r24
	lsl r24
	lsl r24
	add r24, r16
	get_hundred r24
	sts digit2, hundred
	get_ten r24 
	sts digit1, ten
	sts digit0, r24
	convert_base digit2
	do_lcd_data_im temp
	convert_base digit1
	do_lcd_data_im temp
	convert_base digit0
	do_lcd_data_im temp
	;do_lcd_data '0'
	clear_byte Speed
	clear_byte digit0
	clear_byte digit1
	clear_byte digit2
	rjmp EndIF

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
	ldi leds,0b11110000
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

;
; Send a command to the LCD (r16)
;

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
; 4 cycles per iteration - setup/call-return overhead

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