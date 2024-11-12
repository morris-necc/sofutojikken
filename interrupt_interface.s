INTERFACE:
	movem.l	%d0-%d3,-(%sp)
	
	/* Receiver Interrupt */
	move.w	URX1, %d3	/* Copy register URX1 to %d3.w*/
	btst.l	#13, %d3 	/* Receiver FIFO? 1 = not empty, 0 = empty, yes it's confusing*/ 
	bne	CALL_INTERGET	/* Basically, this checks if it is a receiver interupt*/
	
	
	/* Transmitter Interrupt */
	move.w	UTX1, %d3
	btst.l	#15, %d3	/* Transmitter FIFO empty? 1 = empty, 0 = not empty*/
	bne	CALL_INTERPUT	/* not equal to 1*/
	
	
INTERFACE_END:	
	movem.l	(%sp)+, %d0-%d3
	rte
	
CALL_INTERPUT:
	move.l	#0, %d1
	jsr	INTERPUT
	bra	INTERFACE_END

CALL_INTERGET:
	move.l	#0, %d1
	move.b	%d3, %d2	/* Copy lower 8 bits (data part) of %d3.w to %d2.b*/
	jsr	INTERGET
	bra	INTERFACE_END
