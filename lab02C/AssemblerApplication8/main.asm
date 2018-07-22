;
; AssemblerApplication8.asm
;
; Created: 26/08/2017 4:23:17 PM
; Author : Lilac Liu
;


; Replace with your application code
.include "m2560def.inc"
.dseg
counter:.byte 2
.cseg
n:.db 8
A:.db 1
B:.db 3
C:.db 2
main:
	ldi r24,low(1)
	ldi r25,high(1)
	ldi xl,low(counter)
	ldi xh,high(counter)
	ld r22,x+                        ;why can't use lpm
	ld r23,x
	ldi r28,low(RAMEND)
	ldi r29,high(RAMEND)
	out SPH,r29
	out SPL,r28
	ldi r30,low(n<<1)
	ldi r31,high(n<<1)
	lpm r16,z                       ;why can't usw ld
    ldi r30,low(A<<1)
	ldi r31,high(A<<1)
	lpm r17,z
	ldi r30,low(B<<1)
	ldi r31,high(B<<1)
	lpm r18,z
	ldi r30,low(C<<1)
	ldi r31,high(C<<1)
	lpm r19,z
	rcall move
	rjmp loopforever
loopforever: rjmp loopforever
move:
	push r28
	push r29
	in r28,SPL
	in r29,SPH
	sbiw r29:r28,4
	out SPH,r29
	out SPL,r28
	std Y+1,r19
	std Y+2,r18
	std Y+3,r17
	std Y+4,r16
L1:
	cpi r16,1
	breq equl
	ldd r16,Y+4
	ldd r17,Y+3
	ldd r18,Y+1
	ldd r19,Y+2
	subi r16,1
	rcall move
L3:
	ldi r16,1
	ldd r17,Y+3
	ldd r18,Y+2
	ldd r19,Y+1
	rcall move
	ldd r16,Y+4
	ldd r17,Y+1
	ldd r18,Y+2
	ldd r19,Y+3
	subi r16,1
	rcall move
L2:
	adiw r29:r28,4
	out SPH,r29
	out SPL,r28
	pop r29
	pop r28
	ret
equl:
	add r22,r24
	adc r23,r25
	rjmp L2
	