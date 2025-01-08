#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include "mtk_c.h"
#include <fcntl.h>
#include <stdbool.h>


// Global variabes
FILE *com0in;
FILE *com0out;
FILE *com1in;
FILE *com1out;


void task1(){
  while(1){
	  P(0);
	  
	  fprintf(com0out,"hello from player 1");
	  fflush(com0out);
	  
	  char response[100];
	  fscanf(com1in,"%s", response);
	  printf("player1 received: %s\n",response);
	  v(0);
  }
}

void task2(){
  while(1){
	  P(0);
	  fprintf(com1out,"hello from player 2");
	  fflush(com1out);
	  char response[100];
	  fscanf(com0in,"%s", response);
	  printf("player2 received: %s\n",response);
	  v(0);
  }
}


void init_ports() {
	int success = 4;
	while(success>0){
		com0in = fdopen(3, "r");
		if (com0in == NULL) success--;
	
		com0out = fdopen(3, "w");
		if (com0out == NULL) success--;
	
		com1in = fdopen(4, "r");
		if (com1in == NULL) success--;
	
		com1out = fdopen(4, "w");
		if (com1out == NULL) success--;
	}
	
	fprintf(com0out, "Ports Initialized! \n");
	fprintf(com1out, "Ports Initialized! \n");
}

int main()
{
	// initialization

	init_ports();

	set_task(task1);
    	set_task(task2);
    	//set_task(task3);

    	begin_sch();
	return 0;
	
}
}

