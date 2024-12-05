#include <stdio.h>
#include "mtk_c.h"
#define MAX 1024

void task1(){ 
    // task1 definition 
} 
void task2(){ 
    // task2 definition 
}

void main(){
  //hardware initialization
  init_kernel(); // maybe?
  
  //system setting
  set_task(task1);
  set_task(task2);
  begin_sch(); //start multitasking
}
