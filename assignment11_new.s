************************************* 
** Typing Practice
** Display character string on screen		**DONE, needs fixing**
** Let user input the character screen		**DOING, needs fixing**
** Don't output a failed input to screen	**DONE, needs testing & fixing **
** Change time limit depending on the length of a character string	** NOT done, just needs copas tbh**
** Count the numbers of correct & failed inputs and display each 	** DONE, needs testing **
** Calculate the typing speed (characters per minute) & display it	** DONE, needs testing **
************************************* 

************************************* 
** Current Bugs
** 1. "ara" is printed before every line after every print is called
** 		This could be either before/after the prints
** 		Check the emulator
** 2. Subroutine WAIT does not work
** 		It printed both the texts from INTRO and GAMEMODE
** 		Either there's something wrong with PUTSTRING outputting way more than it needs to
** 		Or WAIT somehow going back to both subroutines??? (this makes no sense)
** 		Anyways, try bugtesting without WAIT to see if this is a result of PRINT
** 		Oh, and WAIT isn't actually waiting it seems
************************************* 


********************
** System call numbers 
******************** 
    .equ    SYSCALL_NUM_GETSTRING, 1 
    .equ    SYSCALL_NUM_PUTSTRING, 2 
    .equ    SYSCALL_NUM_RESET_TIMER, 3 
    .equ    SYSCALL_NUM_SET_TIMER, 4 

******************************
** Head of the Register Group
*******************************
    .equ    REGBASE, 0xFFF000 | DMAP is used.
    .equ    IOBASE, 0x00d00000
*******************************
** Registers Related to Interrupts
*******************************
    .equ    IVR, REGBASE+0x300 | Interrupt Vector Register
    .equ    IMR, REGBASE+0x304 | Interrupt Mask Register
    .equ    ISR, REGBASE+0x30c | Interrupt Status Register
    .equ    IPR, REGBASE+0x310 | Interrupt Pending Register
*******************************
** Registers Related to the Timer
*******************************
    .equ    TCTL1, REGBASE+0x600 	|Timer1 Control Register
    .equ    TPRER1, REGBASE+0x602 	|Timer1 Prescaler Register
    .equ    TCMP1, REGBASE+0x604 	|Timer1 Compare Register
    .equ    TCN1, REGBASE+0x608 	|Timer1 Counter Register
    .equ    TSTAT1, REGBASE+0x60a 	|Timer1 Status Register
*******************************
** Registers Related to UART1 (Transmitter and Receiver)
*******************************
    .equ    USTCNT1, REGBASE+0x900 	|UART1 Status / Control Register
    .equ    UBAUD1, REGBASE+0x902 	| UART 1 Baud Control Register
    .equ    URX1, REGBASE+0x904 	| UART 1 Receiver register
    .equ    UTX1, REGBASE+0x906 	| UART 1 Transmitter Register
*******************************
** LED
*******************************
    .equ    LED7, IOBASE+0x000002f 	| Register for LED mounted on the board
    .equ    LED6, IOBASE+0x000002d 	| Refer to Appendix A.4.3.1 for a way to use
    .equ    LED5, IOBASE+0x000002b
    .equ    LED4, IOBASE+0x0000029
    .equ    LED3, IOBASE+0x000003f
    .equ    LED2, IOBASE+0x000003d
    .equ    LED1, IOBASE+0x000003b
    .equ    LED0, IOBASE+0x0000039
    .equ    PUSHSW, 0xFFF419 		| Register for Push Switch mounted on the board
****************************************************************
** Reservation of the stack region
****************************************************************
.section .bss
.even
SYS_STK:
    .ds.b   0x4000  | System stack region
    .even
SYS_STK_TOP:        | End of the system stack region
****************************************************************
** Initialization
** A specific value has been set to internal device registers.
** Refer to each register specification in Appendix B to know the above reason.
****************************************************************
.section .text
.even
boot:
* Prohibit an interrupt into the supervisor and during performing various settings.
    move.w  #0x2700, %SR	    | run at lv.0
    lea.l   SYS_STK_TOP, %SP    | Set SSP
******************************
**Initialization of the interrupt controller
******************************
    move.b  #0x40, IVR                  | Set the user interrupt vector number to 0x40+level.
    move.l  #0x00ff3ff9, IMR            | Allow UART1 and timer interrupts
    move.l  #SYSCALL, 0x080             | Set the interrupt for system call TRAP #0
    move.l  #INTERFACE, 0x110     | Set the interrupt subroutine for level 4 interrupt
    move.l  #TIMER_INTERRUPT, 0x118     | Set the interrupt subroutine for level 6 interrupt
