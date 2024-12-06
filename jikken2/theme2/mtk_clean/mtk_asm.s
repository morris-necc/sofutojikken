.include "equdefs.inc"

.global first_task
.global pv_handler
.global P
.global V
.global hard_clock
.global swtch
.global init_timer

.extern p_body
.extern v_body
.extern curr_task
.extern addq
.extern sched
.extern ready /*points to the first task*/
.extern task_tab
.extern next_task
 
.section .text
.even
********************
** System call numbers 
******************** 
.equ    SYSCALL_P, 0
.equ    SYSCALL_V, 1
 
swtch:
	move.w 	%SR , -(%sp)/*SR is piled up on the stack so that the process can be returned by the RTE.*/
	
	movem.l %d0-%d7/%a0-%a6,-(%sp)/*Saving register of task under execution*/
	move.l 	%USP, %a1
	move.l 	%a1, -(%sp)

	move.l 	curr_task,%d0 	/*current task ID*/
	lea.l 	task_tab, %a0 	/*save the pointer to the beginning of task_tab*/
	mulu 	#20, %d0 	/* because every element takes 4*5 bytes*/
	add.l 	#4, %d0 	/*to access stack_ptr*/
	adda.l 	%d0, %a0 	/*access the stack_ptr of curr_task in task_tab*/
	move.l 	%sp, (%a0) 	/* record the SSP*/

	/*Substitute ‘next_task’ for ‘curr_task’*/
	lea.l 	curr_task, %a1
	move.l 	next_task, (%a1)

	/* Read out SSP of next task*/
	move.l 	curr_task,%d0 	/*current task ID*/
	lea.l 	task_tab, %a0 	/*save the pointer to the beginning of task_tab*/
	mulu 	#20, %d0 	/* because every element takes 4*5 bytes*/
	addq.l 	#4, %d0 		/*to access stack_ptr*/
	adda.l 	%d0, %a0 	/*access the stack_ptr of curr_task in task_tab*/
	move.l 	(%a0), %sp 	/* read out next task's SSP*/

	/*Read out register of next task*/
	move.l 	(%sp)+, %a1
	move.l 	%a1, %USP
	movem.l (%sp)+, %d0-%d7/%a0-%a6

	rte

*****************************************
** subroutine first_task
** To start user task: stack used by kernel is switched to the stack pointed by "curr_task"
** activated once (with "begin_sch()")
** ends with RTE
** needs to be in supervisor mode
*****************************************
first_task:
	move.w	#0x2700, %SR

	/* calcuate TCB's head address */
	/* find the address of TCB of 'curr_task' */
	clr.l	%d1
	lea.l	task_tab, %a1
	move.l	curr_task, %d1
	mulu	#20, %d1	/* TCB datatype takes up 20 bytes*/
	adda.l	%d1, %a1	/* add 20*curr_task to access task_tab[curr_task]*/

	/* restoration of values of USP and SSP */
	/* restore the ssp's value recorded in this task's TCB & USP value recorded in the ss*/
	move.l	4(%a1), %sp	/* restore stack pointer */
	move.l	(%sp)+, %a2
	move.l	%a2, %USP	/* restore USP */
	

	/* restoration of al of remained registers */
	/* restore the values of remained 15 registers piled up on the supervisor's stack*/
	movem.l	(%sp)+, %d0-%d7/%a0-%a6

	/* start of user task */
	/* execute the RTE instruction*/
	rte
	
	
******************************************
*** create the timer subroutines:
*** init_timer/Trap#0:OK/set_timer:OK/reset_timer:OK/hard_clock
******************************************
/* called from hardware intrruptprocessing interface for timer(prepared in 1st part) */
hard_clock: /* timer interrupt routine */
	movem.l	%d0-%d1/%a1,-(%sp)  /*save register of task under execution(piled up in ss: executed in timer interrupt!!!!)*/
	/*to check if supervisor mode*/
	movea.l %sp, %a1
	adda.l 	#12,%a1
	move.w 	(%a1),%d1	/*get SR value to %d1*/
	addi.w 	#0x2000,%d1
	cmpi.w 	#0x2000,%d1 	/*check if supervisor mode*/
	beq 	hard_clock_end
	
	/* add "curr_task" to the end of 'ready' using addq() */
	move.l 	curr_task,-(%sp)
	move.l 	#ready, -(%sp)
	jsr 	addq
	
	add.l 	#8, %sp
	/* start "sched": the ID of task to be executed next='next_task' */
	jsr sched
	/* start 'swtch'*/
	jsr swtch

hard_clock_end:
	movem.l (%sp)+, %d0-%d1/%a1
	rts

init_timer:
	/* clock interrupt routine: generates hardware interruption by the timer control routine */
	/* interruption period: 1s */
	movem.l %d0-%d2,-(%sp)
	
	move.l	#SYSCALL_NUM_RESET_TIMER, %d0
	trap 	#0

	move.l	#SYSCALL_NUM_SET_TIMER, %d0
	move.w	#10000, %d1
	move.l	#hard_clock, %d2
	trap	#0

	movem.l (%sp)+,%d0-%d2
	rts

********************************
** Entrance of P system call
** Input: D1 = semaphore ID
********************************
P:
	movem.l	%d0-%d1, -(%sp)
	move.l	SYSCALL_P, %d0
	move.l	12(%sp), %d1
	trap	#1
	movem.l	(%sp)+, %d0-%d1
	rts
	
********************************
** Entrance of V system call
** Input: D1 = semaphore ID
********************************
V:
	movem.l	%d0-%d1, -(%sp)
	move.l	SYSCALL_V, %d0
	move.l	12(%sp), %d1
	trap	#1
	movem.l	(%sp)+, %d0-%d1
	rts

********************************
** TRAP #1 interrupt provessing routine
** D0 = P/V system call
** D1 = Semaphore ID
** According to D0, call p_body() or v_body()
********************************
pv_handler:
	movem.l	%d1, -(%sp)	/* save argument on top of stack */
	move.w	#0x2700, %SR	/* supervisor mode */
	
	cmpi.l	#0, %d0
	beq	CALL_P_BODY
	cmpi.l	#1, %d0
	beq 	CALL_V_BODY
	bra	end_pv_handler
CALL_P_BODY:
	jsr	p_body
	bra 	end_pv_handler
CALL_V_BODY:	
	jsr	v_body
	bra	end_pv_handler
end_pv_handler:
	movem.l	(%sp)+, %d1
	rte
