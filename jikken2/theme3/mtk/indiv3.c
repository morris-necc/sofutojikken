#include <stdio.h>
#include <stdlib.h>
#include "mtk_c.h"
#include <stdbool.h>

#define BOARD_SIZE 3

typedef struct {
    char mark;      // 'X' or 'O'
    bool is_turn;   // true if it's the player's turn
    FILE* input;    // input stream for the player
    FILE* output;   // output stream for the player
} Player;

Player player_X = {'X', false, NULL, NULL};
Player player_O = {'O', true, NULL, NULL};

void init_players() {
    player_X.input = fdopen(4, "r");
    player_X.output = fdopen(4, "w");
    player_O.input = fdopen(3, "r");
    player_O.output = fdopen(3, "w");

    if (!player_X.input || !player_X.output || !player_O.input || !player_O.output) {
        fprintf(stderr, "Failed to initialize player ports.\n");
        exit(EXIT_FAILURE);
    }

    fprintf(player_X.output, "Player X ready!\n");
    fprintf(player_O.output, "Player O ready!\n");
}

void player_turn(Player* player) {
    while (1) {
        p(0); // Semaphore lock

        if (!player->is_turn) {
            v(0);
            continue;
        }

        int cell = -1;
        bool valid = false;

        while (!valid) {
            fprintf(player->output, "Player '%c', choose a cell (0-8): ", player->mark);
            fscanf(player->input, "%d", &cell);

            if (is_valid_cell(cell)) {
                valid = true;
                update_board(cell, player->mark);
                remove_cell(cell);
                if (check_win(board, cell, player->mark)) {
                    fprintf(player->output, "Player '%c' wins!\n", player->mark);
                    fprintf(player->input == player_X.input ? player_O.output : player_X.output,
                            "Player '%c' wins!\n", player->mark);
                    exit(EXIT_SUCCESS);
                }
            } else {
                fprintf(player->output, "Invalid cell. Try again.\n");
            }
        }

        display_board();

        // Switch turn
        player->is_turn = false;
        (player == &player_X ? &player_O : &player_X)->is_turn = true;

        v(0); // Semaphore unlock
    }
}


void main() {
    init_kernel();
    init_players();
    init_board();

    set_task((void*)player_turn, &player_O);
    set_task((void*)player_turn, &player_X);
    set_task(hurry_msg);

    begin_sch();
}
