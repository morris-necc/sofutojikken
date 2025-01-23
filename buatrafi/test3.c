#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "mtk_c.h"

extern char inbyte(int);

// ========================================
// GLOBAL VARIABLES
// ========================================

// structure
typedef struct {
    char a;
    char b;
    char c;
    char d;
} four_digit;

typedef struct {
    int X;
    int Y;
} two_digit;

four_digit inputs[2];

int phase = 0;			// shared resource 0
bool setup_done[2];		// shared resource 1
four_digit answers[2];		// shared resource 2
four_digit guess;		// shared resource 3
int win_flag = 0;		// shared resource 4


// FILE descriptors for RS232C port
FILE *com0in;
FILE *com0out;
FILE *com1in;
FILE *com1out;

// ========================================
// USER-DEFINED FUNCTIONS
// ========================================

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

void drawWelcome() {
    /*
        Draw welcome message.
        args:
            none
        returns:
            none
    */
    fprintf(com0out, "Welcome to MASTERMIND GAME!\n");
    fprintf(com1out, "Welcome to MASTERMIND GAME!\n");
    fprintf(com0out, "Let's play! First is the initialization phase, please set a 4 digit (0-9) password!\n\n");
    fprintf(com1out, "Let's play! First is the initialization phase, please set a 4 digit (0-9) password!\n\n");
    
}

int isValidInput(char c) {
	/*
		Validate input. Check if each digit is between a and z
		args:
			c: input character
		returns:
			1 if valid, 0 otherwise
	*/

    if (c >= '0' && c <= '9') {
        return 1; // Valid
    }
    return 0; // Invalid
}

int inkey(int ch) {
	/*
		Judge if the specified key is pressed.
		args:
			ch: port number
		returns:
			1 if pressed, 0 otherwise
	*/
    char a = inbyte(ch);
    if(isValidInput(a)) { // if valid
        inputs[ch].a = a;
    }
    char b = inbyte(ch);
    if(isValidInput(b)) { // if valid
        inputs[ch].b = b;
    }
    char c = inbyte(ch);
    if(isValidInput(c)) { // if valid
        inputs[ch].c = c;
    }
    char d = inbyte(ch);
    if(isValidInput(d)) { // if valid
        inputs[ch].d = d;
        return 1;
    }
    return 0;			 // otherwise
}

two_digit judge(four_digit guess, four_digit answer) {
    two_digit res = {0, 0};  // Initialize X and Y to 0

    // Check for digits in the correct place (X)
    if (guess.a == answer.a) res.X++;
    else if (guess.a == answer.b || guess.a == answer.c || guess.a == answer.d) res.Y++;
    if (guess.b == answer.b) res.X++;
    else if (guess.b == answer.a || guess.b == answer.c || guess.b == answer.d) res.Y++;
    if (guess.c == answer.c) res.X++;
    else if (guess.c == answer.a || guess.c == answer.b || guess.c == answer.d) res.Y++;
    if (guess.d == answer.d) res.X++;
    else if (guess.d == answer.a || guess.d == answer.b || guess.d == answer.c) res.Y++;

    return res;
}

int is_game_over(two_digit res) {
	if (res.X == 4) return 1;
	else return 0;
}

