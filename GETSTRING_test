.section .text
.even

****************************************************************
** Putstring
****************************************************************

PUTSTRING:
	/* Input: Channel ch -> d1, Head address p -> d2, No. of data -> d3 */
	/* Output: no. of data actually sent -> d0 */
	movem.l	%d4/%a0, -(%sp)
	cmp	#0, %d1
	bne	PUTSTRING_END	/* If ch =/= 0, end */

	move.l	#0, %d4		/* d4 = sz */
	move.l	%d2, %a0	/* a0 = i */

	cmp	#0, %d3
	beq	PUTSTRING_END
	
PUTSTRING_LOOP:
	cmp	%d4, %d3	/* If sz == size */
	beq	PUTSTRING_UNMASK
	
	move.b	(%a0), %d1	/* Put data in d1 */
	move.l	#1, %d0		/* Use queue 1 */
	jsr	INQ
	cmp	#0, %d0		/* If INQ failed*/
	beq	PUTSTRING_UNMASK

	addq	#1, %d4		/* Increment sz and i */
	addq	#1, %a0
	jmp	PUTSTRING_LOOP

PUTSTRING_UNMASK:
	move.l	%d4, %d0		/* %d0 <- sz */
	ori 	#0x0007, USTCNT1 	/* Permit the transmitter interrupt */
	
PUTSTRING_END:
	movem.l	(%sp)+, %d4/%a0
	rts

MAIN :
	/* INTERPUT test*/
	move.w	#0x2700, %SR
	
	
	jsr	INIT_Q 		/* Initialize Queue */
	move.l	#1000000, %d5

TIMER:
	move.w	#0x2000, %SR /* Set running level to 0*/

	move.l	#0, %d1		/* Channel 0? */
	lea.l	WORK, %a1
	move.l	%a1, %d2	/* Idk if this works */
	move.l	#256, %d3
	jsr	GETSTRING

	subq	#1, %d5
	cmpi	#1, %d5
	bgt	TIMER

	bra 	LOOP
	
LOOP :
	move.w	#0x2000, %SR /* Set running level to 0*/
	
	move.l	#0, %d1		/* Channel 0? */
	move.l	#16, %d3	/* size = 16? */
	jsr	PUTSTRING
	
	bra 	LOOP

task_p:
	bra 	MAIN
