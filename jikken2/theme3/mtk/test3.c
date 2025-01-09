#include <stdio.h>
#include <stdlib.h>
#include "mtk_c.h"
#include <stdbool.h>


//For clearing the screen
#define ESC "\x1b"
#define HOME ESC "[H"
#define DELETESCREEN ESC "[2J"
#define CURSORINVISIBLE ESC "[?25l"
#define CURSORVISIBLE ESC "[?25h"

#define SAVECURSORLOC ESC "7"
#define RETCURSORLOC ESC "8"

typedef struct{
	char mark;
	bool is_turn;
	FILE* input;
	FILE* output;
}Player;

Player player_x={"X",false,NULL,NULL};
Player player_O={"O",true,NULL,NULL};

void init_players(){
	int success=4;
	while (success>4){
		player_x.input=fdopen(4,"r") ;
		if(player_x.input!=NULL) success--;
		player_x.output=fdopen(4,"w") success--;
		if(player_x.output!=NULL) success--;
		player_O.input=fdopen(3,"r");
		if (player_O.input!=NULL) success--;
		player_O.output=fdopen(3,"w");
		if (player_O.output!=NULL) success--;
		}
		
	
	
//global variables for functions
int b_board[3][3]={0};
char board[3][3] = {
    {'0', '1', '2'},
    {'3', '4', '5'},
    {'6', '7', '8'}
};
int valid_cells[9] = {0, 1, 2, 3, 4, 5, 6, 7, 8};
bool player_X_playing = false;

//fct for tracking empty cells
bool is_valid_cell(int cell) {
    for (int i = 0; i < valid_cells.length(); i++) {
        if (valid_cells[i] == cell) return true;
    }
    return false;
}

void remove_cell(int cell) {
    for (int i = 0; i < valid_cells.length(); i++) {
        if (valid_cells[i] == cell) {
            // Shift the remaining cells
            for (int j = i; j < valid_cells.length() - 1; j++) {
                valid_cells[j] = valid_cells[j + 1];
            }
            break;
        }
    }
}
//updates the board after each player move
void update_board(int cell, char mark) {
    int row = cell / 3;
    int col = cell % 3;
    board[row][col] = mark;
}
//displays the board after the change
void display_board() {
	FILE* screen;
	if (player_X_playing) screen=com1out;
	else screen = com0out;
	// disable cursor while drawing
	fprintf(screen, "%s", CURSORINVISIBLE);
	
    	for (int i = 0; i < 3; i++) {
        	for (int j = 0; j < 3; j++) {
            		fprintf(screen," %c ", board[i][j]); // Print the current cell value
            		if (j < 2) fprintf(screen,"|");     // Print column separator
       			 }
        		fprintf(screen,"\n");
        if (i < 2) fprintf(screen,"---+---+---\n"); // Print row separator
    }
    	fprintf(screen,"\n");
	// enable cursor
	fprintf(screen, "\033[%d;%dH", 24, 1);
	fprintf(screen, "%s", CURSORVISIBLE);
	
	fflush(screen);
    }

void player_maru() {
	int cell = -1;
	bool valid = false;
	player_X_playing = false;
	while (1)
	{
		P(0);

		while (!valid) {
			// choose a cell
			fprintf(com0out, "Player 'O', choose a cell (0-8): ");
			fscanf(com0in, "%d", &cell);

			// Validate the chosen cell
			if (is_valid_cell(cell)) {
				valid = true;
				update_board(cell, 'O');  // Place 'O' on the board
				remove_cell(cell);       // Remove the cell from the available list
			} else {
				fprintf(com0out, "Invalid cell. Try again.\n");
			}
		}
		display_board(); // Show the updated board
		V(0);
	}
}
void player_x() {
		
	int cell = -1;
	bool valid = false;
	player_X_playing = true;
	while(1){
		P(0);


		while (!valid) {
			// Prompt the player to choose a cell
			fprintf(com1out, "Player 'X', choose a cell (0-8): ");
			fscanf(com1in, "%d", &cell);

			// Validate the chosen cell
			if (is_valid_cell(cell)) {
				valid = true;
				update_board(cell, 'X');  // Place 'X' on the board
				remove_cell(cell);       // Remove the cell from the available list
			} else {
				fprintf(com1out, "Invalid cell. Try again.\n");
			}
		}
		display_board(); // Show the updated board
		V(0);
	}
}
void hurry_msg() {
 
    if (player_X_playing) {
        fprintf(com0out, "Hurry up! you are taking sooo long!!!\n");
    } else {
        fprintf(com1out, "Hurry up! you are taking sooo long!!!\n");
    }
	while (1) {
		display_board();
	}
}
//draws the init Tic-Tac-Toe board for both players
void init_board() {
    fprintf(com0out, "\nTic-Tac-Toe Board:\n");
    fprintf(com1out, "\nTic-Tac-Toe Board:\n");

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            // Print the current cell (e.g., 0..8 initially)
            fprintf(com0out, "%c ", board[i][j]);
            fprintf(com1out, "%c ", board[i][j]);

            if (j < 2) {
                fprintf(com0out, "| ");
                fprintf(com1out, "| ");
            }
        }
        fprintf(com0out, "\n");
        fprintf(com1out, "\n");

        if (i < 2) {
            // Print separator between rows
            fprintf(com0out, "---------\n");
            fprintf(com1out, "---------\n");
        }
    }

    fprintf(com0out, "\n");
    fprintf(com1out, "\n");
}

