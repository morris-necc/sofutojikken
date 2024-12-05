#ifndef MTK_C_H
#define MTK_C_H

// ******************************************
// Constants
// ******************************************
#define NULLTASKID 0 /*Queue's termination*/
#define NUMTASK 5    /*Maximum number of tasks*/
#define NUMSEMAPHORE 3
#define STKSIZE 1024 /*size of 1Kbyte*/

#define UNDEFINED 0
#define OCCUPIED 1
#define FINISHED 2


// ******************************************
// User-made datatypes
// ******************************************
typedef int TASK_ID_TYPE;

typedef struct {
  void (*task_addr)();
  void *stack_ptr;
  int priority;
  int status;
  TASK_ID_TYPE next;
} TCB_TYPE;

typedef struct {
  int count;
  int nst; //reserved
  TASK_ID_TYPE task_list;
} SEMAPHORE_TYPE;

typedef struct {
  char ustack[STKSIZE];
  char sstack[STKSIZE];
} STACK_TYPE;

// ******************************************
// Global Variables
// ******************************************
extern TASK_ID_TYPE curr_task;
extern TASK_ID_TYPE new_task;
extern TASK_ID_TYPE next_task;
extern TASK_ID_TYPE ready;

extern SEMAPHORE_TYPE semaphore[NUMSEMAPHORE];
extern TCB_TYPE task_tab[NUMTASK+1]; /*declaration of TCB's array*/
extern STACK_TYPE stacks[NUMTASK];

// ******************************************
// Function Declarations
// ******************************************
void init_kernel();
void set_task(void (*task_ptr)());
void* init_stack(TASK_ID_TYPE task_id);
void begin_sch();


extern void addq();
extern void removeq();


extern void sched();
extern void sleep();
extern void wakeup();
extern void p_body();
extern void v_body();  //again, idk if tihs is right
