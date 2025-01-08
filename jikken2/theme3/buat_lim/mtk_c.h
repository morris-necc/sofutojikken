#ifndef _mtk_c_h_
#define _mtk_c_h_

/////////////////////
//マクロの定義
/////////////////////
#define NULLTASKID      0	    // キューの終端
#define NUMTASK	        5	    // 最大タスク数
#define STKSIZE		    1024    // スタック差のサイズ
#define NUMSEMAPHORE	3	    // セマフォの数

//TCBのstatus用マクロ
#define	UNDEFINED	0	// 未定義
#define	OCCUPIED	1	// 使用中
#define FINISHED	2	// 実行終了

/////////////////////
//構造体の定義
/////////////////////
typedef int TASK_ID_TYPE;

typedef struct{
	int		        count;
	TASK_ID_TYPE	task_list;
} SEMAPHORE_TYPE;

typedef struct{
	void		    (*task_addr)();
	void		    *stack_ptr;
	int		        priority;
	int		        status;
	TASK_ID_TYPE	next;
} TCB_TYPE;

typedef struct{
	char	        ustack[STKSIZE];
	char	        sstack[STKSIZE];
} STACK_TYPE;

/////////////////////
//大域変数, 配列の定義
/////////////////////
extern SEMAPHORE_TYPE 	semaphore[NUMSEMAPHORE];	// セマフォの配列
extern TCB_TYPE 	    task_tab[NUMTASK + 1];		// タスクコントロールブロックの配列
extern STACK_TYPE	    stacks[NUMTASK];		    // タスクスタックの配列

extern TASK_ID_TYPE	curr_task;	                // 現在実行中のタスクID
extern TASK_ID_TYPE	new_task;	                // 現在登録作業中のタスクID
extern TASK_ID_TYPE	next_task;	                // 次に実行するタスクID
extern TASK_ID_TYPE	ready;		                // 実行待ちタスクのキュー

//////////////////////////////
//関数のプロトタイプの定義
//////////////////////////////

/////////////////////
//マルチタスク関連
/////////////////////
void init_kernel();                                 // カーネルの初期化
void set_task(void (*usertask_ptr)());	            // ユーザタスクの初期化と登録
void* init_stack(TASK_ID_TYPE id);	                // ユーザタスク用のスタックの初期化
void begin_sch();	                                // マルチタスク処理の開始
void addq(TASK_ID_TYPE* que_ptr, TASK_ID_TYPE id);	// タスクのキューへの最後尾へのTCBの追加
TASK_ID_TYPE removeq(TASK_ID_TYPE* que_ptr);	    // タスクのキューへの先頭からのTCBの除去

void sched();                                       // タスクのスケジュール関数

extern int first_task();	                        // ユーザタスク起動
extern int swtch();                                 // タスクスイッチ

/////////////////////
//タイマ関連
/////////////////////

extern int hard_clock();	// タイマ割り込み
extern int init_timer();	// クロック割り込み
extern int set_timer();	
extern int reset_timer();	

/////////////////////
//セマフォ関連
/////////////////////
void p_body();	            // Pシステムコールの本体
void v_body();	            // Vシステムコールの本体

void sleep(int ch);	        // タスクを休眠状態にしてタスクスイッチをする
void wakeup(int ch);	    // 休眠状態のタスクを実行可能状態にする

extern int P(int p);		// Pシステムコールの入り口
extern int V(int v);		// Vシステムコールの入り口
extern int pv_handler();	// trap#1割り込み処理

/////////////////////
//stdio関連
/////////////////////
extern void outbyte(unsigned char c);
extern char inbyte();

#endif
