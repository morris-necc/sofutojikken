INTERFACE:
	movem.l	%d0-%d3,-(%sp)
	
	/* Transmitter Interrupt */
	move.l	UTX1,	%d0
	btst.b	#15, %d0	/* Transmitter FIFO empty? 1 = empty, 0 = not empty*/
	beq	CALL_INTERPUT	/* not equal to 1*/
	
	/* Receiver Interrupt */
	move.w	URX1, %d3	/* Copy register URX1 to %d3.w*/
	move.b	%d3, %d2	/* Copy lower 8 bits (data part) of %d3.w to %d2.b*/
	btst.b	#13, %d3 	/* Receiver FIFO? 1 = not empty, 0 = empty, yes it's confusing*/ 
	beq	CALL_INTERGET	/* Basically, this checks if it is a receiver interupt*/
	
INTERFACE_END:	
	movem.l	(%sp)+, %d0-%d3
	rte
	
CALL_INTERPUT:
	move.l	#0, %d1
	jsr	INTERPUT
	jmp	INTERFACE_END

CALL_INTERGET:
	move.l	#0, %d1
	jsr	INTERGET
	jmp	INTERFACE_END
