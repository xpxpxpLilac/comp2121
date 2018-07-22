;lab04 B
.include "m2560def.inc"
.def temp =r21
.def row =r17
.def col =r18
.def mask =r19
.def temp2 =r20
.def count =r22
.def line =r23
.equ PORTLDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F
.equ base = 48

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
.macro do_lcd_data_imme
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.cseg
.org 0x0
jmp RESET

RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, PORTLDIR ; columns are outputs, rows are inputs
STS DDRL, temp     ; cannot use out
ser temp
out DDRC, temp ; Make PORTC all outputs
out PORTC, temp ; Turn on all the LEDs
out DDRF, temp
out DDRA, temp
clr temp
out PORTF, temp
out PORTA, temp

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
	clr line

; main keeps scanning the keypad to find which key is pressed.
main:
ldi mask, INITCOLMASK ; initial column mask
clr col ; initial column
colloop:
	STS PORTL, mask ; set column to mask value
; (sets column 0 off)
	ldi temp, 0xFF ; implement a delay so the
; hardware can stabilize
delay:
	dec temp
	brne delay
	LDS temp, PINL ; read PORTL. Cannot use in 
	andi temp, ROWMASK ; read only the row bits
	cpi temp, 0xF ; check if any rows are grounded
	breq nextcol ; if not go to the next column
	ldi mask, INITROWMASK ; initialise row check
	clr row ; initial row
rowloop:      
	mov temp2, temp
	and temp2, mask ; check masked bit
	brne skipconv ; if the result is non-zero,
; we need to look again
	rcall convert ; if bit is clear, convert the bitcode
	jmp main ; and start again
skipconv:
	inc row ; else move to the next row
	lsl mask ; shift the mask to the next bit
	jmp rowloop          
nextcol:     
	cpi col, 3 ; check if we^Òre on the last column
	breq main ; if so, no buttons were pushed,
; so start again.

	sec ; else shift the column mask:
; We must set the carry bit
	rol mask ; and then rotate left by a bit,
; shifting the carry into
; bit zero. We need this to make
; sure all the rows have
; pull-up resistors
	inc col ; increment column value
	jmp colloop ; and check the next column
; convert function converts the row and column given to a
; binary number and also outputs the value to PORTC.
; Inputs come from registers row and col and output is in
; temp.
convert:
	rcall sleep_350ms                                             ;add a debouncing here, at first it's not stable,when we detect a key pushed
	cpi col, 3 ; if column is 3 we have a letter					;wait until disturbing signal disappear then convert					
	breq letters
	cpi row, 3 ; if row is 3 we have a symbol or 0
	breq symbols
	mov temp, row ; otherwise we have a number (1-9)
	lsl temp ; temp = row * 2
	add temp, row ; temp = row * 3
	add temp, col ; add the column address
; to get the offset from 1
	inc temp ; add 1. Value of switch is
; row*3 + col + 1.
	ldi r16,base
	add temp,r16
	jmp convert_end
letters:
	ldi temp, 0xA
	add temp, row ; increment from 0xA by the row value
	ldi r16,55
	add temp, r16
	jmp convert_end
symbols:
	cpi col, 0 ; check if we have a star
	breq star
	cpi col, 1 ; or if we have zero
	breq zero
	ldi temp, 0xF ; we'll output 0xF for hash
	ldi r16,20
	add temp,r16
	jmp convert_end
star:
	ldi temp, 0xE ; we'll output 0xE for star
	ldi r16,28
	add temp,r16
	jmp convert_end
zero:
	ldi temp,base
convert_end:
	out PORTC, temp ; write value to PORTC
	cpi line,16
	breq new_line											;count when it shold be a new line
print:
	inc line
	do_lcd_data_imme temp
	ret ; return to caller


new_line:
	do_lcd_command 0b00000001
	clr line
	rjmp print

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
