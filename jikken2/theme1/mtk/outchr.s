.global outbyte

.include "equdefs.inc"

.text
.even

outbyte:
    move.b  7(%sp), BUF_OUTBYTE /* the argument is stored in the 
    last byte of the extended long word*/
    movem.l %d0-%d3, -(%sp)     /*store registers*/
outbyte_start:
    move.l	#SYSCALL_NUM_PUTSTRING, %d0             /* call PUTSTRING */
    move.l	#0, %d1
    move.l	#BUF_OUTBYTE, %d2
    move.l	#1, %d3
    trap	#0

    cmpi.b	#1, %d0 /*checks if PUTSTRING is successful*/
    bne     outbyte_start /*if not goes back to the loop*/

    movem.l (%sp)+, %d0-%d3
    rts

.section .bss
    .even
BUF_OUTBYTE:    .ds.b 1
    .even
