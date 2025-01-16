#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>
#include "mtk_c.h"

extern char inbyte(int ch);

// Bugs
// Turn not ending
// map updating after the cursor is moved onto its position


// Global variabes
FILE *com0in;
FILE *com0out;
FILE *com1in;
FILE *com1out;

#define ROWS 10
#define COLS 10

#define EMPTY 0
#define SHIP 1
#define HIT 2
#define MISS 3
#define MARKER 4

//For clearing the screen
#define ESC "\x1b"
#define HOME ESC "[H"
#define DELETESCREEN ESC "[2J"
#define CURSORINVISIBLE ESC "[?25l"
#define CURSORVISIBLE ESC "[?25h"

#define SAVECURSORLOC ESC "7"
#define RETCURSORLOC ESC "8"

typedef struct {
	int x;
	int y;
	int enterPressed;
	int prevMarker[2]; //0 = map, 1 = opp_map
	int hits;
	
	char map[ROWS][COLS];
	char opp_map[ROWS][COLS]; //all empty in the beginning
	char input;
	
	bool orientation; //true horizontal, false vertical
	bool fired;
} Player;

typedef struct {
	int screenX;
	int screenY;
} screenCoords;


//shared?
int stage = 0;
int player1done = 0;
int player2done = 0;
Player players[2];
int shipSizes[] = {5, 4, 3, 3, 2};

screenCoords calcScreenCoords(int x, int y, int map) {
	screenCoords calculated;
	calculated.screenY = 3 + y * 2;
	calculated.screenX = 3 + x * 4 + map * 61;
	return calculated;
}


char mapIcons(int key) {
	char icons[5] = " SOXx"; //0: empty, 1: ship, 2: hit, 3: miss, 4: marker
	return icons[key];
}

bool isValid(char c) {
	if (stage == 0) {
		return (c == 'r' || c == 'w' || c == 'a' || c == 's' || c == 'd' || c == 'f');
	} else {
		return (c == 'w' || c == 'a' || c == 's' || c == 'd' || c == 'f');
	}
}

bool getValidInput(int turn) {
	char c = inbyte(turn);
	if (isValid(c)) {
		players[turn].input = c;
		return true;
	}
	return false; //else
	
}

void printIntro() {
	fprintf(com0out, "===========================================================\n");
	fprintf(com0out, "              WELCOME TO BATTLESHIP, PLAYER 1              \n");
	fprintf(com0out, "===========================================================\n");
	
	fprintf(com1out, "===========================================================\n");
	fprintf(com1out, "              WELCOME TO BATTLESHIP, PLAYER 2              \n");
	fprintf(com1out, "===========================================================\n");
	
	fprintf(com0out, "SET UP YOUR SHIPS!!! Press any key to continue... \n");
	fprintf(com1out, "SET UP YOUR SHIPS!!! Press any key to continue... \n");
	
	char a, b;
	
	while(1) {
		a = fscanf(com0in, "%c", &a);
		b = fscanf(com1in, "%c", &b);
		
		
		fprintf(com0out, "Player 1: %c", a);
		fprintf(com1out, "Player 2: %c", b);
		
		a = '1';
		b = '2';
		if (a && b) break;
	}
}

