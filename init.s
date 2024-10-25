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
	move.w #0x2000, %SR /*Start at level 0 */
	lea.l SYS_STK_TOP, %SP |Set SSP

	******************************
	**Initialization of the interrupt controller
	******************************

	move.b #0x40, IVR | Set the user interrupt vector| number to 0x40+level.
	move.l #0x00ff3ffb, IMR | Permit transmitter and receiver interrupt

	******************************
	**Initialization of the interrupt vector
	******************************

	move.l #UART1_INTERRUPT, 0x110 /* Level 4 user interrupt */
	move.l #TIMER1_INTERRUPT, 0x118 /* Level 6 user interrupt */

	******************************
	** Initialization related to the transmitter and the receiver (UART1)
	** (The interrupt level has been fixed to 4.)
	******************************

	move.w #0x0000, USTCNT1 | Reset
	move.w #0xe108, USTCNT1 |Transmission and reception possible |no parity, 1 stop, 8 bit| Only allow receiver interrupts
	move.w #0x0038, UBAUD1 |baud rate = 230400 bps

	*************************
	** Initialization related to the timer (The interrupt level has been fixed to 6.)
	*************************

	move.w #0x0004, TCTL1 | Restart, an interrupt impossible|Count the time with the 1/16 of the system clock|as a unit|Stop the timer use

	
	
	bra MAIN

****************************************************************
** Interrupt Controller
****************************************************************

UART1_INTERRUPT:
	movem.l	%d0, -(%sp)

	/* Step 2*/
	# move.w	URX1, %d0 /* Received data in register URX1 moved to d0*/
	# adda.w	#0x0800 + 'a', %d0 /* When copying, it is necessary to add a header of the upper 8 bits*/
	# move.w	%d0, UTX1 /* This data is then moved to UTX1*/
	
	/* Step 3 */
	move.w #0x0800 + 'a', UTX1
	

	movem.l	(%sp)+, %d0
	rte


*****************************************************************
** % Write in ‘a’ in the transmitter register UTX1 to confirm the normal initialization routine
** % operation at the present step. When ‘a’ is outputted, it’s OK.
*****************************************************************

.section .text
.even
MAIN :
	move.b #'a', LED0 /* Debug */
	move.w #0x0800+'a', UTX1 |Refer to Appendix for the reason to add 0x0800
LOOP :
	bra LOOP