******************************
** Initialization related to the transmitter and the receiver (UART1)
** (The interrupt level has been fixed to 4.)
******************************
    move.w  #0x0000, USTCNT1 | Reset
    move.w  #0xe10c, USTCNT1 | Transmission and reception possible - no parity, 1 stop, 8 bit, allow only tranmission interrupt
    move.w  #0x0038, UBAUD1  | baud rate = 230400 bps
*************************
** Initialization related to the timer (The interrupt level has been fixed to 6.)
*************************
    move.w  #0x0004, TCTL1  | Restart, an interrupt impossible
                            | Count the time with the 1/16 of the system clock
                            | as a unit
                            | Stop the timer use
    jsr		INIT_Q
    bra     MAIN

****************************************************************
**  System Call Interface:
**	Maker: Morris Kim, Rafii Hakim
**  Reviewer: Lim Liang Sun, Napat Limsuwan
****************************************************************
        
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
**	Timer interrupt
**	Maker: Lim Liang Sun, Napat Limsuwan
**  Reviewer: Morris Kim, Rafii Hakim
****************************************************************
TIMER_INTERRUPT:
	movem.l	%a0, -(%sp)		/* Evacuate registers */
	cmp	#0, TSTAT1		/* Checks 0th bit of TSTAT1 */
	beq	TIMER_INTERRUPT_END
	clr.w	TSTAT1			/* Reset TSTAT1 to 0 */
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
**	UART1 Interrupt Interface
**	Maker: Morris Kim, Rafii Hakim
**  Reviewer: Lim Liang Sun, Napat Limsuwan
****************************************************************
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


****************************************************************
**	INTERGET
**	Maker: Zelal Denis Yildiz
**  Reviewer: Amira Ben Youssef
****************************************************************
	
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

	move.b	#'a', LED0
INTERGET_END:
	movem.l	(%sp)+, %d0
	rts
        
****************************************************************
**  INTERPUT
**	Maker: Amira Ben Youssef
**  Reviewer: Zelal Denis Yildiz
****************************************************************	
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
        
****************************************************************
**  PUTSTRING
**	Maker: Amira Ben Youssef
**  Reviewer:  Zelal Denis Yildiz
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
**  GETSTRING
**	Maker: Zelal Denis Yildiz
**  Reviewer: Amira Ben Youssef
****************************************************************
	
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

*****************************************************************
** Queues
**	Maker: Amira Ben youssef, Zelal Denis Yildiz
**  Reviewer: Moris Kim
*****************************************************************
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
	adda.l  #255, %a5  /* the bottom is 255 from the top */

	move.l  #1, %d0     /* success flag raised */

	cmp	%a1, %a5	/* compare inp/outp with bottom*/
	beq	Q_BACK		/* reach the bottom */
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

****************************************************************
**	Main Program
****************************************************************

****************************************************************
**    Program region
****************************************************************
MAIN:
	** Set the running mode and the level (The process to move to 'the user mode')
	move.w	#0x2000, %SR		/*USER MODE, LEVEL 0*/
	lea.l	USR_STK_TOP, %sp	/*set user stack*/

	/* a5 used for printing, d5 for user input */
	/* d4 for if game is played (0/1)*/
	move.l	#0, %d4
	move.w 	#0, CORRECT
	move.w 	#0, MISTAKES

INTRO_LOOP:
	jsr	INTRO
	jsr	WAIT

	cmpi.b	#0, %d5
	beq	INTRO_LOOP

PICKGAMEMODE_LOOP:
	jsr	PICKGAMEMODE
	jsr	WAIT
	
	/* Check user input*/
	cmpi.b	#49, %d5	/* Easy mode */
	jsr	GAME1

	cmpi.b	#50, %d5	/* Normal mode */
	jsr	GAME2

	cmpi.b	#51, %d5	/* Hard mode */
	jsr	GAME3

	cmpi.l	#0, %d4 	/* Has a game been played? */
	bne	RESULTS

	/* Input is Invalid*/
	lea.l	INVALIDTEXT, %a5
	jsr		PRINT
	bra	PICKGAMEMODE_LOOP