bool checkMovable(int size, int turn, char in) {
	// checks if ship is movable
	// DONE
	// check border (not efficient since we could've checked earlier, but who cares)
	if (in == 'a' && players[turn].x - 1 < 0) return false;
	if (in == 'w' && players[turn].y - 1 < 0) return false; 
	if (in == 's' && players[turn].y + 1 >= ROWS) return false;
	if (in == 'd' && players[turn].x + 1 >= COLS) return false;
	
	if (stage == 1) return true;
	
	// for cases where the end of the ship is touching the border
	if (players[turn].orientation) {
		// horizontal orientation, moving right
		if (in == 'd' && players[turn].x > COLS - size - 1) return false;
		if (in == 'a' && players[turn].map[players[turn].y][players[turn].x - 1] == SHIP) return false;
		else{
			// moving into another ship (going vertically)
			for (int i = 0; i < size; i++) {
				if (in == 'w') {
					if (players[turn].map[players[turn].y - 1][players[turn].x + i] == SHIP) return false;
				}
				else if (in == 's') {
					if (players[turn].map[players[turn].y + 1][players[turn].x + i] == SHIP) return false;
				}
			}
			// moving into anoher ship (horizontally)
			if (in == 'd' && players[turn].map[players[turn].y][players[turn].x + size] == SHIP) return false;
		} 
	} else {
		// vertical orientation, moving down
		if (in == 's' && players[turn].y > ROWS - size - 1) return false;
		if (in == 'w' && players[turn].map[players[turn].y - 1][players[turn].x] == SHIP) return false;
		else{
			// moving into another ship (going horizontally)
			for (int i = 0; i < size; i++) {
				if (in == 'a') {
					if (players[turn].map[players[turn].y + i][players[turn].x - 1] == SHIP) return false;
				}
				else if (in == 'd') {
					if (players[turn].map[players[turn].y + i][players[turn].x + 1] == SHIP) return false;
				}
			}
			if (in == 's' && players[turn].map[players[turn].y+ size][players[turn].x] == SHIP) return false;
		}
	}
	return true;
}

bool checkRotatable(int size, int turn) {
	// checks if ship is rotatable
	// DONE
	
	if (players[turn].orientation) {
		//horizontal orientation
		if (players[turn].y > ROWS - size) return false; //rotation would exceed border
		
		//brute force check if another ship is in the way
		for (int i = 1; i < size; i++){
			if (players[turn].map[players[turn].y + i][players[turn].x] == SHIP) return false;
		}
		
		
	} else {
		//vertical orientation
		if (players[turn].x > COLS - size) return false; //rotation would exceed border
		
		//brute force check if another ship is in the way
		for (int i = 1; i < size; i++){
			if (players[turn].map[players[turn].y][players[turn].x + i] == SHIP) return false;
		}
	}
	
	return true; // else return true
}

void restorePrev(int turn) {
	// restores prevMarker on previous position
	// always a miss because we're changing the actual map to an x
	
	FILE* screen[2] = {com0out, com1out};
	int opp = 1 - turn;
	screenCoords coords;
	
	fprintf(screen[0], "%s", CURSORINVISIBLE);
	fprintf(screen[1], "%s", CURSORINVISIBLE);
	
	// Print prevMarker on previous location
	// Current player's opp_map
	coords = calcScreenCoords(players[turn].x, players[turn].y, 1);
	fprintf(screen[turn], "\033[%d;%dH", coords.screenY, coords.screenX);
	fprintf(screen[turn], "%c", mapIcons(players[turn].prevMarker[1]));
	
	// Opp player's map
	coords = calcScreenCoords(players[turn].x, players[turn].y, 0);
	fprintf(screen[opp], "\033[%d;%dH", coords.screenY, coords.screenX);
	fprintf(screen[opp], "%c", mapIcons(players[opp].prevMarker[0]));
	
	fprintf(screen[0], "\033[%d;%dH", 24, 1);
	fprintf(screen[1], "\033[%d;%dH", 24, 1);
	
	fprintf(screen[0], "%s", CURSORVISIBLE);
	fprintf(screen[1], "%s", CURSORVISIBLE);
	
	fflush(screen[0]);
	fflush(screen[1]);
	
}


