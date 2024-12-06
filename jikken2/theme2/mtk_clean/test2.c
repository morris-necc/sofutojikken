#include <stdio.h>
#include "mtk_c.h"
#define MAX 1024

void task1(){ 
  while(1){
    P(0);
    //Something here?
    V(0);}
}

void task2(){ 
  while(1){
    P(0);
    //Something here?
    V(0);
    }
}

int main(){
  //hardware initialization
  init_kernel(); // maybe?
  
  //system setting
  set_task(task1);
  set_task(task2);
  begin_sch(); //start multitasking
  return 0;
}
