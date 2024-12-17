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
	bool success = true;
	while(!success){
		com0in = fdopen(3, "r");
		if (com0in == EBADF) success = false;
	
		com0out = fdopen(3, "w");
		if (com0out == EBADF) success = false;
	
		com1in = fdopen(4, "r");
		if (com1in == EBADF) success = false;
	
		com1out = fdopen(4, "w");
		if (com1out == EBADF) success = false;
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

