#include <stdio.h>
#include "mtk_c.h"

void init_kernel() {
  //TCB array's initialization: all elements are made empty
  int i;
  for(int i = 0; i <= NUMTASK; i++) {
    task_tab[i].task_addr = NULL;
    task_tab[i].stack_ptr = NULL;
    task_tab[i].priority = 0;
    task_tab[i].status = UNDEFINED;
    task_tab[i].next = NULLTASKID;		
  }
  //Ready queue's initiaization: to be made empty (task ID = 0)
  ready = NULLTASKID; //Task id = 0;

  //Registrate the P/V system call7s interruption processing routine (pv_handler)
  //in the interrupt vector of TRAP #1
  // idk what this means
  *(int*) 0x0084 = (int)pv_handler;

  //Initialize the semaphore's value
  for(int i=0; i < NUMSEMAPHORE; i++){
    semaphore[i].count = 1;
    semaphore[i].task_list = NULLTASKID;
  }
}

void set_task() {

}

void init_stack() {

}

void begin_sch() {

}

void addq() {

}

void removeq() {

}

void sched() {

}

void sleep() {

}

void wakeup() {

}

void p_body() {

}

void v_body() {

}
