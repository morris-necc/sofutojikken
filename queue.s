.section .text
*****************************************************************
** Queues
*****************************************************************

Main:
  /* just for testing */
	jsr 	INIT_Q
	/* d0 = queue number */
	/* d1 = data */
	move.w	#0xaa, %d1
	/* d2, d3 = counter */
	move.l	#257, %d2
	move.l	%d2, %d3
		
LOOPIN1:
	move.l	#0, %d0 	/* use queue 0 */
	subi	#1, %d3
	jsr	INQ

	cmpi	#0, %d3
	bne	LOOPIN1
	move.l	%d2, %d3
LOOPIN2:
	move.l	#1, %d0
	subi	#1, %d3
	jsr	INQ
  
	cmpi	#0, %d3
	bne	LOOPIN2
	move.l	%d2, %d3

  jsr INQ  /* test inputting in a full queue */
LOOPOUT1:
	move.l	#0, %d0
	subi	#1, %d3
	jsr	OUTQ

	
	cmpi	#0, %d3
	bne	LOOPOUT1
	move.l	%d2, %d3
  jsr OUTQ  /* test outputting from an empty queue */
LOOPOUT2:
	move.l	#1, %d0
	subi	#1, %d3
	jsr	OUTQ
	
	cmpi	#0, %d3
	bne	LOOPOUT2
	stop	#0x2700

	
INIT_Q:
	movem.l	%a1-%a4, -(%sp)
  
	lea.l	top, %a1		/*top address is a1*/
	lea.l  	inp, %a2
	lea.l  	outp, %a3
	lea.l  	s, %a4
  
	move.l	%a1, (%a2)+  /* Initialize inp, outp, and s for q0*/
	move.l	%a1, (%a3)+
	move.w	#0, (%a4)+

	adda  	#SIZE_of_QUEUE, %a1  /* add offset for q1 */

	move.l	%a1, (%a2)  /* Initialize inp, outp, and s for q1*/
	move.l	%a1, (%a3)
	move.w	#0, (%a4)
  
	movem.l	(%sp)+, %a1-%a4
	rts

INQ:
	movem.l	%d2-%d5/%a1-%a5,-(%sp)    /* Save registers */
	jsr	Q_START
	lea.l 	inp, %a2		/* inp -> a2 */
	adda.l  %d2, %a2    /* add offset */
	move.l  (%a2), %a1  /* a1 = in pointer */
  
	jsr	INQ_SIZE_CHECK
	jmp 	Q_FINISH

INQ_SIZE_CHECK:
	cmp.w	#256, (%a3)   /* check if queue is full */
	bne	INQ_SUCC		/*if s not equals to 256*/
	bra	Q_FAIL		  /*if s==256*/

INQ_SUCC:
	move.b 	%d1, (%a1)  /* d1 = data moved into inp */
	addq    #1, (%a3)    /* Increment size */

	jmp     Q_SUCC

OUTQ:
	movem.l	%d2-%d5/%a1-%a5,-(%sp)    /* Save registers */
	jsr     Q_START

	lea.l 	outp, %a2		/* outp -> a2 */
	adda.l  %d2, %a2    /* add offset */
	move.l  (%a2), %a1  /* a1 = out pointer */

	jsr	OUTQ_SIZE_CHECK
	jmp 	Q_FINISH

OUTQ_SIZE_CHECK:
	cmp.w 	#0, (%a3)    /* check if queue is empty*/
	bgt 	OUTQ_SUCC
	bra	Q_FAIL

OUTQ_SUCC:
	move.b	(%a1), %d1 /* data is moved to d1*/
	subi.w  #1, (%a3)    /* Decrement size */

	jmp 	Q_SUCC
  

/* These are common for both INQ and OUTQ */
Q_START:
	move.w	%SR, %d5    /* Save running level */
	move.w 	#0x2700, %SR	/* running level = 7 */
  
	move.l 	%d0, %d2   /* d2 = pointer offset */
	mulu	#4,  %d2   /* because address is stored in longword */
  
	move.l  %d0, %d3   /* d3 = queue size pointer offset */
	mulu	#2, %d3	   /* because address is stored in word */
  
	lea.l	s,   %a3    /* size -> a3 */
	adda.l  %d3, %a3    /* add offset */
	rts

Q_SUCC:
	move.l 	%d0, %d4   /* d4 = queue area offset */
	mulu	#SIZE_of_QUEUE, %d4
	lea.l   top, %a4  /* a4 = head of queue area */
	adda.l  %d4, %a4  /* adds offset */
	move.l  %a4, %a5  /* a5 = bottom of queue area */
	adda.l  #SIZE_of_QUEUE, %a5  /* the bottom is 256 from the top */

	move.l  #1, %d0     /* success flag raised */

	cmp	%a1, %a5
	beq	Q_BACK		/*reach the bottom*/
	bra	Q_NEXT

Q_NEXT:
	addq	#1, %a1    /* increment input/output pointer*/
	rts

Q_BACK:
	move.l	%a4, %a1  /* input/output pointer set to head of queue area */
	rts	

Q_FAIL:
	move.l	#0, %d0    /* set flag to fail */
	rts

Q_FINISH:
	move.l	%a1, (%a2)    /* update inp/outp */
	move.w	%d5, %SR      /* restore previous running level */
	movem.l	(%sp)+,%d2-%d5/%a1-%a5  /* restore registers */
	rts


.section .data
	.equ	SIZE_of_QUEUE,	256

.section .bss
top:		.ds.b	SIZE_of_QUEUE*2
inp:		.ds.l	2
outp:		.ds.l	2
s:		.ds.w	2

.end