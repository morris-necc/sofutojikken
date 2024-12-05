.include "equdefs.inc"
.section .text

.extern curr_task
.extern addq
.extern sched
.extern ready /*points to the first task*/

*****************************************
** subroutine first_task
** To start user task: stack used by kernel is switched to the stack pointed by "curr_task"
** activated once (with "begin_sch()")
** ends with RTE
** needs to be in supervisor mode
*****************************************
first_task:
	/* calcuate TCB's head address */
	/* find the address of TCB of 'curr_task' */
	clr.l	%d1
	lea.l	task_tab, %a1
	move.l	curr_task, %d1
	mulu	#20, %d1	/* TCB datatype takes up 20 bytes*/
	adda.l	%d1, %a1	/* add 20*curr_task to access task_tab[curr_task]*/

	/* restoration of values of USP and SSP */
	/* restore the ssp's value recorded in this task's TCB & USP value recorded in the ss*/
	adda.l	#4, %a1		/* get stack pointer */
	move.l	(%a1), %sp	/* restore stack pointer */
	move.l	(%sp)+, %a2	/* pop stack containing _____ into a2*/
	move.l	%a2, %USP	/* i dont get this part */
	

	/* restoration of al of remained registers */
	/* restore the values of remained 15 registers piled up on the supervisor's stack*/
	movem.l	(%sp)+, %d0-%d7/%a0-%a7

	/* start of user task */
	/* execute the RTE instruction*/
	rte
	
	
******************************************
*** create the timer subroutines:
*** init_timer/Trap#0:OK/set_timer:OK/reset_timer:OK/hard_clock
******************************************
//called from hardware intrruptprocessing interface for timer(prepared in 1st part)
hard_clock: // timer interrupt routine
	movem.l %d0-%d1/%a1,-(%sp)  //save register of task under execution(piled up in ss: executed in timer interrupt!!!!)
	/*to check if supervisor mode*/
	move.l %sp, %a1
	adda.l #12,%a1
	move.l (%a1),%d1//get SR value to %d1
	addi.l #2000,%d1
	cmpi.l #2000,%d1 //check if supervisor mode
	beq hard_clock_end
	//add "curr_task" to the end of 'ready' using addq()
	move.l curr_task,-(%sp)
	move.l #ready, -(%sp)
	jsr addq
	addq.l #8, %sp

	//start "sched": the ID of task to be executed next='next_task'
	jsr sched
	//start 'swtch'
	jsr swtch
	movem.l (%sp)+, %d0-%d1/%a1 //restoration of register
	rts

hard_clock_end:
	movem.l (%sp)+, %d0-%d1/%a1
	rts

init_timer:	//clock interrupt routine: generates hardware interruption by the timer control routine(created in jikken1): interruption period: 1s)
	movem.l %d0-%d2,-(%sp)
	move.l	#SYSCALL_NUM_RESET_TIMER, %d0
	trap #0

	move.l	#SYSCALL_NUM_SET_TIMER, %d0
	move.w	#10000, %d1
	move.l	#hard_clock, %d2
	trap	#0

	movem.l (%sp)+,%d0-%d2
