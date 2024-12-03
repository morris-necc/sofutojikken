.global pv_handler
.global P
.global V

.extern p_body
.extern v_body

********************
** System call numbers 
******************** 
	.equ    SYSCALL_P, 0
	.equ    SYSCALL_V, 1

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
	move.w	#0x2700, %SR
	cmp	#0, %d0
	beq	CALL_P_BODY
	cmp	#1, %d0
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
