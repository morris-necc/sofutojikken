INTERPUT:
	/* Input: Channel ch -> %d1 */
	/* d0 = UTX1 at the end, we need %d0 to compare when we return to INTERFACE*/
	/* No return value */
	movem.l	%d2,-(%sp)
	move.l	%SR, %d2	/* Save running level */
	move.l	#0x2700, %SR	/* Set running level to 7 */

	cmp	#0, %d1		/* Return without doing anything if ch=/=0*/
	bne	INTERPUT_END

	move.l	#1, %d0		/* Queue #1 */
	jsr	OUTQ		/* Substitute it for data?? */
				/* d1 is data */

	cmp	#0, %d0 	/* OUTQ failure? */
	beq	MASK_TRANSMITTER_INTERRUPT
	
	add.l	#0x0800, %d0
	move.w 	%d0, UTX1	/* Substitute the data for the transmitter register UTX1 */
				/* And transmit it??? */
MASK_TRANSMITTER_INTERRUPT:
	andi 	#0xfff8, USTCNT1 /* Mask the transmitter interrupt */
INTERPUT_END:
	move.l	%d2, %SR	/* Restore running level */
	movem.l	(%sp)+, %d2
	rts
