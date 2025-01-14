#include <stdio.h>
#include <stdlib.h>
#include "mtk_c.h"

extern char inbyte(int);

// ========================================
// GLOBAL VARIABLES
// ========================================

// cell state
#define EMPTY 0
#define FILLED 1

// matrix size
#define ROWS 4
#define COLS 4

// random seed
unsigned int seed;

// coordinate structure
typedef struct {
    int x;
    int y;
} Coordinate;

// key map
Coordinate keyMap[128]; // within ASCII code range

// user inputs
char inputs[2];

// FILE descriptors for RS232C port
FILE *com0in;
FILE *com0out;
FILE *com1in;
FILE *com1out;

// ========================================
// SHARE RESOURCES
// ========================================

// share resource 0 (coordinate to specify)
Coordinate ch_p;

// share resource 1 (board)
int matrix[ROWS][COLS] = {			// init board
    {EMPTY, EMPTY, FILLED, EMPTY},
    {EMPTY, EMPTY, FILLED, FILLED},
    {FILLED, FILLED, FILLED, EMPTY},
    {EMPTY, EMPTY, FILLED, FILLED},
};

// share resource 2 (game end flag)
int win_flag = 0;

// ========================================
// USER-DEFINED FUNCTIONS
// ========================================

// 0. INITIALIZATION
void initKeymap() {
	/*
		initialize key map.
		args:
			none
		returns:
			none
	*/
    keyMap['4'] = (Coordinate){0, 0};
    keyMap['5'] = (Coordinate){0, 1};
    keyMap['6'] = (Coordinate){0, 2};
	keyMap['7'] = (Coordinate){0, 3};
	keyMap['r'] = (Coordinate){1, 0};
	keyMap['t'] = (Coordinate){1, 1};
	keyMap['y'] = (Coordinate){1, 2};
	keyMap['u'] = (Coordinate){1, 3};
	keyMap['f'] = (Coordinate){2, 0};
	keyMap['g'] = (Coordinate){2, 1};
	keyMap['h'] = (Coordinate){2, 2};
	keyMap['j'] = (Coordinate){2, 3};
	keyMap['v'] = (Coordinate){3, 0};
	keyMap['b'] = (Coordinate){3, 1};
	keyMap['n'] = (Coordinate){3, 2};
	keyMap['m'] = (Coordinate){3, 3};
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

// 1. DRAWING
void resetCur(int move) {
	/*
		Reset cursor position to the left end of the border.
		args:
			move: number of lines to move
		returns:
			none
	*/
    fprintf(com0out, "\033[%dA", move);
    fprintf(com1out, "\033[%dA", move);
}

void resetMatrix() {
	/*
		Reset matrix for the board.
		args:
			none
		returns:
			none
	*/
    srand(seed);                        // set rand seed
    for(int i = 0; i < ROWS; i++) {
        for(int j = 0; j < COLS; j++) {
            matrix[i][j] = rand() % 2;  // EMPTY or FILLED
        }
    }
}

void drawWelcome() {
    /*
        Draw welcome message.
        args:
            none
        returns:
            none
    */
    fprintf(com0out, "WELCOME to 4x4 MATRIX GAME\n");
    fprintf(com1out, "WELCOME to 4x4 MATRIX GAME\n");
    fprintf(com0out, "Let's play!\n\n");
    fprintf(com1out, "Let's play!\n\n");
}

void drawBorder(FILE* output) {
	/*
		Draw border for a line.
		args:
			output: file descriptor for RS232C port
		returns:
			none
	*/
    for(int i = 0; i < COLS + 2; i++) {
        fprintf(output, "%c", '-');
    }
    fprintf(output, "\n");
}

void drawField() {
	/*
		Draw board.
		args:
			none
		returns:
			none
	*/

    // draw upper border
    drawBorder(com0out);
    drawBorder(com1out);
    // draw matrix
    for(int i = 0; i < ROWS; i++) {
        fprintf(com0out, "|");
        fprintf(com1out, "|");
        for(int j = 0; j < COLS; j++) {
            fprintf(com0out, "%d", matrix[i][j]);
            fprintf(com1out, "%d", matrix[i][j]);
        }
        fprintf(com0out, "|\n");
        fprintf(com1out, "|\n");
    }
    // draw lower border
    drawBorder(com0out);
    drawBorder(com1out);
    // reset cursor
    resetCur(6);
}

int isValidInput(char c) {
	/*
		Validate input.
		args:
			c: input character
		returns:
			1 if valid, 0 otherwise
	*/

    return (c == '4' || c == '5' || c == '6' || c == '7' ||
            c == 'r' || c == 't' || c == 'y' || c == 'u' ||
            c == 'f' || c == 'g' || c == 'h' || c == 'j' ||
            c == 'v' || c == 'b' || c == 'n' || c == 'm');
}

int inkey(int ch) {
	/*
		Judge if the specified key is pressed.
		args:
			ch: port number
		returns:
			1 if pressed, 0 otherwise
	*/

    char c = inbyte(ch);
    if(c == inputs[ch]) { // if duplicated
        return 0;
    }
    if(isValidInput(c)) { // if valid
        inputs[ch] = c;
        return 1;
    }
    return 0;			 // otherwise
}

int judge() {
	/*
		Judge if the game is over.
		args:
			none
		returns:
			none
	*/
    for(int i = 0; i < ROWS; i++) {
        for(int j = 0; j < COLS; j++) {
            if (matrix[i][j] == FILLED) {
                return 0;	// continue
            }
        }
    }
    return 1; 				// game over
}

void setChangePoint(char input) {
	/*
		Set coordinate according to input.
		args:
			input: input character
		returns:
			none
	*/
    if(isValidInput(input)) {
        ch_p = keyMap[input];
    }
}

void updateBoard() {
	/*
		Update board matrix according to current input coordinate.
		args:
			none
		returns:
			none
	*/
    for(int i = 0; i < 5; i++) {
        int x = ch_p.x;
        int y = ch_p.y;
        if(0 <= x && x < ROWS && 0 <= y && y < COLS) {
            matrix[x][y] = (matrix[x][y] == EMPTY) ? FILLED : EMPTY;
        }
    }
}

void changeBoard(int ch) {
	/*
		Change board according to port.
		args:
			ch: port number
		returns:
			none
	*/
    char c = inputs[ch];

    setChangePoint(c);
    updateBoard();
    drawField();

    if(judge()) {
        win_flag = 1;
    }
}

void seed_task() {
	/*
		Generate seed for random number.
		args:
			none
		returns:
			none
	*/
    while(1) {
        seed = rand();
    }
}

void player1() {
	/*
		Process task for player 1 ( = port 0).
		args:
			none
		returns:
			none
	*/
    while(1) {
        int ch = 0;
        if(inkey(ch)) {
            P(0);	// secure coordinate
            P(1);	// secure board
            P(2);	// secure game end flag

            changeBoard(ch);

            V(0);
            V(1);

            if(win_flag) {
                fprintf(com0out, "You win!!\n");
                fprintf(com1out, "You lose...\n");
                fprintf(com0out, "Let's play again:)\n\n");
                fprintf(com1out, "Let's play again:)\n\n");

                // reset and redraw board
                resetMatrix();
                drawWelcome();
                drawField();
                win_flag = 0;
            }
            V(2);
        }
    }
}

void player2() {
	/*
		Process task for player 2 ( = port 1).
		args:
			none
		returns:
			none
	*/
    while(1) {
        int ch = 1;
        if(inkey(ch)) {
            P(0);	// secure coordinate
            P(1);	// secure board
            P(2);	// secure game end flag

            changeBoard(ch);

            V(0);
            V(1);

            if(win_flag) {
                fprintf(com0out, "You lose...\n");
                fprintf(com1out, "You win!!\n");
                fprintf(com0out, "Let's play again:)\n\n");
                fprintf(com1out, "Let's play again:)\n\n");

                // reset and redraw board
                resetMatrix();
                drawWelcome();
                drawField();
                win_flag = 0;
            }
            V(2);
        }
    }
}

// ========================================
// MAIN FUNCTIONS
// ========================================

int main() {
    // inits
    init_kernel();
    initPort();
    initKeymap();
    ch_p.x = -1; ch_p.y = -1; // init coordinate

    drawWelcome();
    drawField();

	// set tasks and start scheduling
    set_task(seed_task);
    set_task(player1);
    set_task(player2);
    begin_sch();

    return 0;
}