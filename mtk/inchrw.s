.include "equdefs.inc"

.global inbyte

.text
.even

inbyte:
    movem.l %d1-%d3, -(%sp)
inbyte_start:
    move.l	#1, %d0             /* GETSTRING */
    move.l	#0, %d1			    /*ch = 0*/
    move.l	#BUF_INBYTE, %d2
    move.l	#1, %d3
    trap	#0

    cmpi.b	#1, %d0
    bne     inbyte_start

    clr.l	%d0
    move.b  BUF_INBYTE, %d0
    move.b  %d0, 0x00d00039     /* debug LED0 */

    movem.l (%sp)+, %d1-%d3
    rts

	

inbyte_test:
	movem.l	%a0/%d1-%d3, -(%sp)
	lea.l	BUF_INBYTE, %a0
	
inbyte_loop_test:
	/* At some point, GETSTRING is called */
	move.l	#SYSCALL_NUM_GETSTRING, %d0				/* GETSTRING*/
	move.l	#0, %d1				/* channel */
	move.l	%a0, %d2			/* head destination */
	move.l	#1, %d3				/* no. of data to be read */
	trap	#0				
	
	cmp.l	#0, %d0
	beq	inbyte_loop_test

	move.b	(%a0), %d0
	move.b	%d0, LED7

	movem.l	(%sp)+, %a0/%d1-%d3
	
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