RESULTS:
	/* here d4 is used for typing speed*/
	jsr	CALCULATE_RESULTS

	lea.l	BORDER, %a5
	jsr	PRINT

	lea.l	RESULTS1, %a5
	jsr	PRINT

	lea.l	BORDER, %a5
	jsr	PRINT

	lea.l	CONFIRMATION, %a5
	jsr	PRINT

	jsr	WAIT

	/* Results calculation & display */
	/* Typing speed */
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#RESULTS2, %d2		/*p = #PRINT_BUFFER*/
	move.l	#61, %d3			/* d3 = size*/
	trap	#0
	jsr	DUMB_PRINT
	lea.l 	ENDLINE, %a5
	jsr	PRINT

	/* Correct characters */
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#RESULTS3, %d2		/*p = #PRINT_BUFFER*/
	move.l	#9, %d3				/* d3 = size*/
	trap	#0
	clr		%d4					/* just in case */
	move.w	CORRECT, %d4
	jsr	DUMB_PRINT
	lea.l 	ENDLINE, %a5
	jsr	PRINT	

	/* Mistakes */	
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#RESULTS4, %d2		/*p = #PRINT_BUFFER*/
	move.l	#10, %d3			/* d3 = size*/
	trap	#0
	clr		%d4				/* just in case */
	move.w	MISTAKES, %d4
	jsr	DUMB_PRINT
	lea.l 	ENDLINE, %a5
	jsr	PRINT	

	/* Accuracy */	
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#RESULTS5, %d2		/*p = #PRINT_BUFFER*/
	move.l	#48, %d3			/* d3 = size*/
	trap	#0
	move.l	%d5, %d4
	jsr DUMB_PRINT
	lea.l 	ENDLINE, %a5
	jsr	PRINT
	
	lea.l 	ENDING, %a5
	jsr	PRINT

CALCULATE_RESULTS:
	/* Outputs: d4 <- typing speed, %d5 <- accuracy*/
	/* Calculates typing speed and accuracy */
	movem.l 	%d0-%d3, -(%sp)
	move.w 	CORRECT, %d4	/* d4 = correct */
	move.w 	TIME_ELAPSED_TOTAL, %d1	/* d1 = total time elapsed */
	divu.l	%d1, %d4		/* d4 <- correct/time */
	mulu	#60, %d4		/* d4 <- characters per minute*/

	move.w	CORRECT, %d5
	move.w 	%d5, %d0
	add.w	MISTAKES, %d0	/* d0 <- total */
	divu.l	%d0, %d5		/* d5 <- correct/total, might need a size*/
	mulu	#100, %d5		/* Accuracy (%)*/

	movem.l 	(%sp)+ ,%d0-%d3
	rts

DUMB_PRINT:
	/* can't think anymore, here's what my demented brain came up with */
	/* convert binary to printable ascii */
	/* input: d4*/
	movem.l 	%d0-%d3, -(%sp)

DIGIT1:
	move.w 	%d4, %d0
	divu.l	#100, %d0
	move.l	%d0, %d4		/* looks stupid, i know. this saves the divided answer*/

	cmpi.b	#0, %d0			/* might cause problems? we're putting word into d0 and only testing byte*/
	beq		DIGIT2			/* if d0<100, skip this digit*/
	addi.b	#0x30, %d0		
	move.b	%d0, PRINT_BUFFER
	
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#PRINT_BUFFER, %d2		/*p = #PRINT_BUFFER*/
	move.l	#1, %d3				/* d3 = size*/
	trap	#0

DIGIT2:
	swap	%d4			/* swapped so we get the remainder */	
	move.w	%d4, %d0	
	divu.l	#10, %d0
	move.l	%d0, %d4	/* again, saves the divided answer*/

	/* No need to skip if 0, because what are the chances your cpm & acc < 10?? */
	addi.b	#0x30, %d0
	move.b	%d0, PRINT_BUFFER

	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#PRINT_BUFFER, %d2		/*p = #PRINT_BUFFER*/
	move.l	#1, %d3				/* d3 = size*/
	trap	#0

DIGIT3:
	swap	%d4
	move.w	%d4, %d0	

	addi.b	#0x30, %d0
	move.b	%d0, PRINT_BUFFER

	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#PRINT_BUFFER, %d2		/*p = #PRINT_BUFFER*/
	move.l	#1, %d3				/* d3 = size*/
	trap	#0

	movem.l 	(%sp)+ ,%d0-%d3
	rts
	
INTRO:
	/* Intro menu */
	/* Output: d5 <- User Input */
	lea.l	BORDER, %a5
	jsr	PRINT

	lea.l	INTRO_TEXT, %a5
	jsr	PRINT

	lea.l	BORDER, %a5
	jsr	PRINT

	lea.l	CONFIRMATION, %a5
	jsr	PRINT

	rts

