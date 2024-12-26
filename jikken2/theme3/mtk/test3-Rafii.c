// what to do after:
// - x vertical, y horizontal
// - update client2

// escape characters definition
#define ESC "\x1b"

#define CLEARDISPLAY ESC "[H" ESC "[2J"

#define CURSORINVISIBLE ESC "[?25l"
#define CURSORVISIBLE ESC "[?25h"

#define SAVECURSORLOC ESC "7"
#define RETCURSORLOC ESC "8"
//

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "mtk_c.h"

#define MAX_STRING_SIZE 100

extern char inbyte(int);

// FILE descriptors for RS232C port
FILE *com0in;
FILE *com0out;
FILE *com1in;
FILE *com1out;

// global variables
int global_hour = 0, global_min = 0, global_sec = 0;

int clock_pos_x, clock_pos_y;
int chatlog_start_x, chatlog_start_y, chatlog_x, chatlog_y;

int chatlog_read_index = 0, chatlog_write_index = 0, chatlog_size = 0;
int chatlog_sender[1000] = {};
char chatlog[1000][101] = {};
//


void gotoxy(int channel, int x, int y) {
	FILE* fd;
	if(channel == 0) fd = com0out;
	if(channel == 1) fd = com1out;
	
	fprintf(fd, "\033[%d;%dH", x, y);
}

void initPort() {
	/*
		Assign file descriptors for RS232C port.
		args:
			none
		returns:
			none
	*/
	
    com0in = fdopen(3, "r");
    if(com0in == NULL) {
        perror("com0in not open");
        exit(1);
    }
    com0out = fdopen(3, "w");
    if(com0out == NULL) {
        perror("com0out not open");
        exit(1);
    }
    
    return;			// for testing purpose
    
    com1in = fdopen(4, "r");
    if(com1in == NULL) {
        perror("com1in not open");
        exit(1);
    }
    com1out = fdopen(4, "w");
    if(com1out == NULL) {
        perror("com1out not open");
        exit(1);
    }
}

void runtime_clock() {
	/*
		Update the running time of the application
		args:
			none
		returns:
			none
	*/
	
	// define clock hour, min, sec
	const int MILISECONDDIVIDER = 100;
	int runtime = 0, last_runtime = 0;
	int hour = 0, min = 0, sec = 0, milisec = 0;
	while(1) {
		P(0);
		P(1);
		
		// time manipulation
		milisec += (runtime - last_runtime) / MILISECONDDIVIDER + 1;
        last_runtime = runtime;
        if(milisec >= 100) {
        	sec++;
        	milisec -= 100;
        }
		if(sec >= 60) {
			min++;
			sec -= 60;
		}
		if(min >= 60) {
			hour++;
			min -= 60;
		}
        global_hour=hour, global_min=min, global_sec=sec;
        
		V(1);
		V(0);
		
		runtime++;
	}
}

void welcome_ui(int channel) {
	/*
		Display welcome message
		args:
			file_descriptor = the output file descriptor of the port
		returns:
			none
	*/
	
	FILE* fd;
	if(channel == 0) fd = com0out;
	if(channel == 1) fd = com1out;
	
	// set terminal window size
	unsigned int screen_height = 43, screen_width = 132;
	fprintf(fd, "%s[8;%d;%dt", ESC, screen_height, screen_width);
	
	// clear the screen
	fprintf(fd, "\033[2J");
	
	// move cursor to (1, 1)
	fprintf(fd, "\033[1;1H");
	
	// disable cursor while drawing
	fprintf(fd, "%s", CURSORINVISIBLE);
	
	// draw the welcome box
	int welcome_box_size = 3;
	fprintf(fd, "╔═══════════════════════════════╗\n");
	fprintf(fd, "║ Welcome to Terminal Chat Box! ║\n");
	fprintf(fd, "╚═══════════════════════════════╝\n");
	
	// draw the instruction box
	int instruction_box_size = 5;
	fprintf(fd, "------------------------------------------------------------------\n");
	fprintf(fd, "Instruction:\n");
	fprintf(fd, "- just input your message in dude!\n");
	fprintf(fd, "- and make sure the message does not exceed 100 characters\n");
	fprintf(fd, "------------------------------------------------------------------\n");
	
	// save coordinate to draw clock
	fprintf(fd, "\n ** Current runtime \n");
	clock_pos_x = welcome_box_size + instruction_box_size + 2;
	clock_pos_y = 21;
	
	// print frame line
	fprintf(fd, "##!!==//##!!==//##!!==//##!!==//##!!==//##!!==//##!!==//##!!==//##\n");
	
	// save coordinate to write chat log
	chatlog_start_x = clock_pos_x + 2;
	chatlog_start_y = 1;
	
	// enable back cursor after drawing
	fprintf(fd, "%s", CURSORVISIBLE);
}

void draw_client_ui(int channel) {
	/*
		Draw the UI for each of the respective client
		args:
			file_descriptor = the output file descriptor of the port
		returns:
			none
	*/
	
	FILE* fd;
	if(channel == 0) fd = com0out;
	if(channel == 1) fd = com1out;
	
	// disable cursor while drawing
	fprintf(fd, "%s", CURSORINVISIBLE);
	
	// refresh current runtime
	gotoxy(channel, clock_pos_x, clock_pos_y);
	fprintf(fd, "%02d:%02d:%02d", global_hour, global_min, global_sec);		// (10, 20)
	
	//return;		// debug 
	
	chatlog_x = chatlog_start_x;
	chatlog_y = chatlog_start_y;
	
	// print chatlog
	if(chatlog_read_index < chatlog_write_index) {
		gotoxy(channel, chatlog_x, chatlog_y);
		fprintf(fd, "| Client%d: %s", chatlog_sender[chatlog_read_index] + 1, chatlog[chatlog_read_index]);
		
		chatlog_x++;
		chatlog_read_index++;
	}
	
	// enable back cursor after drawing
	// fprintf(fd, "%s", CURSORVISIBLE);
}

void client1() {
	/*
		Process the client1 related stuff
		args:
			none
		returns:
			none
	*/
	
	//return;
	
	welcome_ui(0);
	
	// testing purpose
	chatlog_sender[0] = 0;
	strcpy(chatlog[0], "Hi your message starts here\n");
	chatlog_write_index++;
	chatlog_size++;
	
	while(1) {
		// draw the ui for client1
		draw_client_ui(0);
		
		// get input from user
		// fscanf(com0in, "%c", &key_in);
		
		P(0);
		P(1);
		
		// input the string into chatlog
		
		V(1);
		V(0);	
	}
}

void client2() {
	/*
		Process the client2 related stuff
		args:
			none
		returns:
			none
	*/

	//return;
	
	while(1) {
		P(0);
		P(1);
		
		V(1);
		V(0);
	}
}


int main() {
    // initialization
    init_kernel();		// mandatory
    initPort();
    
    // set tasks and start scheduling
    set_task(runtime_clock);
    set_task(client1);
    set_task(client2);
    begin_sch();
	
	while(1)
	
    return 0;
}