void drawMarker(int turn) {
	// draws new marker and set current as prev marker
	// we want to draw on your opp_map and the opponent's map
	// NOT DONE
	
	FILE* screen[2] = {com0out, com1out};
	int opp = 1 - turn;
	screenCoords coords;
	
	// Store prevMarker
	players[turn].prevMarker[1] = players[turn].opp_map[players[turn].y][players[turn].x];
	players[opp].prevMarker[0] = players[opp].map[players[turn].y][players[turn].x];
	
	// Print MARKER
	fprintf(screen[0], "%s", CURSORINVISIBLE);
	fprintf(screen[1], "%s", CURSORINVISIBLE);
	
	// Current player's opp_map
	coords = calcScreenCoords(players[turn].x, players[turn].y, 1);
	fprintf(screen[turn], "\033[%d;%dH", coords.screenY, coords.screenX);
	fprintf(screen[turn], "x");
	
	// Opp player's map
	coords = calcScreenCoords(players[turn].x, players[turn].y, 0);
	fprintf(screen[opp], "\033[%d;%dH", coords.screenY, coords.screenX);
	fprintf(screen[opp], "x");
	
	fprintf(screen[0], "\033[%d;%dH", 24, 1);
	fprintf(screen[1], "\033[%d;%dH", 24, 1);
	
	fprintf(screen[0], "%s", CURSORVISIBLE);
	fprintf(screen[1], "%s", CURSORVISIBLE);
	
	fflush(screen[0]);
	fflush(screen[1]);
	
}


void clearShip(int size, int turn) {
	// clears the map of the current ship
	// DONE
	FILE* screen;
	
	if (turn == 0) screen = com0out; 
	else screen = com1out; 
	
	// disable cursor while drawing
	fprintf(com0out, "%s", CURSORINVISIBLE);
	screenCoords coords;
	
	if (players[turn].orientation) {
		// horizontal orientation
		for (int i = 0; i < size; i++) {
			//update player map
			players[turn].map[players[turn].y][players[turn].x + i] = EMPTY;
			
			// move cursor to screencoords
			coords = calcScreenCoords(players[turn].x + i, players[turn].y, 0);
			fprintf(screen, "\033[%d;%dH", coords.screenY, coords.screenX);
			fprintf(screen, " ");
		}
	} else {
		// vertical orientation
		for (int i = 0; i < size; i++) {
			players[turn].map[players[turn].y + i][players[turn].x] = EMPTY;
			
			// move cursor to screencoords
			coords = calcScreenCoords(players[turn].x, players[turn].y + i, 0);
			fprintf(screen, "\033[%d;%dH", coords.screenY, coords.screenX);
			fprintf(screen, " ");
		}
	}
	
	// enable cursor
	fprintf(screen, "\033[%d;%dH", 24, 1);
	fprintf(screen, "%s",CURSORVISIBLE);
	
	fflush(screen);
}

void moveShip(int size, int turn) {
	// updates the player's map with new position of curren ship
	// DONE
	
	FILE* screen;
	
	if (turn == 0) screen = com0out; 
	else screen = com1out; 
	
	// disable cursor while drawing
	fprintf(screen, "%s", CURSORINVISIBLE);
	screenCoords coords;
	
	if (players[turn].orientation) {
		// horizontal orientation
		for (int i = 0; i < size; i++) {
			//update player map
			players[turn].map[players[turn].y][players[turn].x + i] = SHIP;
			
			// move cursor to screencoords
			coords = calcScreenCoords(players[turn].x + i, players[turn].y, 0);
			fprintf(screen, "\033[%d;%dH", coords.screenY, coords.screenX);
			fprintf(screen, "S");
		}
	} else {
		// vertical orientation
		for (int i = 0; i < size; i++) {
			//update player map
			players[turn].map[players[turn].y + i][players[turn].x] = SHIP;
			
			// move cursor to screencoords
			coords = calcScreenCoords(players[turn].x, players[turn].y + i, 0);
			fprintf(screen, "\033[%d;%dH", coords.screenY, coords.screenX);
			fprintf(screen, "S");
		}
	}
	
	// enable cursor
	fprintf(screen, "\033[%d;%dH", 24, 1);
	fprintf(screen, "%s", CURSORVISIBLE);
	
	fflush(screen);
}

