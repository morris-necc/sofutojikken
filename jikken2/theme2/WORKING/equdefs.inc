    .equ    SYSCALL_NUM_GETSTRING, 1 
    .equ    SYSCALL_NUM_PUTSTRING, 2 
    .equ    SYSCALL_NUM_RESET_TIMER, 3 
    .equ    SYSCALL_NUM_SET_TIMER, 4 

    .equ    REGBASE, 0xFFF000 
    .equ    IOBASE, 0x00d00000

    .equ    IVR, REGBASE+0x300 
    .equ    IMR, REGBASE+0x304 
    .equ    ISR, REGBASE+0x30c 
    .equ    IPR, REGBASE+0x310 
    
    .equ    TCTL1, REGBASE+0x600 	
    .equ    TPRER1, REGBASE+0x602 	
    .equ    TCMP1, REGBASE+0x604 	
    .equ    TCN1, REGBASE+0x608 	
    .equ    TSTAT1, REGBASE+0x60a 	
    
    .equ    USTCNT1, REGBASE+0x900 	
    .equ    UBAUD1, REGBASE+0x902 	
    .equ    URX1, REGBASE+0x904 	
    .equ    UTX1, REGBASE+0x906 	
    
    .equ    LED7, IOBASE+0x000002f 	
    .equ    LED6, IOBASE+0x000002d 	
    .equ    LED5, IOBASE+0x000002b
    .equ    LED4, IOBASE+0x0000029
    .equ    LED3, IOBASE+0x000003f
    .equ    LED2, IOBASE+0x000003d
    .equ    LED1, IOBASE+0x000003b
    .equ    LED0, IOBASE+0x0000039
    .equ    PUSHSW, 0xFFF419 		
