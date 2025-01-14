#include <stdio.h>
#include "mtk_c.h"

SEMAPHORE_TYPE 	semaphore[NUMSEMAPHORE];	// セマフォの配列
TCB_TYPE 	    task_tab[NUMTASK + 1];		// タスクコントロールブロックの配列
STACK_TYPE	    stacks[NUMTASK];		    // タスクスタックの配列

TASK_ID_TYPE	curr_task;	                // 現在実行中のタスクID
TASK_ID_TYPE	new_task;	                // 現在登録作業中のタスクID
TASK_ID_TYPE	next_task;	                // 次に実行するタスクID
TASK_ID_TYPE	ready;		                // 実行待ちタスクのキュー

/************************************************************************************
**カーネルの初期化 init kernel()
**引数なし．以下のような処理を行う．
**1. TCB 配列の初期化：すべて空タスクとする
**2. ready キューの初期化：空（タスク ID=0）とする
**3. P・V システムコールの割り込み処理ルーチン (pv handler) を TRAP #1 の割り込みベクタに登録する
**4. セマフォの値を初期化する
************************************************************************************/
void init_kernel(){
	int i;
	
	for(i = 0; i < NUMTASK+1; i++){ 	/* TCB配列の初期化 */	
		task_tab[i].task_addr = NULL;
		task_tab[i].stack_ptr = NULL;
		task_tab[i].priority = 0;
		task_tab[i].status = UNDEFINED;
		task_tab[i].next = NULLTASKID;							
	}

	ready = NULLTASKID;	/* readyキューの初期化 */					

	*(int*) 0x0084 = (int)pv_handler; /* pv_handlerをTRAP#1の割り込みベクタに登録 */

    for(i = 0; i < NUMSEMAPHORE; i++){  /* セマフォの値を初期化 */
        semaphore[i].count = 1;
        semaphore[i].task_list = NULLTASKID;
    }
}

/************************************************************************************
**ユーザタスクの初期化と登録 set task()
**引数にはユーザタスク関数へのポインタ（タスク関数の先頭番地）を取る．以下のような処理を行う．
**1. タスク ID の決定：
**task tab[] の中に空きスロットを見つけ (0 番は除く)，その ID を new task に代入する．
**2. TCB の更新：
**上で見つけた TCB に，task addr，status を登録する．
**3. スタックの初期化：
**関数 init stack() を起動する．関数 init stack() の戻り値を TCB の stack ptr に登録
**する．
**4. キューへの登録：
**ready キューに new task を登録する．
**Cでは，配列の名前はその配列のアドレスを意味する．TCB へ登録するスタックの位置情報は
**これらの機能を用いて表すことができる．
************************************************************************************/
void set_task(void (*usertask_ptr)()){
    TASK_ID_TYPE i;
    
    for(i = 1; i < NUMTASK+1; i++){
        if((task_tab[i].status == UNDEFINED)||(task_tab[i].status == FINISHED)){
            new_task = i; /* タスクIDの決定 */
            task_tab[i].task_addr = usertask_ptr; /* TCB の更新 */
            task_tab[i].status = OCCUPIED;
            task_tab[i].stack_ptr = init_stack(new_task); /* スタックの初期化 */
            addq(&ready, new_task); /* キューへの登録 */
            break;
        }
    }
}

/***************************************************************************************
**ユーザタスク用のスタックの初期化 init stack()
**タスク ID を引数としてとる．戻り値に初期化が完了した時点でのユーザタスク用 SSP が指す
**アドレス (void * 型) を返す．引数を id とすると，以下の処理を行なう．
**1. stacks[id - 1] の sstack を図 2.8 のように設定する．図中の「initial(初期)PC」の部分に
**はタスクの実行開始アドレス task tab[id].task addr を設定する．「initial SR」の部分に
**は 0x0000 を，15×4 バイト分の領域を飛ばして，「initial USP」の部分はユーザスタックトッ
**プ stacks[id - 1].ustack[STKSIZE] を設定する．
**2. 図 2.8 の (*) のアドレスを戻り値として返す．
**なお，int 型へのポインタ ssp を宣言しておくと，ssp の値が現在のスーパバイザスタックの
**トップを指しているならば，4 バイトの値をプッシュすることは，*(--ssp) = 値で実現できる．
**これを利用すると，上記の操作は簡単である．また，2 バイトの値をプッシュするときは，unsigned
**short int 型へのポインタを宣言しておき，これを利用すると良い．
*****************************************************************************************/
void *init_stack(TASK_ID_TYPE id){
    int* int_ssp = (int*)&stacks[id-1].sstack[STKSIZE];
    *(--int_ssp) = task_tab[id].task_addr; /* initial PCの設定 */
    unsigned short int* short_ssp = (unsigned short int*)int_ssp;
    *(--short_ssp) = 0x0000; /* initial SRの設定 */
    int_ssp = (int*)short_ssp;
    int_ssp -= 15; /* 15*4バイト分の領域を飛ばす */
    /*修正*/
    *(--int_ssp) = &stacks[id-1].ustack[STKSIZE]; /* initial USPの設定 */

    return (void*)int_ssp;
}

