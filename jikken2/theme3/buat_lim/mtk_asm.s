.include "equdefs.inc"
.section .text

.global swtch
.global pv_handler
.global init_timer
.global first_task
.global P
.global V

**齊藤　作成**
********************************************************************************************
**【機能】
**Pシステムコールの入口…Cから呼ばれる関数（サブルーチン）として作成．
**Cプログラムから引数（セマフォID）付きで呼び出される
**中では適切な値をレジスタに置き，TRAP #1 命令を実行する．
********************************************************************************************
**【レジスタ用途】
**d0:p_body()のIDとして０を代入
**d1:セマフォIDを代入
*********************************************************************************************

.text
.even
P:	
	movem.l %d1-%d2/%a1,-(%sp)	|レジスタ退避	
	move.l #0,%d0				|d0 = 0
	movea.l	%sp, %a1			|スタックポインタをa1にコピー
	move.l	#16,   %d2			|a1,d1,d2,PC各4ずつ
	adda.l	%d2,   %a1			|スタックポインタにプラス16
	move.l	(%a1), %d1			|↑その位置の中身(セマフォID)をd1にコピー
	trap #1						|pv_handlerを呼び出す
	movem.l (%sp)+,%d1-%d2/%a1	|レジスタ復帰
	rts
	
**齊藤　作成**
********************************************************************************************
**【機能】
**Vシステムコールの入口…Cから呼ばれる関数（サブルーチン）として作成．
**Cプログラムから引数（セマフォID）付きで呼び出される
**中では適切な値をレジスタに置き，TRAP #1 命令を実行する．
********************************************************************************************
**【レジスタ用途】
**d0:v_body()のIDとして1を代入
**d1:セマフォIDを代入
*********************************************************************************************

.text
.even
V:	
	movem.l %d1-%d2/%a1,-(%sp)	| レジスタ退避	
	move.l #1,%d0				| d0 = 1
	movea.l	%sp, %a1			| スタックポインタをa1にコピー
	move.l	#16,   %d2			| a1,d1,d2,PC各4ずつ
	adda.l	%d2,   %a1			| スタックポインタにプラス16
	move.l	(%a1), %d1			| ↑その位置の中身(セマフォID)をd1にコピー
	trap #1						| pv_handlerを呼び出す
	movem.l (%sp)+,%d1-%d2/%a1	| レジスタ復帰
	rts
	
**齊藤作成**
*****************************************
**☆P.sとV.s中のtrap#1命令で呼び出される☆
*****************************************
**【機能】
**タスクの切り換え…割り込み処理ルーチンとして作成．
**関数として呼び出されることはあってはならないが，
**Cプログラムから関数として見えるようにしておくと，Cプログラム内でこの関数の名前をこのルーチンの先頭番地として
**参照することができるので，例外ベクタに登録するのが容易である．
***********************************************************************************************************
**【レジスタ用途】
**d0:0ならp_body()、1ならv_body()
**d1:セマフォID
**両関数とも引数にセマフォIDを取るので、これをスタックに積んだ後サブルーチンコールをする必要がある
*********************************************************************************************
.extern p_body
.extern v_body

.text
.even
pv_handler:
	move.w	%SR, -(%sp)	|現走行レベルの退避	
	movem.l %d0/%a0, -(%sp)	|レジスタ退避
	move.w	#0x2700, %SR	|割り込み禁止 走行レベル７
	/*d0の値チェック*/
	cmp.l #0, %d0
    beq SYSCALL_p
	cmp.l #1, %d0
	beq SYSCALL_v
SYSCALL_p:
	move.l #p_body, %d0
	bra JUMP_pv
SYSCALL_v:
	move.l #v_body, %d0
	bra JUMP_pv
JUMP_pv:	
	movea.l %d0, %a0	
	move.l %d1,-(%sp)	|セマフォIDをスタックに積む
	jsr (%a0)			|p_body or v_body にジャンプ

pv_FINISH:
	addq.l #4,%sp		|引数として使われて削除されているのでスタックポインタをもとに戻す
	movem.l (%sp)+,%d0/%a0 	|レジスタ復帰
	move.w	(%sp)+, %SR	|旧走行レベルの回復
	rte
	
.extern task_tab
.extern curr_task
.extern next_task