PICKGAMEMODE:
	lea.l	GAMEMODEASK, %a5
	jsr	PRINT

	lea.l	MODEASK1, %a5
	jsr	PRINT

	lea.l	MODEASK2, %a5
	jsr	PRINT

	lea.l	MODEASK3, %a5
	jsr	PRINT

START_TIMER:	
	** Start up RESET_TIMER by the system call
	move.l	#SYSCALL_NUM_RESET_TIMER, %d0
	trap	#0
	
	** Start up SET_TIMER by the system call
	move.l	#SYSCALL_NUM_SET_TIMER, %d0
	move.w	#50000, %d1				/* 5 seconds */
	move.l	#TT, %d2
	trap	#0

	rts

************************************* 
*    Print Subroutine 
*    I Think this works??
*************************************
PRINT:
	/* Input: a5 <- Head address of text*/
	/* Running level set to 7 to prevent interrupt while printing */
	movem.l	%d0-%d4/%a1, -(%sp)
	move.w	%SR, %d4
	move.w	#0x2700, %SR
	
	lea.l	PRINT_BUFFER, %a1
	move.w	#0, %d3		/* d3 = size counter*/
	
INSERT_BUFFER_LOOP:
	/* Put the text in BUFFER */
	cmpi.b	#0x0a, (%a5)	/* Encountered an '\n' */
	beq	INSERT_BUFFER_END
	
	move.b	(%a5)+, (%a1)+	/* Move into buffer*/
	addi.w	#1, %d3		/* Increment Size*/

	bra	INSERT_BUFFER_LOOP
	
INSERT_BUFFER_END:
	addi.w	#1, %d3		/* Include \n */
	move.b	#0x0a, (%a1)
	
	/* PUTSTRING  all the text*/
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#PRINT_BUFFER, %d2		/*p = #BUF*/
	trap	#0

	move.w	%d4, %SR
	movem.l	(%sp)+, %d0-%d4/%a1
	rts

	
************************************* 
*    GAMEMODE 1
*    Easy Typing Test
*************************************
GAME1:
	lea.l 	MODECHOSEN1, %a5
	jsr		PRINT

	lea.l   CONFIRMATION, %a5
	jsr		PRINT

	jsr		WAIT

GAME1_START:
	/* Prints Text */
	lea.l	TEXT1, %a5
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1			/*ch = 0*/
	move.l	#TEXT1, %d2		/*p = #BUF*/
	move.l	#258, %d3		/*size of text + 2*/
	trap	#0
	jsr	PRINT

	/* Configures timer to run for 60 seconds */
	move.b 	#0, TIME_ELAPSED_TOTAL
	move.b 	#6, TIME_ELAPSED2
	move.b 	#0, TIME_ELAPSED1

	jsr 	GAME_TIMER_LED

	/* Reset Timer */
	move.l #SYSCALL_NUM_RESET_TIMER,%d0
	trap   #0

	/* Set Timer to run GAME_TIMER every second */
	move.l #SYSCALL_NUM_SET_TIMER, %d0
	move.w #10000, %d1
	move.l #GAME_TIMER, %d2
	trap #0

GAME1_LOOP:
	move.l	#SYSCALL_NUM_GETSTRING, %d0
	move.l	#0, %d1			/*ch = 0*/
	move.l	#BUF, %d2		/*p = #BUF*/
	move.l	#256, %d3		/*size = 256*/
	trap	#0

	/* Check whether what is written is correct */
	/* if not, do not getstring? or if already getstring take it out of the queue */
	cmp.b	BUF, (%a5)		/* I'm trying to compare first element of BUF */
							/* same = correct, else mistake*/
	beq GAME1_CORRECT
	addi.w 	#1, MISTAKES
	bra	GAME1_CHECKTIMER
	
GAME1_CORRECT:
	addi.l	#1, %a5			/* a5 incremented */
	addi.w 	#1, CORRECT		/* CORRECT incremented*/

	move.l	%d0, %d3		/*size = %d0 (The length of a given string)*/
	move.l	#SYSCALL_NUM_PUTSTRING, %d0
	move.l	#0, %d1			/*ch = 0*/
	move.l	#BUF, %d2		/*p = #BUF*/
	trap	#0

	cmpi.w 	#256, CORRECT
	beq 	GAME1_END
	
GAME1_CHECKTIMER:
	cmpi.b 	#0, TIMER_FLAG
	beq		GAME1_LOOP

