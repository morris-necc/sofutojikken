GETSTRING:
	/* Input: ch -> d1, head address of destination p -> d2, no. of data to be read -> d3 */
	/* Output: no. of data actually read out -> d0 */
	movem.l	%d4/%a0, -(%sp)

	cmpi.l	#0, %d1
	bne	GETSTRING_END	/* If ch =/= 0, end */

	move.l	#0, %d4		/* d4 = sz (Used to count no. of data actually read out) */
	move.l	%d2, %a0	/* a0 = i (NOT Index, but head address of destination) */
	

GETSTRING_LOOP:
	cmp	%d4, %d3	/* is sz == size? */
	beq	GETSTRING_END

	move.l	#0, %d0		/* specify queue 0 */
	jsr	OUTQ		/* Call OUTQ, puts data in d1 */

	cmpi.l	#0, %d0			/* If failure */
	beq	GETSTRING_UPD_SZ	/* End GETSTRING */

	move.b	%d1, (%a0)	/* Copy the data to address i */
	
	addq	#1, %d4		/* Increment sz and i */
	addq	#1, %a0
	jmp	GETSTRING_LOOP

GETSTRING_UPD_SZ:	
	move.l	%d4, %d0	/* %d0 <- sz */
	
GETSTRING_END:
	movem.l	(%sp)+, %d4/%a0
	rts
