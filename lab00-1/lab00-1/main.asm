;
; lab00-1.asm
;
; Created: 8/08/2017 9:33:20 PM
; Author : Lilac Liu
;


; Replace with your application code
.include "m2560def.inc"

start:
    ldi r16, 200
	ldi r17, 100
	add r16,r17
halt:
    rjmp halt
