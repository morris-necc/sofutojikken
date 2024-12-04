	.include "equdefs.inc"
	.section .text

	.extern curr_task
	.extern addq
	.extern sched
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
	move.l (%a1),%d1
	addi.l #2000,%d1
	cmpi.l #2000,%d1
	beq hard_clock_end
	//add "curr_task" to the end of 'ready' using addq()
	//start "sched": the ID of task to be executed next='next_task'
	//start 'swtch'
	//restoration of register
	rts

hard_clock_end:
	
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