void binary_board(char board[3][3],char mark){//changes the X/O to 0/1
	for (int i = 0; i < 3;i++){
		for (int j = 0; j < 3;j++){
			if(board[i][j]==mark){//mark is either X or O ,depending on who's playing
				b_board[i][j] = 1;
			}
		}
	}
}
//we check after changing the X/O to 1/0 depending on who's playing
int check_win(char board[3][3],int in,char mark){//in is the last input cell [0..8]
	int row= in/3;
	int col = in % 3;
	int win = 1;//if equals 3 means win
	binary_board(board, mark);
	// this for loop can detect if there's a win vertically or horizontally
	for (int i = 1; i < 3; i++)
	{
		if (col+i-1 < 2)
		{
			win = +b_board[row][col + i];
		}
		if (col-i+1>0){
			win = +b_board[row][col - i];
		}
		if(row+i-1<2){
			win = +b_board[row+i][col];
		}
		if(row-i+1>0){
			win = +b_board[row-i][col];
		}
	}
	if(win==3)
		return 1;

	if (in == 4)
	{
		int win1 = b_board[0][0] + b_board[1][1] + b_board[2][2];
		int win2 = b_board[0][2] + b_board[1][1] + b_board[2][0];
		if(win1==3||win2==3)
			return 1;
	} else if(in%4==0){
		int win=b_board[0][0] + b_board[1][1] + b_board[2][2];
		if (win==3)
			return 1;
	}else if(in%4==2){
		int win=b_board[0][2] + b_board[1][1] + b_board[2][0];
		if(win==3)
			return 1;
	}
	else
		return 0;
	return 0;
}


void init_ports() {
	int success = 4;
	while(success > 0){
		com0in = fdopen(3, "r");
		if (com0in != NULL) success--;
	
		com0out = fdopen(3, "w");
		if (com0out != NULL) success--;
	
		com1in = fdopen(4, "r");
		if (com1in != NULL) success--;
	
		com1out = fdopen(4, "w");
		if (com1out != NULL) success--;
	}
	
	fprintf(com0out, "Ports Initialized! \n");
	fprintf(com1out, "Ports Initialized! \n");
}

int main()
{
	// initialization

	init_ports();

	init_board();
	set_task(player_maru);
	set_task(player_x);
    	set_task(hurry_msg);

    	begin_sch();
    	return 0;
	
}


