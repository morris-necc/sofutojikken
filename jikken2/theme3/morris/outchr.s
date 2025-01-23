.include "equdefs.inc"
.global outbyte

.text
.even

outbyte:
	movem.l %d1-%d3/%a1, -(%sp)	/* STORE REGISTERS */
outbyte_loop:
	movea.l	%sp,   %a1			/* copy head address of stack pointer */
	move.l	#23,   %d2			/* add address offset */
	adda.l	%d2,   %a1			/* get character*/

	move.b	(%a1), BUF_OUTBYTE		/* copy data to BUF_OUTBYTE */

	move.l  #1,    %d2			
	adda.l  %d2,   %a1			/* ch stored right next to character */

	/* SYSCALL: PUTSTRING */
	move.l #SYSCALL_NUM_PUTSTRING, %d0
	move.l (%a1),  %d1         	| ch = fd
	move.l #BUF_OUTBYTE, %d2       	| p  = #BUF_OUTBYTE
	move.l #1, %d3          	| size = 1
	trap #0

	/* FLAG CHECK */
	cmp.l #0, %d0				/* see if PUTSTRING is successful */
	beq outbyte_loop			/* if false, retry */

	/* SUCCESS */
	movem.l (%sp)+, %d1-%d3/%a1 		/* RESTORE REGISTERS */
	rts
        
.section .bss
.even

.global BUF_OUTBYTE
BUF_OUTBYTE:
	.ds.b 1
	.even
