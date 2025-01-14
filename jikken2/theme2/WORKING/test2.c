#include <stdio.h>
#include "mtk_c.h"

#define MAX 1024

void task1()
{
	P(0);
	for (int i=1;i<=500;i++){
		printf("1 %d\n", i);
		}
	V(0);
	
}

void task2()
{	
	P(0);
	for (int i=1;i<=500;i++){
		printf("2 %d\n", i);
		}
	//V(0);
	
       
}

void task3()
{
char c;
	P(0);
	while(1){
	scanf("%c",&c);}
	//V(0);
}

int main()
{

	init_kernel();
	
	set_task(task1);
    	set_task(task2);
    	set_task(task3);

    	begin_sch();
	return 0;
}

