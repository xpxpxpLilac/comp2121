;
; AssemblerApplication9.asm
;
; Created: 26/08/2017 10:18:46 PM
; Author : Lilac Liu
;


; Replace with your application code
.include "m2560def.inc"
.def nv=r16
.def xv=r17
.def iv=r18
.def s_l=r19
.def s_m=r20
.def s_h=r21
.def r_l=r22
.def r_h=r23
.def a_i=r15
.macro multi
mov r30,@0
mov r31,@1
lsl r30
rol r31
add @0,r30
adc @1,r31
.endmacro 
.macro twobyone
clr r26
mov r16,@0
mov r17,@1
mul r16,@2
movw r22:r23,r0:r1
mul r17,@2
add r22,r3
adc r23,r0
adc r26,r1
.endmacro
.dseg
n:.byte 1
ex:.byte 1
.cseg
n_in:.db 10
x_in:.db 3
i:.db 0
sum:.dw 0
result:.dw 0
a:.db 0

main:
	
	ldi zl,low(n_in<<1)
	ldi zh,high(n_in<<1)
	lpm r16,z
	;lpm r17,z
	ldi zl,low(x_in<<1)
	ldi zh,high(x_in<1)
	lpm r17,z
	;lpm r18,z
	ldi xl,low(i<<1)
	ldi xh,high(i<<1)
	ld r18,x
	ldi r30,low(sum<<1)
	ldi r31,high(sum<<1)
	lpm r19,z+               ;why pointer x can't
	lpm r20,z
	ldi zl,low(result<<1)
	ldi zh,high(result<<1)
	lpm r21,z+
	lpm r22,z
	ldi yl,low(a)
	ldi yh,high(a)
	ld r23,x
	
	ldi r28,low(RAMEND-6)
	ldi r29,high(RAMEND-6)
	sbiw r28:r29,9
	out SPL,r28
	out SPH,r29
	std Y+9,nv
	std Y+8,xv
	std Y+7,iv
	std Y+6,s_l
	std Y+5,s_m
	std Y+4,s_h
	std Y+3,r_l
	std Y+2,r_h
	std Y+1,a_i
for:
	ldd xv,Y+8
	ldd nv,Y+9
	ldd r_l,Y+3
	ldd r_h,Y+2
	cp nv,iv
	brlo loopforever
	mov a_i,iv
	rcall power
	std Y+7,iv
	std Y+1,a_i
	twobyone r24,r25,a_i
	add s_l,r22
	adc s_m,r23
	adc s_h,r26
	mov r_l,r24
	mov r_h,r25
	std Y+3,r_l
	std Y+2,r_h
	inc iv
	rjmp for

loopforever: rjmp loopforever
power:
	push r28
	push r29
	push r16
	push r17
	push r18
	in r28,SPL
	in r29,SPH
	sbiw r28,2
	out SPH,r29
	out SPL,r28
	std Y+1,iv
	std Y+2,xv
	ldi r16,1
	ldi r24,1
	ldi r25,0
for2:
	ldd r18,Y+1   ;r18 power
	ldd r17,Y+2   ;r17 number
	cp r18,r16   ;r16 i 
	brlo L1
	multi r24,r25
	inc r16
	rjmp for2
L1:
	in r28,SPL
	in r29,SPH
	adiw r28:r29,2
	out SPL,r28
	out SPH,r29
	pop r18
	pop r17
	pop r16	
	pop r29
	pop r28
	ret