GAME1_END:
	/* Reset Timer */
	move.l #SYSCALL_NUM_RESET_TIMER,%d0
	trap   #0

	move.l	#1, %d4			/* Game done flag */
	rts
	
************************************* 
*    GAMEMODE 2
*    Normal Typing Test
*************************************
GAME2:
	lea.l 	MODECHOSEN2, %a5
	jsr		PRINT

	lea.l   CONFIRMATION, %a5
	jsr		PRINT

	jsr		WAIT

	rts
	
GAME2_START:	
	rts

************************************* 
*    GAMEMODE 3
*    Hard Typing Test
*************************************
GAME3:
	lea.l 	MODECHOSEN3, %a5
	jsr		PRINT

	lea.l   CONFIRMATION, %a5
	jsr		PRINT

	jsr		WAIT

	rts
	
GAME3_START:	
	rts

**************************************       
*    Wait for input    
**************************************

WAIT:
	/* WAIT FOR INPUT */
	/* We might have to clear buffer */
	/* Output: %d5 <- User Input */
	movem.l	%d0-%d3, -(%sp)
	move.l	#SYSCALL_NUM_RESET_TIMER, %d0
	trap	#0
	
	move.l	#SYSCALL_NUM_SET_TIMER, %d0
	move.l	#600000, %d1			/* 60 seconds */
	move.l	#WAIT_END, %d2			/* Finish waiting when timer ends */	
	trap	#0

	/* Clear Confirmation Buffer*/
	move.b	#0, CONFIRMATION_BUFFER
WAIT_LOOP:
	/* Note: We also want the timer to end if something is input */
	/* I think we can put a cmp if data is input to reset the timer */
	move.l	#SYSCALL_NUM_GETSTRING, %d0
	move.l	#0, %d1				/*ch = 0*/
	move.l	#CONFIRMATION_BUFFER, %d2	/*p = #BUF*/
	move.l	#1, %d3				/*size = 1*/
	trap	#0	
	
	cmpi.b	#0, %d0				/* d0 = no. of things read out by GETSTRING*/
	beq	WAIT_LOOP

	move.w	CONFIRMATION_BUFFER, %d5
	
WAIT_END:
	move.l	#SYSCALL_NUM_RESET_TIMER, %d0
	trap	#0
	movem.l	(%sp)+, %d0-%d3
	rts

**************************************       
**  Game Timer
**	Decrements Game Timer & ends it when done   
**************************************   

GAME_TIMER:
    movem.l	%d0-%d7/%a0-%a6, -(%sp)
    cmpi.w	#0, TIME_ELAPSED2		/*Count with the counter TTC whether five times of the execution have been performed*/
    bne		GAME_TIMER_LED			/*Skip check if >10s left*/

	cmpi.w	#0, TIME_ELAPSED1		/* If 0s, kill timer*/
	beq	GAME_TIMERKILL

	/* Decrement Timer digits */
	cmpi.w 	#0, TIME_ELAPSED1
	beq	GAME_TIMERDECREMENT

	subi.w 	#1, TIME_ELAPSED1
	bra		GAME_TIMEREND

GAME_TIMERDECREMENT:
	move.w	#9, TIME_ELAPSED1
    subi.w	#1, TIME_ELAPSED2			/* Decrement 2nd digit by 1 and return */
    bra		GAME_TIMEREND

GAME_TIMERKILL:
    move.l	#SYSCALL_NUM_RESET_TIMER, %d0
    trap	#0
    
GAME_TIMEREND:
	addi.w	#1, TIME_ELAPSED_TOTAL
    movem.l	(%sp)+, %d0-%d7/%a0-%a6
    rts

GAME_TIMER_LED:
	/* Output time left on LED */
    movem.l	%d1-%d2, -(%sp)
	move.b  #"T", LED7
	move.b  #"i", LED6
	move.b  #"m", LED5
	move.b  #"e", LED4

	move.b  #0x30, %d1  	/* d1 = 0 */
	move.b	%d1, %d2
	add.b  	TIME_ELAPSED1, %d1
	add.b  	TIME_ELAPSED2, %d2

	move.b	#":", LED3
	move.b  %d1, LED2
	move.b  %d2, LED1
	move.b  #"s", LED0
    movem.l	(%sp)+, %d1-%d2
    rts

****************************************************************
**	Data for Queues
****************************************************************

.section .data
    .equ	SIZE_of_QUEUE,	256

