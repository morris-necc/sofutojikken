*********************************************
** function: INTERGET
**###########################################
** input:
**	d1:	channel number
**	d2:	received data
** output:
**	none
*********************************************

CALL_INTERGET:
	move.l	#0, %d1			/* d0 channel number */
	jsr INTERGET
	jmp INTERFACE_END
	
INTERGET:
	movem.l	%d0-%d2, -(%sp)		/* evacuate */
	
	/* step (1) */
	cmp	#0, %d1			/* Return without doing anything if ch=/=0*/
	bne	INTERPUT_END
	
	/* step (2) */
	move.l	#0, %d0			/* set to Queue #0 */
	move.w	%d2, %d1		/* PUT INPUT DATA TO d1 */
	jsr	INQ			/* go to queue input function */
	
	movem.l	(%sp)+, %d0-%d2		/* de-evacuate */
	
	rts
