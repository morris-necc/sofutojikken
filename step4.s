** Input: D1 = Ch **
** Read out one data from transmitting queue of channel Ch and write in UTX1 **
INTERPUT:
    movem.l 
    move  #0x2700, %SR
    cmpi  #0, %d1
    beq INTERPUT_END
    move  #1, %d0
    jsr OUTQ
    
    
INTERPUT_END:
