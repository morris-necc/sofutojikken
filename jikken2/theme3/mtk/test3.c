#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include "mtk_c.h"

#define MAX 1024

// Global variabes
FILE *com0in;
FILE *com0out;
FILE *com1in;
FILE *com1out;

void init_ports() {
	int success = 4;
	while(success > 0){
	
	
		com0in = fdopen(3, "r");
		if (com0in != NULL) success--;
	
		com0out = fdopen(3, "w");
		if (com0out != NULL) success--;
		else fprintf(com0out, "Port 0 succesfully connected \n");
	
		com1in = fdopen(4, "r");
		if (com1in != NULL) success--;
	
		com1out = fdopen(4, "w");
		if (com1out != NULL) success--;
		else fprintf(com0out, "Port 1 succesfully connected \n");
		
		success = 4;
		
	}
	
	fprintf(com0out, "Ports Initialized! \n");
	fprintf(com1out, "Ports Initialized! \n");
}

void main()
{
	// initialization
	init_kernel();
	init_ports();

	
	set_task(task1);
    	set_task(task2);
    	set_task(task3);

    	begin_sch();
	
}

