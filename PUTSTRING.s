.section .text
PUTSTRING:
	/*INPUT:
	%d1.l:ch=0|1
	%d2.l:p
	%d3.l: data size to be sent
	OUTPUT:	
	%d0= number of bytes of data written in queue(actually sent)
	*/
	cmpi.l	#0, %d1 /* if ch!=0 -> no exec*/
	beq PUTSTRING_INIT 
	rts
	

PUTSTRING_INIT:
	movem.l %a1-%a6,-(%sp)
	bne PUT_STOP
	move.l #0, size_put/*size of data put to the Q*/
	move.l size_put,%d0/*D0.l:= number of data sz actually sent*/
	move.l %d2, ptr_put /*start address of data to be transmitted (in receiver Q)*/
	cmp #0,%d3 /*number of data to be sent: receiverQ size?*/
	beq PUT_STOP
	movem.l (%sp)+, %a1-%a6
	rts

PUTSTRING_DO:
	cmp size_put, %d3
	beq PUT_UNMASK
	jsr PUT_DATA
PUT_UNMASK:
	ori.w 0xe107, %SR
	bra PUT_STOP
PUT_STOP:
	move.l size_put, %d0
	movem.l  (%sp)+,%a1-%a7
	rts
PUT_DATA:
	movem.l %d0-%d1/%a1,-(%sp)
	move.l ptr_put,%a1/*d1:= pointer in receiver Q to get data*/
	moveq.l #1, %d0/*choose trans. queue*/
	move.b (%a1)+, %d1 /* moves content in addr. p to d1*/
	jsr INQ
	lea.l %a1, ptr_put /*update the pointer*/
	jsr UPDATE_SZ
	cmp size_put,%d3
	beq PUT_UNMASK
	cmp #0, %d0
	beq PUT_UNMASK
	bra PUT_DATA

UPDATE_SZ:
	move.l %d2,-(%sp)
	move.l size_put, %d2
	addq #1, %d2
	move.l %d2, size_put
	move.l (%sp)+, %d2
	rts


.section .data
size_put:	.ds.l 1
ptr_put:	.ds.l 1