void setupInputResponse(int turn, char in) {
	//DONE
	int size = shipSizes[players[turn].enterPressed];
	switch(in){
		case 'r':
			if (checkRotatable(size, turn)) {
				// clear previous space
				clearShip(size, turn);
				
				players[turn].orientation = !players[turn].orientation;
				
				// put in new space
				moveShip(size, turn);
			}
			break;
		case 'w':
			if (checkMovable(size, turn ,in)) {
				// clear previous space
				clearShip(size, turn);
				
				players[turn].y--;
				
				// put in new space
				moveShip(size, turn);
			}
			break;
		case 'a':
			if (checkMovable(size, turn, in)) {
				// clear previous space
				clearShip(size, turn);
				
				players[turn].x--;
				
				// put in new space
				moveShip(size, turn);
			}
			break;
		case 's':
			if (checkMovable(size, turn, in)) {
				// clear previous space
				clearShip(size, turn);
				
				players[turn].y++;
				
				// put in new space
				moveShip(size, turn);
			}
			break;
		case 'd':
			if (checkMovable(size, turn, in)) {
				// clear previous space
				clearShip(size, turn);
				
				players[turn].x++;
				
				// put in new space
				moveShip(size, turn);
			}
			break;
		case 'f':
			players[turn].enterPressed++;
			players[turn].fired = true;
			break;
	}
	players[turn].input = 0; //reset input?
}

void battleInputResponse(int turn, char in) {
	//DONE?
	switch(in){
		case 'w':
			if (checkMovable(1, turn ,in)) {
				// need to update this
				// restore previous space
				restorePrev(turn);
				
				players[turn].y--;
				
				// put in new space
				drawMarker(turn);
			}
			break;
		case 'a':
			if (checkMovable(1, turn, in)) {
				// restore previous space
				restorePrev(turn);
				
				players[turn].x--;
				
				// put in new space
				drawMarker(turn);
			}
			break;
		case 's':
			if (checkMovable(1, turn, in)) {
				// restore previous space
				restorePrev(turn);
				
				players[turn].y++;
				
				// put in new space
				drawMarker(turn);
			}
			break;
		case 'd':
			if (checkMovable(1, turn, in)) {
				// restore previous space
				restorePrev(turn);
				
				players[turn].x++;
				
				// put in new space
				drawMarker(turn);
			}
			break;
		case 'f':
			// check player's opp_map with other player's map
			int opposite_turn = 1 - turn;
			FILE* screen[2] = {com0out, com1out};
			 
			screenCoords coords;
			
			if (players[opposite_turn].map[players[turn].y][players[turn].x] == SHIP) {
				//hit! UPDATE MAP
				players[turn].opp_map[players[turn].y][players[turn].x] = HIT;
				players[opposite_turn].map[players[turn].y][players[turn].x] = HIT;
				players[turn].hits++;
				
				// actually print that out on the map please
				coords = calcScreenCoords(players[turn].x, players[turn].y, 1);
				fprintf(screen[turn], "\033[%d;%dH", coords.screenY, coords.screenX);
				fprintf(screen[turn], "O"); //your map
				
				coords = calcScreenCoords(players[turn].x, players[turn].y, 0);
				fprintf(screen[opposite_turn], "\033[%d;%dH", coords.screenY, coords.screenX);
				fprintf(screen[opposite_turn], "O"); //their map
				
				fprintf(screen[turn], "\033[%d;%dH", 24, 1);
				fprintf(screen[turn], "Hit!!!!");
				
				fflush(com0out);
				fflush(com1out);
			} else if (players[opposite_turn].map[players[turn].y][players[turn].x] != MISS) {
				//miss! UPDATE MAP
				players[turn].opp_map[players[turn].y][players[turn].x] = MISS;
				players[opposite_turn].map[players[turn].y][players[turn].x] = MISS;
				
				coords = calcScreenCoords(players[turn].x, players[turn].y, 1);
				fprintf(screen[turn], "\033[%d;%dH", coords.screenY, coords.screenX);
				fprintf(screen[turn], "X"); //your map
				
				coords = calcScreenCoords(players[turn].x, players[turn].y, 0);
				fprintf(screen[opposite_turn], "\033[%d;%dH", coords.screenY, coords.screenX);
				fprintf(screen[opposite_turn], "X"); //their map
				
				fprintf(screen[turn], "\033[%d;%dH", 24, 1);
				fprintf(screen[turn], "Miss!!!!");
				
				fflush(com0out);
				fflush(com1out);
			} else {
				fprintf(screen[turn], "\033[%d;%dH", 24, 1);
				fprintf(screen[turn], "Miss!!!!");
				
				fflush(com0out);
				fflush(com1out);
			}
			
			break;
	}
	players[turn].input = 0; //reset input?
}

