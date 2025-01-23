#include <stdio.h>
#include <stdlib.h>
#include "mtk_c.h"
#include <stdbool.h>

extern char inbyte(int);

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
	int is_turn;
	int port;
	int score;
	FILE *input;
	FILE* output;
}Player;

//init players: player "O" starts 
Player player_x={'X',0,1,0,NULL,NULL};
Player player_O={'O',1,0,0,NULL,NULL};

int win_flg=0;

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
	fprintf(player_x.output, "\033[%d;%dH", 1, 1);
	fprintf(player_O.output, "\033[%d;%dH", 1, 1);
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
char valid_cells_copy[9] = {'0', '1', '2', '3', '4', '5', '6', '7', '8'};
int valid_cells_length=9;

//fct for tracking empty cells
bool is_valid_cell(char cell) {
    for (int i = 0; i < 9; i++) {
        if (valid_cells[i] == cell) return true;
    }
    return false;
}

void remove_cell(char cell) {
    for (int i = 0; i < valid_cells_length; i++) {
        if (valid_cells[i] == cell) {
            // Shift the remaining cells
            for (int j = i; j < valid_cells_length - 1; j++) {
                valid_cells[j] = valid_cells[j + 1];
            }
            //valid_cells[i]='n';
            valid_cells_length=valid_cells_length-1;
            break;
        }
    }
}
//draws the init Tic-Tac-Toe board for both players
void init_board() {

	//fprintf(player_x.output,"\033[2J");
	//fprintf(player_x.output,"\033[2J");
	valid_cells_length=9;
	win_flg=0;
	for (int i = 0; i < 9; i++) {
		valid_cells[i]=valid_cells_copy[i];
	}
	for (int i = 0; i < 3; i++) {
        	for (int j = 0; j < 3; j++) {
        		board[i][j]='0'+i*3+j;
        		b_board[i][j]=0;
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
	//Clear the screen
	fprintf(player_x.output,"\033[2J");
	fprintf(player_O.output,"\033[2J");
	// disable cursor while drawing
	//fprintf(player_x.output, "%s", CURSORINVISIBLE);
	//fprintf(player_O.output, "%s", CURSORINVISIBLE);
	fprintf(player_x.output, "\033[%d;%dH", 1, 1);
	fprintf(player_O.output, "\033[%d;%dH", 1, 1);
	 //fprintf(player_O.output,"%d\n",valid_cells_length);
         //fprintf(player_x.output,"%d\n",valid_cells_length);
    	for (int i = 0; i < 3; i++) {
        	for (int j = 0; j < 3; j++) {
            		fprintf(player_x.output," %c ", board[i][j]); // Print the current cell value
            		fprintf(player_O.output," %c ", board[i][j]);
            		if (j < 2) {
            			fprintf(player_x.output,"|");     // Print column separator
            			fprintf(player_O.output,"|"); 
            			}
       			 }
        		fprintf(player_x.output,"\n");
        		fprintf(player_O.output,"\n");
        	if (i < 2) {
        		fprintf(player_x.output,"---+---+---\n"); // Print row separator
        		fprintf(player_O.output,"---+---+---\n");
    }
    	
	
	
    }
	
 }
    
void binary_board(char mark){//changes the X/O to 0/1
	for (int i = 0; i < 3;i++){
		for (int j = 0; j < 3;j++){
			if(board[i][j]==mark){//mark is either X or O ,depending on who's playing
				b_board[i][j] = 1;
			}
			else b_board[i][j]=0;
		}
	}
}


//we check after changing the X/O to 1/0 depending on who's playing
int check_win(FILE* screen,int in,char mark){//in is the last input cell [0..8]
	int row= in/3;
	int col = in % 3;
	int win[2] = {1,1};//if equals 3 means win
	binary_board(mark);
	//fprintf(screen,"%d \n,",row);
	//fprintf(screen,"%d \n",col);
	for (int i = 0; i < 3;i++){
		for (int j = 0; j < 3;j++){
	fprintf(screen,"%d,",b_board[i][j]);
	}}
	// this for loop can detect if there's a win vertically or horizontally
	for (int i = 1; i < 3; i++)
	{
		if (col+i-1 < 2)
		{
			win[0] = win[0]+b_board[row][col + i];
		}
		if (col - i + 1 > 0)
		{
			win[0] = win[0]+b_board[row][col - i];
		}

		if(row+i-1<2){
			win[1] = win[1]+b_board[row+i][col];
		}
		if(row-i+1>0){
			win[1] = win[1]+b_board[row-i][col];
		}
	}
	for (int i = 0; i < 2; i++){
		//fprintf(screen,"%d \n",win[i]);
		if(win[i]==3){
			//fprintf(screen, "vert/horiz win\n");
			win_flg=1;
			return 1;
			}
	}
	if (in == 4)
	{
		int win1 = b_board[0][0] + b_board[1][1] + b_board[2][2];
		int win2 = b_board[0][2] + b_board[1][1] + b_board[2][0];
		if(win1==3||win2==3){
			fprintf(screen, "diag1wi\n");
			win_flg=1;
			return 1;}
	} else if(in%4==0){
		int win=b_board[0][0] + b_board[1][1] + b_board[2][2];
		if (win==3){
			fprintf(screen, "diag2win\n");
			win_flg=1;
			return 1;
			}
	}else if(in%4==2){
		int win=b_board[0][2] + b_board[1][1] + b_board[2][0];
		if(win==3){
			//fprintf(screen, "diag3win\n");
			win_flg=1;
			return 1;
	}}
	else
		return 0;
	return 0;
}


void player_maru() {
	
	
	
	while (1)
	{
		P(0);
		char cell;
		bool valid = false;
		player_x.is_turn = false;
		player_O.is_turn=true;
		display_board(); // Show the updated board
		while (!valid) {
			// choose a cell
			fprintf(player_O.output, "Player 'O', choose a cell (0-8): \n");
			fprintf(player_O.output,"%s", CURSORVISIBLE);//enable cursor
			cell = inbyte(player_O.port);
			// Validate the chosen cell
			if (is_valid_cell(cell)) {
				valid = true;
				update_board(cell-'0', player_O.mark);  // Place 'O' on the board
				remove_cell(cell);       // Remove the cell from the available list
			} else 
				fprintf(player_O.output, "Invalid cell. Try again.\n");
		}

		if (check_win(player_O.output,cell-'0',player_O.mark)||valid_cells_length==0) {
			display_board();
			V(1);
			P(0);
			V(0);
			//break;
		}
		else
		{
			//valid = false;
			V(0);
		}
	}
}

void win_lose_msg(){
	P(1);
	P(1);
	
	if (win_flg){
	if(player_O.is_turn){
		
		player_O.score = player_O.score + 1;
		fprintf(player_O.output, "your score is: %d\n", player_O.score);
		fprintf(player_x.output, "your score is: %d\n", player_x.score);
		fprintf(player_O.output, "You win!!\n");
		fprintf(player_x.output, "You lose...\n");
		}
	else{
			player_x.score = player_x.score + 1;
			fprintf(player_O.output, "your score is: %d\n", player_O.score);
			fprintf(player_x.output, "your score is: %d\n", player_x.score);
			fprintf(player_x.output, "You win!!\n");
			fprintf(player_O.output, "You lose...\n");
		}
	}else{
	
		fprintf(player_O.output,"It's a draw!\n");
        	fprintf(player_x.output,"It's a draw!\n");
        	fprintf(player_O.output, "your score is: %d\n", player_O.score);
		fprintf(player_x.output, "your score is: %d\n", player_x.score);
	}
	fprintf(player_O.output, "Do you want to play again? y/n \n");
	fprintf(player_x.output, "Do you want to play again? y/n \n");
	while (1)
	{
		char again_O = inbyte(player_O.port);
		char again_x = inbyte(player_x.port);
		if (again_O == 'y' && again_x == 'y')
		{
			init_board();
			V(0);
			P(1);
			
		}
		else
		{
			fprintf(player_O.output, "Game is over\n Your score is %d", player_O.score);
			fprintf(player_x.output, "Game is over\n Your score is %d", player_x.score);

			while(1){}
		}
	}
}
void task_player_x() {
	//char cell ;
	
	while(1){
		//fprintf(player_x.output,"Hello player x");
		P(0);
		char cell;
		bool valid = false;
		player_x.is_turn = true;
		player_O.is_turn = false;
		display_board(); // Show the updated board
		while (!valid) {
			//choose a cell
			fprintf(player_x.output, "Player 'X', choose a cell (0-8): \n");
			fprintf(player_x.output,"%s", CURSORVISIBLE);//enable cursor
			cell = inbyte(player_x.port);
			fprintf(player_x.output, "Player 'X', cell chosen: \n");
			// Validate the chosen cell
			if (is_valid_cell(cell)) {
				valid = true;
				update_board(cell-'0', player_x.mark);  // Place 'X' on the board
				remove_cell(cell);       // Remove the cell from the available list
			} else {
				fprintf(player_x.output, "Invalid cell. Try again.\n");
			}
		}

		if(check_win(player_x.output,cell-'0',player_x.mark)||valid_cells_length==0) {
			display_board();//clears screen
            		V(1);
			P(0);
			V(0);
			//break;
		}else
		{
			//valid = false;
			V(0);
		}
               
}
}


int main()
{
	// initialization
	init_kernel();
	init_ports();

	
	set_task(player_maru);
	set_task(task_player_x);
    set_task(win_lose_msg);
    	

    	begin_sch();
    	return 0;
	
}

