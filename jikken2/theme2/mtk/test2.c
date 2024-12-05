#include <stdio.h>
#include "mtk_c.h"
#define MAX 1024

void task1(){ 
  while(1){
    P(0);
    V(0);}
}

void task2(){ 
    // task2 definition
  while(1){
    P(0);
    V(0);
}

void main(){
  //hardware initialization
  init_kernel(); // maybe?
  
  //system setting
  set_task(task1);
  set_task(task2);
  begin_sch(); //start multitasking
}
