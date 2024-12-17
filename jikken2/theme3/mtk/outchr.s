.global outbyte

.text
.even

*****************
**  Outbyte
*****************
/* char-type arg, output data to serial port 0 */
outbyte:
	movem.l	%d0-%d3/%a0, -(%sp)
	move.l 	%sp, %a0
	add.l	#24, %a0		/* a0 = ch (argument) */

TRY:	
	move.l	#2, %d0
	move.l	%a0, %d1		/*ch = a0*/
	
	add.l	#7, %a0			/*a0 = char*/
	
	move.l	%a0, %d2		/*p = a0*/
	move.l	#1, %d3			/*size = %d0 (The length of a given string)*/	
	trap	#0

	cmp	#0, %d0
	beq 	TRY

	movem.l	(%sp)+, %d0-%d3/%a0
	rts