.section .bss
.even
top:		.ds.b	SIZE_of_QUEUE*2
inp:		.ds.l	2
outp:		.ds.l	2
s:		.ds.w	2
task_p:		.ds.l	1

            .even

****************************************************************
**	Data region with an initial value
****************************************************************
.section .data
TMSG:	.ascii	"******\r\n"
            .even
TIME_ELAPSED1:	.dc.w	0		/* why is this length 0 */
        .even
TIME_ELAPSED2:	.dc.w	0
        .even
TIME_ELAPSED_TOTAL:	.dc.w 	0
		.even
BORDER:	.ascii	"***************************************************************\r\n"
	.even
INTRO_TEXT:	.ascii	"***               Welcome to the typing game!               ***\r\n"
	.even
CONFIRMATION:	.ascii	"Press any key to continue...\r\n"
	.even
GAMEMODEASK:	.ascii	"Pick a gamemode!\r\n"
	.even
MODEASK1:	.ascii	"1 - Easy Mode (256 characters, 30s)\r\n"
	.even
MODEASK2:	.ascii	"2 - Normal Mode (512 characters, 45s)\r\n"
	.even
MODEASK3:	.ascii	"3 - Hard Mode (1024 characters, 60s)\r\n"
	.even
INVALIDTEXT:	.ascii	"Invalid Input! Try again\r\n"
	.even
MODECHOSEN1:	.ascii	"Word Mode Chosen!\r\n"
	.even
MODECHOSEN2:	.ascii	"Paragraph Mode Chosen!\r\n"
	.even
RESULTS1:	.ascii	"***                       Your Results                      ***\r\n"
	.even
RESULTS2:	.ascii	"Characters Per Minute (Rounded to the nearest whole number): "
RESULTS3:	.ascii	"Correct: "
RESULTS4:	.ascii	"Mistakes: "
RESULTS5:	.ascii	"Accuracy (Rounded to the nearest whole number): "
ENDLINE:	.ascii	"\r\n"
	.even
CORRECT:	.dc.w 	1
MISTAKES:	.dc.w	1
TIMER_FLAG:	.dc.b	1

ENDING:	.ascii	"Play again?\r\n"

TEXT1:	.ascii	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce ornare est vel arcu venenatis fringilla. Maecenas at bibendum velit. Nunc eget metus metus. Pellentesque iaculis mauris lobortis ante semper vestibulum. Morbi et aliquete nunc. Donec porttitor.\r\n"
TEXT2:	.ascii	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla in massa lorem. Nulla lacinia a lectus vel tristique. Duis blandit justo non hendrerit accumsan. Vivamus ut laoreet eros. Suspendisse potent. Aliquam efficitur nunc sapien, ac ultrices odio hendrerit id. Nam sit amet diam mattis, volutpat leo et, pulvinar justo. Nam non lacinia orci. Donec condimentum nibh ex, sed accumsan lorem efficitur ut. Quisque tincidunt suscipit urna at placerat. Vivamus ultricies, nunc porttitor pulvinar dignissim vivam.\r\n"
TEXT3:	.ascii	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vitae justo vel justo dapibus iaculis convallis non magna. Curabitur orci magna, malesuada aporta sed, tempor eu quam. Donec interdum purus finibus arcu iaculis finibus. Etiam imperdiet non nisi sit amet convallis. Pellentesque ut enim vehicula, tristique diam ac, gravida ex. Nam ut est blandit, rhoncus arcu vel, vestibulum risus. Nulla facilisi. Suspendisse non tortor maximus, rutrum dui quis, mattis felis. Nunc orci diam, rutrum eget dui at, blandit placerat elit. Nam nec magna ligula. Maecenas malesuada viverra tortor ut volutpat. Fusce a tristique neque. Maecenas convallis justo non ligula blandit, eget suscipit mauris fringilla. Morbi tempor nibh eget dictum egestas. Vestibulum suscipit orci purus, nec pellentesque est facilisis eget. Sed lacinia quis est nec dignissim. Sed mi nibh, sodales vitae viverra eget, auctor non diam. Vivamus nec turpis eget risus dictum tincidunt. Ut quis eros at dolor scelerisque dictum. Donec porta, lectus nec am.\r\n"
****************************************************************
**	Data region without an initial value
****************************************************************
.section .bss
BUF:		.ds.b	256
        .even
PRINT_BUFFER:		.ds.b	256
        .even
CONFIRMATION_BUFFER:	.ds.b	1
		.even
USR_STK:
            .ds.b	0x4000
            .even
USR_STK_TOP:
