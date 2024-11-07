TIMER_INTERRUPT:
	movem.l	%a0, -(%sp)	/* Evacuate registers */
	btst	#0, TSTAT1	/* Checks 0th bit of TSTAT1 */
	beq	TIMER_INTERRUPT_END
	clr.w   TSTAT1		/* Reset TSTAT1 to 0 */
	jsr	CALL_RP
TIMER_INTERRUPT_END:
	movem.l	(%sp)+, %a0
	rte

RESET_TIMER:
	move.w 	#0x0004, TCTL1	/* Restart, an interrupt impossible, input is SYSCLK/16, prohibit timer */
	rts
SET_TIMER:
	/* D1.W = t (timer interrupt cycle, every 0.t msec) */
	/* D2.L = p (head address of the routine to be called at the interrupt occurrence) */
  /* STILL NEED TO DEFINE GLOBAL VARIABLE TASK_P IN THE .BSS SECTION */
	move.l	%d2, task_p	/* Substitute p for the global variable task_p*/
	move.w	#0x00CE, TPRER1 /* Let counter increment by 1 every 0.1 msec*/
	move.w	%d1, TCMP1	/* Substitute t for the TCMP1 */
	move.w	#0x0015, TCTL1		/* Restart, enable compare interrupt, input is SYSCLK/16, permit timer */
	rts
CALL_RP:
	move.l	(task_p), %a0
	jsr	(%a0)
	rts

/* another version*/

TIMER_INTERRUPT:
    btst    #0, TSTAT1          /* Check 0th bit of TSTAT1 for interrupt */
    beq     TIMER_INTERRUPT_END /* If not set, skip interrupt handling */
    movem.l %a0, -(%sp)         /* Save register %a0 */
    clr.w   TSTAT1              /* Clear TSTAT1 (reset interrupt flag) */
    jsr     CALL_RP             /* Call interrupt routine at task_p */
    movem.l (%sp)+, %a0         /* Restore register %a0 */
    
TIMER_INTERRUPT_END:
    rte                          /* Return from exception */

RESET_TIMER:
    move.w  #0x0004, TCTL1      /* Restart with no interrupts, SYSCLK/16 */
    rts

SET_TIMER:
    move.l  %d2, task_p         /* Store address of routine to task_p */
    move.w  #0x00CE, TPRER1     /* Set TPRER1 for 0.1 ms per count */
    move.w  %d1, TCMP1          /* Set compare value from %d1 */
    move.w  #0x0015, TCTL1      /* Enable timer with compare interrupt */
    rts

CALL_RP:
    move.l  (task_p), %a0       /* Load task address from task_p */
    jsr     (%a0)               /* Jump to task routine */
    rts
