#include <stdio.h>
#include "mtk_c.h"
#define MAX 1024

void task1(){ 
	P(1);
	for(int i=1;i<=20;i++){
		printf("\n1 %d",i);
  	}
  	V(1);
  	while(1){
  		printf("\ntask1 finished");
  		}
  	}
void task2()
{ 
    // task2 definition
	P(2);
	for(int i=1;i<=20;i++){
		printf("\n2 %d",i);
  	}
  	V(2);
  	while(1){
  		printf("\ntask2 finished");
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
