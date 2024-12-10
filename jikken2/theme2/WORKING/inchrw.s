.global inbyte

.text
.even

**********************
**  Inbyte
**********************
/* return one character (char-type) read out from the serial port 0, no arg */
inbyte:
	movem.l	%d1-%d3/%a0, -(%sp)
	lea.l	SERIAL_PORT_0, %a0
TRY:
	move.l	#1, %d0
	move.l	#0, %d1			/*ch = 0*/
	move.l	%a0, %d2		/*p = #BUF*/
	move.l	#1, %d3			/*size = 1*/
	trap	#0

	cmpi.b	#0, %d0
	beq 	TRY
	
	clr.l	%d0
	move.b  (%a0), %d0
	move.b  %d0, 0x00d00039     /* debug LED0 */

	movem.l	(%sp)+, %d1-%d3/%a0
	rts
*********************
** Inkey (EXTRA)
*********************
/* return unsigned int value (0x00 to 0xff) if single char is input, else -1*/

.section .bss
SERIAL_PORT_0:	.ds.b 1
	.even