swtch:
*********
***1. SR をスタックに積んで，RTE で復帰できるようにする．
***2. 実行中のタスクのレジスタの退避：
***D0〜D7，A0〜A6，USP をタスクのスーパバイザスタックに積む．
***3. SSP の保存:
***このタスクの TCB の位置を求め， SSP を正しい位置に記録する．
***4. curr task を変更:
***curr task に next task を代入する．swtch の呼び出し前にスケジューラ sched を起動し
***ているため，next task には次に実行するタスク ID がセットされている．
***5. 次のタスクの SSP の読み出し：
***新たな curr task の値を元に TCB の位置を割り出して，その中に記録されている SSP の
***値を回復する．これにより，スーパバイザスタックが次のタスクのものへ切り換わる．
***6. 次のタスクのレジスタの読み出し：
***切り換わったスーパバイザスタックから USP，D0〜D7，A0〜A6 の値を回復する．
***7. タスク切り替えをおこす:
***RTE を実行する．
*********
	***1. SR をスタックに積んで，RTE で復帰できるようにする．
	move.w %sr, -(%sp)      		/*SRを退避*/

	***2. 実行中のタスクのレジスタの退避：
	movem.l %d0-%d7/%a0-%a6, -(%sp)	/*実行中のタスクのレジスタを退避*/
	move.l %USP, %a6        		/*USPをa6に転送*/
	move.l %a6, -(%sp)      		/*USPを退避*/

	***3. SSP の保存:
	move.l #0, %d0  
	move.l curr_task, %d0	/*カレントタスクのIDを転送*/
	lea.l task_tab, %a0		/*タスクコントロールブロックの先頭アドレスを転送*/
	mulu #20, %d0			/*カレントIDを20倍*/
	adda.l %d0, %a0			/*カレントタスクのTCBのアドレスを求める*/
	addq.l #4, %a0			/*SSPの位置を計算*/
	move.l %sp, (%a0)		/*SSPを保存*/

	***4. curr task を変更:
	lea.l curr_task, %a1    /*カレントタスクのアドレスをa1に転送*/
	move.l next_task, (%a1) /*next_taskの値をa1に格納*/

	***5. 次のタスクの SSP の読み出し：
	move.l curr_task, %d0   /*カレントタスクのIDを転送*/
	lea.l task_tab, %a0     /*タスクコントロールブロックの先頭アドレスを転送*/
	mulu #20, %d0			/*カレントIDを20倍*/
	adda.l %d0, %a0         /*カレントタスクのTCBのアドレスを求める*/
	addq.l #4, %a0			/*SSPの位置を計算*/
	move.l (%a0), %sp       /*SSPを回復*/

	***6. 次のタスクのレジスタの読み出し：
	move.l (%sp)+, %a6     			/*a6を復帰*/
	move.l %a6, %USP        		/*USPを回復*/
	movem.l (%sp)+, %d0-%d7/%a0-%a6 /*全レジスタ回復*/

	***7. タスク切り替えをおこす:
	rte

.extern addq
.extern sched
.extern ready

first_task:
************
***1. TCB 先頭番地の計算：
***curr task の TCB のアドレスを見つける．
***2. USP，SSP の値の回復：
***このタスクの TCB に記録されている SSP の値およびスーパバイザスタックに記録されてい
***る USP の値を回復する．
***3. 残りの全レジスタの回復：
***スーパーバイザスタックに積まれている残り 15 本のレジスタの値を回復する．
***4. ユーザタスクの起動：
***RTE 命令を実行する．
************
	***1.TCBの先頭番地の計算
	move.l #0, %d1        
	move.l curr_task, %d1   /* カレントタスクのIDを転送 */
	lea.l task_tab, %a0     /* タスクコントロールブロックの先頭アドレスを転送 */
	mulu #20, %d1           /* カレントIDを20倍 */
	adda.l %d1, %a0         /* カレントタスクのTCBのアドレスを求める */

	***2. USP，SSP の値の回復：
	addq.l #4, %a0          /* SSPの位置を計算 */
	move.l (%a0), %sp       /* SSPを回復 */
	move.l (%sp)+, %a6      /* a6を復帰 */
	move.l %a6,%USP         /* USPを回復 */

	***3. 残りの全レジスタの回復：
	***move.w	(%sp)+, %SR	|旧走行レベルの回復
	movem.l (%sp)+, %d0-%d7/%a0-%a6     /*全レジスタ回復*/

	***4. ユーザタスクの起動：
	move.b #'8',LED7
	rte     				/*ユーザタスクの起動*/

/*
; 7. init_timer
; クロック割り込みルーチンhard_clockをベクトルテーブルに登録するルーチン。モニタのシステムコールTRAP #0 を利用する。
; 
; 担当：武石
*/

init_timer:
    movem.l %d0-%d2,-(%sp)

	move.l #SYSCALL_NUM_RESET_TIMER,%d0 | SYSCALL_NUM_RESET_TIMER=3
	trap   #0

	move.l #SYSCALL_NUM_SET_TIMER, %d0  | SYSCALL_NUM_SET_TIMER=4
	move.w #200, %d1                  | たいたい1秒
	move.l #hard_clock, %d2
	trap #0

    movem.l (%sp)+, %d0-%d2
    rts
    
/*
; 6. hard_clock
; クロック割り込みルーチン。モニタのシステムコールTRAP #0 を利用して登録するので、rtsで復帰するように書く。
; 
; 担当：武石
*/

hard_clock:
    * 1. 実行中のタスクのレジスタの退避
    movem.l %d0-%d1/%a1,-(%sp)

    * テキストp22参照
    movea.l	%sp, %a1
    move.l #12, %d0     | レジスタ3つ分
    adda.l %d0, %a1     | a1 = SR
    move.w (%a1), %d1   | d1 = (SR)
    andi.w #0x2000, %d1 | d1 = (SR) & 0x2000
    cmpi.w #0x2000, %d1 | 13bit目が1かどうか
    beq hard_clock_end  | 13bit目が1でなければ(ユーザーモードであれば)終了

    * 2. addq()により, curr_taskをreadyの末尾に追加.
    move.l curr_task, -(%sp)
    move.l #ready, -(%sp)
    jsr addq
    add.l #8, %sp

    * 3. schedを起動.
    jsr sched

    * 4. swtchを起動.
    jsr swtch

hard_clock_end:
    * 5. レジスタの復帰.
    movem.l (%sp)+, %d0-%d1/%a1 
    rts