/*********
***1. 最初のタスクの決定：
***キュー ready から removeq() によってタスクを１つ取り出し，curr task に代入する
***2. タイマの設定:
***関数 init timer() を呼び出し，タスクスイッチを行うためのタイマを設定．
***3. 最初のタスクの起動：
***関数 first task() を起動して最初のタスクに制御を移す．これは m68k-elf-gcc コンパイラ
***によってアセンブリ言語サブルーチン first task の呼び出しに変換される．
*********/
void begin_sch(){
    curr_task=removeq(&ready);
    init_timer();
    first_task();
    printf("hello world\n");
}

// タスクのキューの最後尾へのTCBの追加
void addq(TASK_ID_TYPE* que_ptr, TASK_ID_TYPE id){
	if(*que_ptr == NULLTASKID){					// キューの先頭のタスクが空なら
		*que_ptr = id; 							// 先頭にタスクを登録
	}
	else{
		TCB_TYPE* task_ptr = &task_tab[*que_ptr];	// 先頭のタスクのポインタ設定
		while(1){
			if((*task_ptr).next == NULLTASKID){		// その次のタスクが空だったら
				(*task_ptr).next = id;				// タスクを登録
				break;
			}
			else{
				task_ptr = &task_tab[(*task_ptr).next];		//次のタスクにポインタを移動
			}
		}
	}
}

// タスクのキューの先頭からのTCBの除去
TASK_ID_TYPE removeq(TASK_ID_TYPE* que_ptr){
	TASK_ID_TYPE r_id = *que_ptr; 					// 返り値(id)
	if(r_id != NULLTASKID){							// キューの先頭が空でなければ
		TCB_TYPE* task_ptr = &task_tab[r_id]; 		// 先頭のタスクのポインタ設定
		*que_ptr = (*task_ptr).next; 				// 先頭から2番目のタスクを先頭にする
		(*task_ptr).next = NULLTASKID;				// 先頭のタスクのnextはNULLTASKIDにして、タスクを取り出す
	}
	return r_id;									// キューの先頭のタスクのidを返す
}

// タスクのスケジュール関数
void sched(){
	next_task = removeq(&ready);					// readyキューの先頭のタスクIDを取り出し、next_taskにセット
	if(next_task == NULLTASKID){
		while(1); 									// 次のタスクができるまで無限ループ
	}		
}

//齊藤作成
//引数としてセマフォID（割り込み時のレジスタD1が保持）をとる
//1.セマフォの値を減らす
//2.セマフォが獲得（セマフォの値が０以上）ならばなにもしない（ユーザータスクをそのまま実行）
//セマフォが獲得できない（セマフォの値が負）ならばsleep(s_id)を実行して休眠状態へ


void p_body(TASK_ID_TYPE s_id){
	semaphore[s_id].count --;
	if(semaphore[s_id].count < 0){
		sleep(s_id);
		}
}

void sleep(int ch){
	addq(&semaphore[ch].task_list, curr_task);		//ch＝セマフォIDの待ち行列に現タスクをつなぐ
	sched();						//次に実行するタスクのIDをnext_taskにセット
	swtch();						//タスクを切り替える
}

//後藤作成
//1. セマフォの値を増やす
//2. セマフォが空けば，wakeup(セマフォの ID) を実行して，そのセマフォを待っているタスク
//   を一つ，実行可能状態にする．

void v_body(TASK_ID_TYPE s_id){
	semaphore[s_id].count++; //セマフォの値を増やす
	if(semaphore[s_id].count<=0){
		wakeup(s_id);         //セマフォを待っているタスクを実行可能状態に
	}
}

void wakeup(int ch){
	TASK_ID_TYPE wakeup_id;
	wakeup_id=removeq(&semaphore[ch].task_list); //セマフォから待ちタスクを除去
	addq(&ready,wakeup_id); //実行可能状態行列（ready）へつなぐ
}