void drawSetupScreen(int turn) {

	// pick which screen to output to
	if (turn == 0) {
		// clear the screen
		// fprintf(com0out, DELETESCREEN);
	
		// move cursor to (1, 1)
		fprintf(com0out, "\033[1;1H");
	
		// disable cursor while drawing
		fprintf(com0out, "%s", CURSORINVISIBLE);
		
		fprintf(com0out, "Player 1 Map\n");
		
		
		fprintf(com0out, "-----------------------------------------\n");
		for (int i = 0; i < COLS; i++) {
			for (int j = 0; j < ROWS; j++) {
				fprintf(com0out, "| %c ", mapIcons(players[turn].map[i][j]));
			}
			fprintf(com0out, "|\n-----------------------------------------\n");
		}
	
		//print controls
		fprintf(com0out, "R = Rotate, WASD = Up Left Down Right, F = Place Ship\n");
		
		// enable cursor
		fprintf(com0out, "%s", CURSORVISIBLE);
		
		fflush(com0out);
		
	} else {
		// clear the screen
		// fprintf(com1out, DELETESCREEN);
	
		// move cursor to (1, 1)
		fprintf(com1out, "\033[1;1H");
	
		// disable cursor while drawing
		fprintf(com1out, "%s", CURSORINVISIBLE);
		
		fprintf(com1out, "Player 2 Map\n");
		
		fprintf(com1out, "-----------------------------------------\n");
		for (int i = 0; i < COLS; i++) {
			for (int j = 0; j < ROWS; j++) {
				fprintf(com1out, "| %c ", mapIcons(players[turn].map[i][j]));
			}
			fprintf(com1out, "|\n-----------------------------------------\n");
		}
	
		//print controls
		fprintf(com1out, "R = Rotate, WASD = Up Left Down Right, F = Place Ship\n");
		
		fprintf(com1out, "%s", CURSORVISIBLE);
		
		fflush(com1out);
	}	
}

void drawBattleScreen(int turn) {
	//Draws BOTH the maps
	//NOT DONE
	if (turn == 0) {
		// clear screen 
		fprintf(com0out, DELETESCREEN);
		
		fprintf(com0out, "\033[1;1H");
		
		fprintf(com0out, "Your map						     Opposing player's map \n");
	
		fprintf(com0out, "-----------------------------------------                    -----------------------------------------\n"); //20 spaces
		for (int i = 0; i < COLS; i++) {
			for (int j = 0; j < ROWS; j++) {
				fprintf(com0out, "| %c ", mapIcons(players[turn].map[i][j]));
			}
			fprintf(com0out, "|                    ");
			
			for (int k = 0; k < ROWS; k++) {
				fprintf(com0out, "| %c ", mapIcons(players[turn].opp_map[i][k]));
			}
			fprintf(com0out, "|\n-----------------------------------------                    -----------------------------------------\n");
		}
	
		//print controls
		fprintf(com0out, "WASD = Up Left Down Right, F = FIRE\n");
		fflush(com0out);
	
	} else {
		// clear screen 
		fprintf(com1out, DELETESCREEN);
		fprintf(com1out, HOME);
		
		fprintf(com1out, "Your map						     Opposing player's map \n");
	
		fprintf(com1out, "-----------------------------------------                    -----------------------------------------\n"); //20 spaces
		for (int i = 0; i < COLS; i++) {
			for (int j = 0; j < ROWS; j++) {
				fprintf(com1out, "| %c ", mapIcons(players[turn].map[i][j]));
			}
			fprintf(com1out, "|                    ");
			for (int k = 0; k < ROWS; k++) {
				fprintf(com1out, "| %c ", mapIcons(players[turn].opp_map[i][k]));
			}
			fprintf(com1out, "|\n-----------------------------------------                    -----------------------------------------\n");
		}
	
		//print controls
		fprintf(com1out, "WASD = Up Left Down Right, F = FIRE\n");
		fflush(com1out);
	}
	
	
}


