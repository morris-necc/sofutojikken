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

//FILE *com0in;
//FILE *com0out;
//FILE *com1in;
//FILE *com1out;


typedef struct{
	char* mark;
	bool is_turn;
	FILE* input;
	FILE* output;
}Player;

//init players
Player player_x={"X",false,NULL,NULL};
Player player_O={"O",true,NULL,NULL};

void init_ports(){
	int success=4;
	while (success>0){
		player_x.input=fdopen(4,"r") ;
		if(player_x.input!=NULL) success--;
		player_x.output=fdopen(4,"w");
		if(player_x.output!=NULL) success--;
		player_O.input=fdopen(3,"r");
		if (player_O.input!=NULL) success--;
		player_O.output=fdopen(3,"w");
		if (player_O.output!=NULL) success--;
		}
	fprintf(player_x.output, "Ports Initialized! \n");
	fprintf(player_O.output, "Ports Initialized! \n");
	}	
	
	
//global variables for functions
int b_board[3][3]={0};
char board[3][3] = {
    {'0', '1', '2'},
    {'3', '4', '5'},
    {'6', '7', '8'}
};
char valid_cells[9] = {'0', '1', '2', '3', '4', '5', '6', '7', '8'};
int valid_cells_length=9;

//fct for tracking empty cells
bool is_valid_cell(int cell) {
    for (int i = 0; i < valid_cells_length; i++) {
        if (valid_cells[i] == cell) return true;
    }
    return false;
}

void remove_cell(int cell) {
    for (int i = 0; i < valid_cells_length; i++) {
        if (valid_cells[i] == cell) {
            // Shift the remaining cells
            for (int j = i; j < valid_cells_length - 1; j++) {
                valid_cells[j] = valid_cells[j + 1];
            }
            valid_cells_length-=1;
            
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
	if (player_x.is_turn) screen=player_x.output;
	else screen = player_O.output;
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
    	fflush(screen);
	// enable cursor
	fprintf(screen, "\033[%d;%dH", 24, 1);
	fprintf(screen, "%s", CURSORVISIBLE);
	
	
    }

void player_maru() {
	char cell;
	bool valid = false;
	player_x.is_turn = false;
	while (1)
	{
		//fprintf(player_O.output,"Hello player O \n");
		P(0);

		while (!valid) {
			// choose a cell
			fprintf(player_O.output, "Player 'O', choose a cell (0-8): \n");
			fscanf(player_O.input, "%c", &cell);

			// Validate the chosen cell
			if (is_valid_cell(cell)) {
				valid = true;
				update_board(cell, 'O');  // Place 'O' on the board
				remove_cell(cell);       // Remove the cell from the available list
			} else {
				fprintf(player_O.output, "Invalid cell. Try again.\n");
			}
		}
		display_board(); // Show the updated board
		V(0);
	}
}
void task_player_x() {
		
	int cell = -1;
	bool valid = false;
	player_x.is_turn = true;
	
	while(1){
		fprintf(player_x.output,"Hello player x");
		P(0);


		while (!valid) {
			// Prompt the player to choose a cell
			fprintf(player_x.output, "Player 'X', choose a cell (0-8): ");
			fscanf(player_x.input, "%d", &cell);

			// Validate the chosen cell
			if (is_valid_cell(cell)) {
				valid = true;
				update_board(cell, 'X');  // Place 'X' on the board
				remove_cell(cell);       // Remove the cell from the available list
			} else {
				fprintf(player_x.output, "Invalid cell. Try again.\n");
			}
		}
		display_board(); // Show the updated board
		V(0);
	}
}
void hurry_msg() {
 
    if (player_x.is_turn) {
        fprintf(player_x.output, "Hurry up! you are taking sooo long!!!\n");
    } else {
        fprintf(player_O.output, "Hurry up! you are taking sooo long!!!\n");
    }
	while (1) {
		display_board();
	}
}
//draws the init Tic-Tac-Toe board for both players
void init_board() {
    fprintf(player_x.output, "\nTic-Tac-Toe Board:\n");
    fprintf(player_O.output, "\nTic-Tac-Toe Board:\n");

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            // Print the current cell (e.g., 0..8 initially)
            fprintf(player_x.output, "%c ", board[i][j]);
            fprintf(player_O.output, "%c ", board[i][j]);

            if (j < 2) {
                fprintf(player_x.output, "| ");
                fprintf(player_O.output, "| ");
            }
        }
        fprintf(player_x.output, "\n");
        fprintf(player_O.output, "\n");

        if (i < 2) {
            // Print separator between rows
            fprintf(player_x.output, "---------\n");
            fprintf(player_O.output, "---------\n");
        }
    }

    fprintf(player_x.output, "\n");
    fprintf(player_O.output, "\n");
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


int main()
{
	// initialization
	init_kernel();
	init_ports();

	init_board();
	set_task(player_maru);
	set_task(task_player_x);
    	//set_task(hurry_msg);

    	begin_sch();
    	return 0;
	
}

