****************************************************************
** Various Register Definition
****************************************************************

/* Things to do: Interrupt vector setup, queue initializing routine */

*******************************
** Head of the Register Group
*******************************
	
.equ REGBASE, 0xFFF000 | DMAP is used.
.equ IOBASE, 0x00d00000

*******************************
** Registers Related to Interrupts
*******************************

.equ IVR, REGBASE+0x300 | Interrupt Vector Register
.equ IMR, REGBASE+0x304 | Interrupt Mask Register
.equ ISR, REGBASE+0x30c | Interrupt Status Register
.equ IPR, REGBASE+0x310 | Interrupt Pending Register

*******************************
** Registers Related to the Timer
*******************************

.equ TCTL1, REGBASE+0x600 |Timer1 Control Register
.equ TPRER1, REGBASE+0x602 |Timer1 Prescaler Register
.equ TCMP1, REGBASE+0x604 |Timer1 Compare Register
.equ TCN1, REGBASE+0x608 |Timer1 Counter Register
.equ TSTAT1, REGBASE+0x60a |Timer1 Status Register

*******************************
** Registers Related to UART1 (Transmitter and Receiver)
*******************************

.equ USTCNT1, REGBASE+0x900 |UART1 Status / Control Register
.equ UBAUD1, REGBASE+0x902 | UART 1 Baud Control Register
.equ URX1, REGBASE+0x904 | UART 1 Receiver register
.equ UTX1, REGBASE+0x906 | UART 1 Transmitter Register

*******************************
** LED
*******************************

.equ LED7, IOBASE+0x000002f | Register for LED mounted on the board
.equ LED6, IOBASE+0x000002d |Refer to Appendix A.4.3.1 for a way to use
.equ LED5, IOBASE+0x000002b
.equ LED4, IOBASE+0x0000029
.equ LED3, IOBASE+0x000003f
.equ LED2, IOBASE+0x000003d
.equ LED1, IOBASE+0x000003b
.equ LED0, IOBASE+0x0000039

****************************************************************
** Reservation of the stack region
****************************************************************

.section .bss
.even
SYS_STK:
.ds.b 0x4000 | System stack region
.even
SYS_STK_TOP: | End of the system stack region

****************************************************************
** Initialization
** A specific value has been set to internal device registers.
** Refer to each register specification in Appendix B to know the above reason.
****************************************************************

.section .text
.even
boot:
	* Prohibit an interrupt into the supervisor and during performing various settings.
	move.w #0x2700, %SR
	lea.l SYS_STK_TOP, %SP |Set SSP

	******************************
	**Initialization of the interrupt controller
	******************************

	move.b #0x40, IVR | Set the user interrupt vector| number to 0x40+level.
	move.l #0x00ff3ffb, IMR |Mask all interrupts, except UART1.

	******************************
	**Initialization of the interrupt vector
	******************************
	move.l #INTERFACEU, 0x110 	/* Level 4 user interrupt */
	** move.l #TIMER1_INTERRUPT, 0x118 /* Level 6 user interrupt*/

	******************************
	** Initialization related to the transmitter and the receiver (UART1)
	** (The interrupt level has been fixed to 4.)
	******************************

	move.w #0x0000, USTCNT1 | Reset
	move.w #0xe107, USTCNT1 |Transmission and reception possible |no parity, 1 stop, 8 bit|prohibit the UART1 interrupt
	move.w #0x0038, UBAUD1 |baud rate = 230400 bps

	*************************
	** Initialization related to the timer (The interrupt level has been fixed to 6.)
	*************************

	move.w #0x0004, TCTL1 | Restart, an interrupt impossible|Count the time with the 1/16 of the system clock|as a unit|Stop the timer use

	bra MAIN

****************************************************************
** Interrupt Controller
****************************************************************
	
INTERFACE:
	movem.l	%d0-%d3,-(%sp)
	
	/* Transmitter Interrupt */
	move.l	UTX1,	%d0
	btst.b	#15, %d0	/* Transmitter FIFO empty? 1 = empty, 0 = not empty*/
	bne	CALL_INTERPUT	/* not equal to 1*/
	
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

INTERGET:
	/* Input: Channel ch -> %d1, received data -> %d2 */
	/* No return value */
	/* Do we have to save running level??? */
	cmp	#0, %d1
	bne	INTERGET_END

	
	move.l	#0, %d0		/* Queue #0 */
	move.b	%d2, %d1 	/* move data to d1*/
	jsr	INQ		/* Do we have to do something for INQ failure?? */
INTERGET_END:
	rts

	
****************************************************************
** Timer
****************************************************************

TIMER_INTERRUPT:
	movem.l	%a0, -(%sp)		/* Evacuate registers */
	btst	#0, TSTAT1		/* Checks 0th bit of TSTAT1 */
	beq	TIMER_INTERRUPT_END
	move.w	#0x0000, TSTAT1		/* Reset TSTAT1 to 0 */
	jsr	CALL_RP
TIMER_INTERRUPT_END:
	movem.l	(%sp)+, %a0
	rte

RESET_TIMER:
	move.w 	#0x0004, TCTL1		/* Restart, an interrupt impossible, input is SYSCLK/16, prohibit timer */
	rts
SET_TIMER:
	/* D1.W = t (timer interrupt cycle, every 0.t msec) */
	/* D2.L = p (head address of the routine to be called at the interrupt occurrence) */
	/* STILL NEED TO DEFINE GLOBAL VARIABLE TASK_P IN THE .BSS SECTION */
	move.l	%d2, task_p		/* Substitute p for the global variable task_p*/
	move.w	#0x00CE, TPRER1 	/* Let counter increment by 1 every 0.1 msec*/
	move.w	%d1, TCMP1		/* Substitute t for the TCMP1 */
	move.w	#0x0015, TCTL1		/* Restart, enable compare interrupt, input is SYSCLK/16, permit timer */
	rts
CALL_RP:
	move.l	(task_p), %a0
	jsr	(%a0)
	rts
 
****************************************************************
** Queue
****************************************************************
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

*****************************************************************
** % Write in ‘a’ in the transmitter register UTX1 to confirm the normal initialization routine
** % operation at the present step. When ‘a’ is outputted, it’s OK.
*****************************************************************

.section .text
.even
MAIN :
	/* move.b #'1', LED1 */
	move.w #0x0800+'a', UTX1 |Refer to Appendix for the reason to add 0x0800
LOOP :
	bra LOOP

*****************************************************************
** Data section for testing
*****************************************************************
.section .data
	.equ	SIZE_of_QUEUE,	256
 
.section .bss
.even
top:		.ds.b	SIZE_of_QUEUE*2
inp:		.ds.l	2
outp:		.ds.l	2
s:		.ds.w	2
WORK:	.ds.b	256