void spawnShip(int turn) {
	//find appropriate position for new ship, and puts ship there
	//DONE
	int curr_size = shipSizes[players[turn].enterPressed];
	int count = 0;
	
	players[turn].orientation = true; //set orientation to horizontal
	players[turn].fired = false;
	
	//brute for search left -> right
	for (int empy = 0; empy < ROWS; empy++) {
		for (int empx = 0; empx < COLS; empx++) {
			if (players[turn].map[empy][empx] == EMPTY) count++;
			else count = 0;
			
			if (count == curr_size) { 
				players[turn].x = empx - curr_size + 1;
				players[turn].y = empy;
				
				for(int i = 0; i < curr_size; i++) {
					players[turn].map[empy][players[turn].x + i] = SHIP;
				}
				return;
			}
		}
		count = 0; //reset count on new line
	}
	
	moveShip(curr_size, turn);
	
	
}

void battleSetup() {

	P(3); //count = 0
	P(3); //count = -1, sent to semaphore
	
	while (1) {
		if (player1done == 1 && player2done == 1) {
			fprintf(com0out, "Starting battle setup");
			stage = 1; // set stage to battle stage
			
			//set both players' x & y
			players[0].x = 0;
			players[0].y = 0;
			players[1].x = 0;
			players[1].y = 0;
			
			//reset fired
			players[0].fired = false;
			players[1].fired = false;
			
			//draw both maps
			drawBattleScreen(0);
			drawBattleScreen(1);
			
			// retrieves other tasks from the shadow realm
			V(0);
			V(1);
			
			player1done = 0;
			player2done = 0;
			
			// sends self to shadow realm
			P(3);
		} else {
			P(3); //sent back to semaphore
		}
	}
}


void player1() {
	P(0); //to setup sending self to the shadow realm
	while(1) {
		if (stage == 0 && player1done == 0) {
			//setup stage, no turn
			P(2);
			drawSetupScreen(0);
			V(2);
			
			while(players[0].enterPressed <= 4) {
				//while not done setting up
				P(2);				//prevents interrupt from other player
				if (players[0].fired) spawnShip(0);			//spawn ship on empty space
				V(2);
				
				if (getValidInput(0)){
					P(2);			//prevents interrupt
					setupInputResponse(0, players[0].input);	//input response
					V(2);
				}
				
			}
			fprintf(com0out, "\033[%d;%dH", 24, 1);
			fprintf(com0out, "Setup Done! Waiting for Player 2...........");
			player1done = 1;
			fprintf(com0out, "Flag set! player1done = %d", player1done);
			fflush(com0out);
		} else if (stage == 0 && player1done == 1) {
			V(3);
			P(0); //send self to the shadow realm
		}
		if (stage == 1){
			//battle stage, turn based
			P(2); //sends other to shadow realm if disturbed
			
			players[0].x = 0;
			players[0].y = 0;
			
			while(!players[0].fired) { //while not fired
				if (getValidInput(0)) {
					battleInputResponse(0, players[0].input);
					//when it's not your turn, you should be able to see their actions
					if (players[0].input == 'f') break;
				}
			}
			
			//1 turn
			players[0].fired = false; //reset fired condition
			
			//check win condition
			if (players[0].hits >= 17) {
				//player 1 wins!!
				while (1) {
					fprintf(com0out, "\033[%d;%dH", 24, 1);
					fprintf(com0out, "\r------------------------------------------PLAYER 1 WINS!!!!------------------------------------------");
					fprintf(com0out, "\r------------------------------------------PLAYER 1 WINS!!!!------------------------------------------");
					
					fprintf(com1out, "\033[%d;%dH", 24, 1);
					fprintf(com1out, "\r------------------------------------------PLAYER 1 WINS!!!!------------------------------------------");
					fprintf(com1out, "\r------------------------------------------PLAYER 1 WINS!!!!------------------------------------------");
				}
			}
			
			V(2);
			 
		}
	
	}
}

