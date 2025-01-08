.include "equdefs.inc"

.global inbyte

.text
.even

inbyte:
	movem.l	%a0/%d1-%d3, -(%sp)/*store registers*/
	lea.l	BUF_INBYTE, %a0    /*%a0<- address the input character is stored*/
	
inbyte_loop:
	/* GETSTRING system call*/
	move.l	#SYSCALL_NUM_GETSTRING, %d0				/* GETSTRING*/
	move.l	#0, %d1		/* channel */
	move.l	%a0, %d2	/* head destination */
	move.l	#1, %d3		/* no. of data to be read */
	trap	#0				
	
	cmp.l	#0, %d0		/*check if GETSTRING is successful*/
	beq	inbyte_loop		/*if false , go back to the loop*/

	move.b	(%a0), %d0	/*copy input data to %d0*/
	move.b	%d0, LED1	/*to check if the scanf fct works fine*/

	movem.l	(%sp)+, %a0/%d1-%d3 /*recover registers*/
	
	rts

inkey:
	movem.l	%a0/%d1-%d3, -(%sp)
	lea.l	BUF_INBYTE, %a0
	
	move.l	%d0, %d1			/* put channel number*/

	move.l	#SYSCALL_NUM_GETSTRING, %d0			
	move.l	%a0, %d2			/* head destination */
	move.l	#1, %d3				/* no. of data to be read */
	trap	#0				

	cmp.l	#0, %d0
	beq	empty

	move.b	(%a0), %d0
	jmp	inkey_end
	
empty:	
	move.l	#0xffffffff, %d0

inkey_end:
	movem.l	(%sp)+, %a0/%d1-%d3
	rts

.section .bss
BUF_INBYTE: .ds.b 1
    .even

