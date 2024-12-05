#include <stdio.h>
#include "mtk_c.h"

TASK_ID_TYPE curr_task;
TASK_ID_TYPE new_task;
TASK_ID_TYPE next_task;
TASK_ID_TYPE ready;

SEMAPHORE_TYPE semaphore[NUMSEMAPHORE];
TCB_TYPE task_tab[NUMTASK+1];
STACK_TYPE stacks[NUMTASK];

void init_kernel() {
  //No arguments
  //Returns nothing
  
  //TCB array's initialization: all elements are made empty
  for(int i = 0; i <= NUMTASK; i++) {
    task_tab[i].task_addr = NULL;
    task_tab[i].stack_ptr = NULL;
    task_tab[i].priority = 0;
    task_tab[i].status = UNDEFINED;
    task_tab[i].next = NULLTASKID;		
  }
  //Ready queue's initiaization: to be made empty (task ID = 0)
  ready = NULLTASKID; //Task id = 0;

  //Registrate the P/V system call's interruption processing routine (pv_handler)
  //in the interrupt vector of TRAP #1
  // idk what this means
  *(int*) 0x0084 = (int)pv_handler;

  //Initialize the semaphore's value
  for(int i=0; i < NUMSEMAPHORE; i++){
    semaphore[i].count = 1;
    semaphore[i].task_list = NULLTASKID;
  }
}

void set_task((*task_ptr)()) {
  //Takes the pointer to the user task function as an argument
  //Returns nothing
  
  //Determine the task ID
  for (TASK_ID_TYPE i = 1; i <= NUMTASK; i++) {
    // Find an empty slot in 'task_tab[]' omitting the 0th slot
    if (task_tab[i].status != OCCUPIED) {
      new_task_id = i;
      task.tab[i].task_addr = task_ptr;  //And substitute the ID to the 'new_task'
      task.tab[i].status = OCCUPIED;  //update status
      task.tab[i].stack_ptr = init_stack(new_task_id); // stack initialization
      addq(&ready, new_task_id) //register to ready queue
      break;
    }
  }
}

void* init_stack(TASK_ID_TYPE task_id) {
  //takes task ID as argument
  //returns address void *type that the user task SSP

  int* int_ssp = (int*)&stacks[task_id-1].sstack[STKSIZE]; //set int_ssp as bottom of stack
  *(--int_ssp) = task_tab[task_id].task_addr; //push value of PC on the stack

  //push initial SR on the stack
  unsigned short int* short_ssp = (unsigned short int*)int_ssp;
  *(--short_ssp) = 0x0000;
  
  //skip 15*4 bytes
  int_ssp = (int*)short_ssp;
  int_ssp -= 15;

  //push initial USP
  *(--int_ssp) = (int*)&stacks[task_id-1].ustack[STKSIZE];
  
  return (void*)int_ssp;
}

void begin_sch() {
  //No argument
  //Returns nothing
  
  curr_task = removeq(&ready); //take out one task from ready queue and put it in curr_task
  init_timer(); //initialize timer
  first_task(); //call first_task
}

void addq(TASK_ID_TYPE* pointerToAQueue, TASK_ID_TYPE newTaskID) {
  	TASK_ID_TYPE currentTaskID = *pointerToAQueue;
	if(currentTaskID != NULLTASKID) {
		while(1) {
			TASK_ID_TYPE nextInLine = task_tab[currentTaskID].next;
			if(nextInLine == NULLTASKID) {
				task_tab[currentTaskID].next = newTaskID;
				task_tab[newTaskID].next = NULLTASKID;
				break;
			} else {
				currentTaskID = task_tab[currentTaskID].next;
			}
		}
	} else {
		*pointerToAQueue = newTaskID;
	}
}

TASK_ID_TYPE removeq(TASK_ID_TYPE* pointerToAQueue) {
	TASK_ID_TYPE topID = *pointerToAQueue;
	if(topID == NULLTASKID) {
		return NULLTASKID;
	} else {
		*pointerToAQueue = task_tab[topID].next;
		return topID;
	}
}

void sched(){
    next_task = removeq(&ready);
    if(next_task == NULLTASKID)
	while(1);   //if next_task is nulltaskid, infinite loop
}


void sleep(int ch) {
    addq(&semaphore[ch].task_list, curr_task);
    sched();
    swtch();    
}

void wakeup(int ch) {
    addq(&ready, removeq(&semaphore[ch].task_list));
}


void p_body() {
  //semaphore
}

void v_body() {
  //semaphore
}