void player1() {
//	P(5);
	/*
		Process task for player 1 ( = port 0).
		args:
			none
		returns:
			none
	*/
	while(1) {
		fprintf(com0out, "");
		fflush(com0out);
		int ch = 0;
		if (phase == 0) {
			if (setup_done[0] == false) {
				fprintf(com0out, "Player 1 Initialization Phase!\n");
				fflush(com0out);
//				fprintf(com1out, "Please wait for player 1 to complete the initialization phase.\n");
//				fflush(com1out);
				if (inkey(ch)) {
					
					P(1);	// secure setup_done
					P(2);	// secure answers
					
//					fprintf(com0out, "TASK 1 locked P(1), P(2)\n");
//					fflush(com0out);
					
					four_digit input = inputs[ch];
					answers[0] = input;
					setup_done[0] = true;
					fprintf(com0out, "P1 done setting up!\n Your password is %c %c %c %c\n", answers[0].a, answers[0].b, answers[0].c, answers[0].d);
					fflush(com0out);
					fprintf(com1out, "P1 done setting up!\n");
					fflush(com1out);
					
					V(1);
					V(2);
//					fprintf(com0out, "TASK 1 unlocked P(1), P(2)\n");
//					fflush(com0out);
				}
//			V(7);
//			P(5);
			}
			
				
//				P(0);	// secure phase
//				if (setup_done[0] == true && setup_done[1] == true) {
//					phase = 1;
//					fprintf(com0out, "Setup phase over. NOW GUESS!\n");
//					fflush(com0out);
//					fprintf(com1out, "Setup phase over. NOW GUESS!\n");
//					fflush(com1out);
//				}
//				V(0);
				
					
		}
		else if (phase == 1 && win_flag != 1) {
//			fprintf(com0out, "P1 Turn!\n");
//			fflush(com0out);
//			fprintf(com1out, "Wait for P1 Turn!\n");
//			fflush(com1out);
//			fprintf(com0out, "TASK 1 wait for INKEY\n");
//			fflush(com0out);
			if(inkey(ch)) {
//				fprintf(com0out, "TASK 1 wait for INKEY success\n");
//				fflush(com0out);
				P(3);	// secure guess
				P(4);	// secure win_flag
				
//				fprintf(com0out, "TASK 1 locked P(3), P(4)\n");
//				fflush(com0out);
				
				four_digit input = inputs[ch];
				guess = input;
				
				two_digit res = judge(guess, answers[1]);
				fprintf(com0out, "You guessed: %c %c %c %c\n", guess.a, guess.b, guess.c, guess.d);
				fflush(com0out);
				if (is_game_over(res)) {
					win_flag = 1;
				}
				else {
					fprintf(com0out, "Correct: %d, Misplaced: %d \n\n", res.X, res.Y);
					fflush(com0out);
				}
				V(3);
				V(4);

//				fprintf(com0out, "TASK 1 unlocked P(3), P(4)\n");
//				fflush(com0out);

				if (win_flag) {
					fprintf(com0out, "Congratulations! You win!\n");
		    			fprintf(com1out, "You lost the game\n");
		    			fflush(com0out);
		    			fflush(com1out);
		       		}
			}
		}
		else {
//			fprintf(com0out, "UNMATCHED CONDITION.\n");
//			fflush(com0out);
//			P(5);
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
//	P(6);
	while(1) {
		fprintf(com0out, "");
		fflush(com0out);
		int ch = 1;
		if (phase == 0) {
			if (setup_done[1] == false) {
				fprintf(com1out, "Player 2 Initialization Phase!\n");
				fflush(com1out);
//				fprintf(com0out, "Please wait for player 2 to complete the initialization phase.\n");
//				fflush(com0out);
				if (inkey(ch)) {
					P(1);	// secure setup_done
					P(2);	// secure answers
					
//					fprintf(com0out, "TASK 2 locked P(1), P(2)\n");
//					fflush(com0out);
					
					four_digit input = inputs[ch];
					answers[1] = input;
					setup_done[1] = true;
					fprintf(com1out, "P2 done setting up!\n Your password is %c %c %c %c\n", answers[1].a, answers[1].b, answers[1].c, answers[1].d);
					fflush(com1out);
					fprintf(com0out, "P2 done setting up!\n");
					fflush(com0out);
					
					
					V(1);
					V(2);
					
//					fprintf(com0out, "TASK 2 unlocked P(1), P(2)\n");
//					fflush(com0out);
						
	//				P(0);	// secure phase
	//				if (setup_done[0] == true && setup_done[1] == true) {
	//					phase = 1;
	//					fprintf(com0out, "Setup phase over. NOW GUESS!\n");
	//					fflush(com0out);
	//					fprintf(com1out, "Setup phase over. NOW GUESS!\n");
	//					fflush(com1out);
	//				}
	//				V(0);
				}
//			V(7);
//			P(6);
			}
		}
		
		else if (phase == 1 && win_flag != 1) {
//			fprintf(com0out, "Wait for P2 Turn!\n");
//			fflush(com0out);
//			fprintf(com1out, "P2 Turn!\n");
//			fflush(com1out);
//			fprintf(com0out, "TASK 2 wait for INKEY\n");
//			fflush(com0out);
			if(inkey(ch)) {
//				fprintf(com0out, "TASK 2 wait for INKEY success\n");
//				fflush(com0out);	
				P(3);	// secure guess
				P(4);	// secure win_flag
				
//				fprintf(com0out, "TASK 2 locked P(3), P(4)\n");
//				fflush(com0out);
				
				four_digit input = inputs[ch];
				guess = input;
				
				two_digit res = judge(guess, answers[0]);
				
				fprintf(com1out, "You guessed: %c %c %c %c\n", guess.a, guess.b, guess.c, guess.d);
				fflush(com1out);
				
				if (is_game_over(res)) {
					win_flag = 1;
				}
				else {
					fprintf(com1out, "Correct: %d, Misplaced: %d \n\n", res.X, res.Y);
					fflush(com1out);
				}
				V(3);
				V(4);
				
//				fprintf(com0out, "TASK 2 unlocked P(3), P(4)\n");
//				fflush(com0out);
				
				if (win_flag) {
					fprintf(com1out, "Congratulations! You win!\n");
		    			fprintf(com0out, "You lost the game\n");
		    			fflush(com0out);
		       			fflush(com1out);
		       		}
			}
		}
		else {
//			fprintf(com1out, "UNMATCHED CONDITION.\n");
//			fflush(com1out);
//			P(6);
		}
	}
}

void task3() {
//	P(7);
//	P(7);
	while(1) {
		fprintf(com0out, "");
		fflush(com0out);
//		fprintf(com1out, "TASK 3!\n");
//		fflush(com1out);
		if (setup_done[0] == true && setup_done[1] == true && phase != 1) {
			P(0);
			phase = 1;
			fprintf(com0out, "Setup phase over. NOW GUESS!\n");
			fflush(com0out);
			fprintf(com1out, "Setup phase over. NOW GUESS!\n");
			fflush(com1out);
			V(0);
//			P(7);
		}
		else {
//			P(7);
		}
//		V(5);
//		V(6);
//		fprintf(com0out, "TASK 3 done\n");
//		fflush(com0out);
	}
}
// ========================================
// MAIN FUNCTIONS
// ========================================

int main() {
    // inits
    init_kernel();
    initPort();

    drawWelcome();

// set tasks and start scheduling
    set_task(player1);
    set_task(player2);
    set_task(task3);
    
    begin_sch();
    return 0;
}