void player2() {
	P(1); //to setup sending self to the shadow realm
	while(1) {
		if (stage == 0 && player2done == 0) {
			//setup stage, no turn
			P(2);
			drawSetupScreen(1);
			V(2);
			
			while(players[1].enterPressed <= 4) {
				//while not done setting up
				P(2);				//prevents interrupt from other player
				if (players[1].fired) spawnShip(1);			//spawn ship on empty space
				V(2);
				
				if (getValidInput(1)){
					P(2);			//prevents interrupt
					setupInputResponse(1, players[1].input);	//input response
					V(2);
				}
				
			}
			fprintf(com1out, "\033[%d;%dH", 24, 1);
			fprintf(com1out, "Setup Done! Waiting for Player 1...........");
			player2done = 1;
			fprintf(com1out, "Flag set! player2done = %d", player2done);
			fflush(com1out);
		} else if (stage == 0 && player2done == 1) {
			V(3);
			P(1); //send self to the shadow realm
		}
		
		if (stage == 1){
			//battle stage, turn based
			P(2); //sends other to shadow realm if disturbed
			
			players[1].x = 0;
			players[1].y = 0;
			
			while(!players[1].fired) { //while not fired
				if (getValidInput(1)) {
					battleInputResponse(1, players[1].input);
				}
				if (players[1].input == 'f') break;
			}
			
			//1 turn
			players[1].fired = false; //reset fired condition
			
			//check win condition
			if (players[1].hits >= 17) {
				//player 2 wins!!
				while (1) {
					fprintf(com0out, "\033[%d;%dH", 24, 1);
					fprintf(com0out, "\r------------------------------------------PLAYER 2 WINS!!!!------------------------------------------");
					fprintf(com0out, "\r------------------------------------------PLAYER 2 WINS!!!!------------------------------------------");
					
					fprintf(com1out, "\033[%d;%dH", 24, 1);
					fprintf(com1out, "\r------------------------------------------PLAYER 2 WINS!!!!------------------------------------------");
					fprintf(com1out, "\r------------------------------------------PLAYER 2 WINS!!!!------------------------------------------");
				}
			}
					
			V(2);
			 
		}
	
	}
}



void init_ports() {
	int success = 4;
	while(success > 0){
	
		success = 4;
	
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

void initPlayers() {
	players[0].orientation = true; //true horizontal, false vertical
	players[0].fired = false;
	players[0].enterPressed = 0;
	
	players[1].orientation = true; //true horizontal, false vertical
	players[1].fired = false;
	players[1].enterPressed = 0;
	
	fprintf(com0out, "Player 1 Ready!");
	fprintf(com1out, "Player 2 Ready!");
	
	
}

int main()
{
	// initialization
	init_kernel();
	init_ports();
	
	fprintf(com0out, DELETESCREEN);
	fprintf(com1out, DELETESCREEN);
	
	printIntro();
	initPlayers();
	
	fprintf(com0out, DELETESCREEN);
	fprintf(com1out, DELETESCREEN);
	
	//setup stage, players traverse their own map
    	set_task(player1);
    	set_task(player2);
	
	//batte stage, player traverse their opponent's map
    	set_task(battleSetup);

    	begin_sch();
    	
    	return 0;
	
}
