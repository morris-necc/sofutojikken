****************************************************************
** Various Register Definition
****************************************************************

/* Echo back process */
/* Data inputted from keyboard -> Receiver Interrupt -> INTERGET*/
/* -> GETSTRING -> PUTSTRING -> Transmitter Interrupt ->  INTERPUT */
/* -> Output to display */

*******************************
** System call numbers 
*******************************

.equ SYSCALL_NUM_GETSTRING, 1 
.equ SYSCALL_NUM_PUTSTRING, 2 
.equ SYSCALL_NUM_RESET_TIMER, 3 
.equ SYSCALL_NUM_SET_TIMER, 4 
	
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
	move.l #0x00ff3ff9, IMR |Mask all interrupts, except UART1.

	******************************
	**Initialization of the interrupt vector
	******************************
 	move.l #SYSCALL, 0x080		/* Trap #0 interrupt */
	move.l #INTERFACE, 0x110 	/* Level 4 user interrupt */
	move.l #TIMER_INTERRUPT, 0x118 	/* Level 6 user interrupt*/

	******************************
	** Initialization related to the transmitter and the receiver (UART1)
	** (The interrupt level has been fixed to 4.)
	******************************

	move.w #0x0000, USTCNT1 | Reset
	move.w #0xe13f, USTCNT1 |Transmission and reception possible |no parity, 1 stop, 8 bit|enable the UART1 interrupt
	move.w #0x0038, UBAUD1 |baud rate = 230400 bps

	*************************
	** Initialization related to the timer (The interrupt level has been fixed to 6.)
	*************************

	move.w #0x0004, TCTL1 | Restart, an interrupt impossible|Count the time with the 1/16 of the system clock|as a unit|Stop the timer use

	
	jsr	INIT_Q 		/* Initialize Queue */

	bra 	MAIN

*************************************
** SYSTEM CALL INTERFACE
**###################################
** input:
**	d0: system call number
**	d1~: system call arg
** output:
** 	d0: the call result
*************************************
SYSCALL:
	cmpi.l	#SYSCALL_NUM_GETSTRING, %d0
	beq	CALL_GETSTRING
	cmpi.l	#SYSCALL_NUM_PUTSTRING, %d0
	beq	CALL_PUTSTRING
	cmpi.l	#SYSCALL_NUM_RESET_TIMER, %d0
	beq	CALL_RESET_TIMER
	cmpi.l	#SYSCALL_NUM_SET_TIMER, %d0
	beq	CALL_SET_TIMER
	rte
	
CALL_GETSTRING:
	jsr	GETSTRING
	rte
CALL_PUTSTRING:
	jsr	PUTSTRING
	rte
CALL_RESET_TIMER:
	jsr	RESET_TIMER
	rte
CALL_SET_TIMER:
	jsr	SET_TIMER
	rte


****************************************************************
** Interrupt Controller
****************************************************************
	
INTERFACE:
	movem.l	%d0-%d3,-(%sp)
	
	move.b	#'4', LED3
	
	/* Transmitter Interrupt */
	move.l	UTX1, %d0
	/* btst.b	#15, %d0 */	/* Transmitter FIFO empty? 1 = empty, 0 = not empty*/
	andi.l	#0x8000, %d0
	beq	RECEIVER_TEST	/* not equal to 1*/
	jmp	CALL_INTERPUT
	
	
RECEIVER_TEST:	
	move.b	#'3', LED2
	
	/* Receiver Interrupt */
	move.w	URX1, %d3	/* Copy register URX1 to %d3.w*/
	move.b	%d3, %d2	/* Copy lower 8 bits (data part) of %d3.w to %d2.b*/
	andi.l	#0x2000, %d3
	/* btst.b	#13, %d3 */	/* Receiver FIFO? 1 = not empty, 0 = empty, yes it's confusing*/ 
	beq	INTERFACE_END	/* Basically, this checks if it is a receiver interupt*/
	bra	CALL_INTERGET
	
INTERFACE_END:	
	movem.l	(%sp)+, %d0-%d3
	rte
	
CALL_INTERPUT:
	move.b	#'5', LED4
	
	move.l	#0, %d1
	jsr	INTERPUT
	jmp	INTERFACE_END

CALL_INTERGET:
	move.l	#0, %d1
	move.b	#'2', LED1
	jsr	INTERGET
	jmp	INTERFACE_END

	
INTERPUT:
	/* Input: Channel ch -> %d1 */
	/* d0 = UTX1 at the end, we need %d0 to compare when we return to INTERFACE*/
	/* No return value */
	
	movem.l	%d2,-(%sp)
	move.w	%SR, %d2	/* Save running level */
	move.w	#0x2700, %SR	/* Set running level to 7 */
	cmp.l	#0, %d1		/* Return without doing anything if ch=/=0*/
	bne	INTERPUT_END

	move.l	#1, %d0		/* Queue #1 */
	jsr	OUTQ		/* Substitute it for data?? */
				/* d1 is data */

	cmp.l	#0, %d0 	/* OUTQ failure? */
	beq	MASK_TRANSMITTER_INTERRUPT
	
	add.l	#0x0800, %d1
	move.w 	%d1, UTX1	/* Substitute the data for the transmitter register UTX1 */
	bra INTERPUT_END
	
MASK_TRANSMITTER_INTERRUPT:
	andi 	#0xfff8, USTCNT1 /* Mask the transmitter interrupt */
INTERPUT_END:
	move.w	%d2, %SR	/* Restore running level */
	movem.l	(%sp)+, %d2
	rts

INTERGET:
	/* Input: Channel ch -> %d1, received data -> %d2 */
	/* No return value */
	/* Do we have to save running level??? */
	movem.l	%d0, -(%sp)
	
	cmpi.l	#0, %d1
	bne	INTERGET_END
	
	move.l	#0, %d0		/* Queue #0 */
	move.b	%d2, %d1 	/* move data to d1*/
	jsr	INQ		/* Do we have to do something for INQ failure?? */
INTERGET_END:
	movem.l	(%sp)+, %d0
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
	lea.l	task_p, %a0
	jsr		(%a0)
	rts

****************************************************************
** Putstring
****************************************************************

PUTSTRING:
	/* Input: Channel ch -> d1, Head address p -> d2, No. of data -> d3 */
	/* Output: no. of data actually sent -> d0 */
	movem.l	%d4/%a0, -(%sp)
	cmp.l	#0, %d1
	bne	PUTSTRING_END	/* If ch =/= 0, end */

	move.l	#0, %d4		/* d4 = sz */
	move.l	%d2, %a0	/* a0 = i */

	cmp.l	#0, %d3
	beq	PUTSTRING_UPD_SZ
	
PUTSTRING_LOOP:
	cmp.l	%d4, %d3	/* If sz == size */
	beq	PUTSTRING_UNMASK
	
	move.b	(%a0)+, %d1	/* Put data in d1 */
	move.l	#1, %d0		/* Use queue 1 */
	jsr	INQ
	
	cmp.l	#0, %d0		/* If INQ failed*/
	beq	PUTSTRING_UNMASK

	addq	#1, %d4		/* Increment sz and i */
	
	bra	PUTSTRING_LOOP

PUTSTRING_UNMASK:
	ori 	#0x0007, USTCNT1 	/* Permit the transmitter interrupt */

PUTSTRING_UPD_SZ:	
	move.l	%d4, %d0		/* %d0 <- sz */
	
PUTSTRING_END:
	movem.l	(%sp)+, %d4/%a0
	rts

****************************************************************
** Getstring
****************************************************************

/* Read out data of size bytes from the receiver queue of the channel ch */
/* And copy them to address p and after */
/* Return value d0 (readout data size) */
/* When the receiver queue becomes empty, the data aren't read out anymore */
/* That is, the data as many as a readable number o pieces lte size are read out */
/* Implement so as not to execute anything when the channel ch is not 0 */

GETSTRING:
	/* Input: ch -> d1, head address of destination p -> d2, no. of data to be read -> d3 */
	/* Output: no. of data actually read out -> d0 */
	movem.l	%d4/%a0, -(%sp)

	cmpi.l	#0, %d1
	bne	GETSTRING_END	/* If ch =/= 0, end */

	move.l	#0, %d4		/* d4 = sz (Used to count no. of data actually read out) */
	move.l	%d2, %a0	/* a0 = i (NOT Index, but head address of destination) */
	

GETSTRING_LOOP:
	cmp.l	%d4, %d3	/* is sz == size? */
	beq	GETSTRING_UPD_SZ

	move.l	#0, %d0		/* specify queue 0 */
	jsr	OUTQ		/* Call OUTQ, puts data in d1 */

	cmpi.l	#0, %d0			/* If failure */
	beq	GETSTRING_UPD_SZ	/* End GETSTRING */

	move.b	%d1, (%a0)+	/* Copy the data to address i */
	
	addq	#1, %d4		/* Increment sz and i */
	jmp	GETSTRING_LOOP

GETSTRING_UPD_SZ:	
	move.l	%d4, %d0	/* %d0 <- sz */
	
GETSTRING_END:
	movem.l	(%sp)+, %d4/%a0
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
	/* Input: Queue no. -> %d0, Data -> %d1 */
	/* Output: Success/fail -> %d0 */
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
	/* Input: Queue no. -> %d0 */
	/* Output: Success/fail -> %d0, Data -> %d1 */
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
	/*  test*/
	move.w	#0x2000, %SR 	/* Set running level */
	
	move.b  #'8', LED6
		
RESET_TIMER:
	move.l	#0x100000, %d5
	move.l	#0, %d4

TIMER:
	subq.l	#1, %d5
	bne	TIMER
	
	move.l	#0x100000, %d5
	addq	#1, %d4
	move.b  #'6', LED5
	cmp	#5, %d4
	blt	TIMER

	
LOOP :
	move.b	#'1', LED0

	move.l	#0, %d1		/* Channel 0? */
	lea.l	WORK, %a1
	move.l	%a1, %d2	
	move.l	#256, %d3
	jsr	GETSTRING
	
	
	move.l	#0, %d1		/* Channel 0? */
	move.l	%a1, %d2	/* PLEASSEEEE LET THIS BE THE CASE */
				/* d2 is changed in the interface */
				/* which is why you have to reset it */
				/* and that's why you get weird characters showing up */
				/* PUTSTRING works, but it's got the head address wrong*/
				/* But this doesn't solve getting stuck before the timer*/
	move.l	#16, %d3	/* size = 16? */
	jsr	PUTSTRING
	
	bra 	RESET_TIMER

task_p:
	bra 	MAIN

*****************************************************************
** Data section for testing
*****************************************************************
.section .data
	.equ	SIZE_of_QUEUE,	256
TDATA1:	.ascii	"0123456789ABCDEF"
TDATA2:	.ascii	"klmnopqrstuvwxyz"
 
.section .bss
.even
top:		.ds.b	SIZE_of_QUEUE*2
inp:		.ds.l	2
outp:		.ds.l	2
s:		.ds.w	2

WORK:	.ds.b	256
