** EECS-Exp II/III software-exp-I
** v1.0 / 2023-11-15
** Group 4
** 1TE21022R Seo Ichika, 	1TE21143S Miyata Yusaku, 	1TE21940P Saitoh Koshi
** 1TE21913T Takeishi Kota,	1TE21033K Goto Aoto,		1TE21057R Morokuma Haruto

** INDEX
** STEP 1: 初期化ルーチン
** STEP 4-2: INTERUT INTERFACE
** STEP 6-3: INTERGET INTERFACE
** STEP 0-1: キューの初期化ルーチン(1/2)
** STEP 0-2: キューへの入力(INQ), 出力(OUTQ) ルーチン 
** STEP 4-1: INTERPUT
** STEP 5-1: PUTSTRING
** STEP 6-1: GETSTRING
** STEP 6-2: INTERGET
** STEP 7: タイマ制御部
** STEP 8: システムコールインタフェース
** STEP 0-1: キューの初期化ルーチン(2/2)

/* STEP 1: 初期化ルーチンの作成 */
***************************************************************
**各種レジスタ定義
***************************************************************
***************
**レジスタ群の先頭
***************
.equ REGBASE,   0xFFF000          | DMAPを使用．
.equ IOBASE,    0x00d00000
***************
**割り込み関係のレジスタ
***************
.equ IVR,       REGBASE+0x300     |割り込みベクタレジスタ
.equ IMR,       REGBASE+0x304     |割り込みマスクレジスタ
.equ ISR,       REGBASE+0x30c     |割り込みステータスレジスタ
.equ IPR,       REGBASE+0x310     |割り込みペンディングレジスタ
***************
**タイマ関係のレジスタ
***************
.equ TCTL1,     REGBASE+0x600     |タイマ１コントロールレジスタ
.equ TPRER1,    REGBASE+0x602     |タイマ１プリスケーラレジスタ
.equ TCMP1,     REGBASE+0x604     |タイマ１コンペアレジスタ
.equ TCN1,      REGBASE+0x608     |タイマ１カウンタレジスタ
.equ TSTAT1,    REGBASE+0x60a     |タイマ１ステータスレジスタ
***************
** UART1（送受信）関係のレジスタ
***************
.equ USTCNT1,   REGBASE+0x900     | UART1ステータス/コントロールレジスタ
.equ UBAUD1,    REGBASE+0x902     | UART1ボーコントロールレジスタ
.equ URX1,      REGBASE+0x904     | UART1受信レジスタ
.equ UTX1,      REGBASE+0x906     | UART1送信レジスタ
***************
** LED
***************
.equ LED7,      IOBASE+0x000002f  |ボード搭載のLED用レジスタ
.equ LED6,      IOBASE+0x000002d  |使用法については付録A.4.3.1
.equ LED5,      IOBASE+0x000002b
.equ LED4,      IOBASE+0x0000029
.equ LED3,      IOBASE+0x000003f
.equ LED2,      IOBASE+0x000003d
.equ LED1,      IOBASE+0x000003b
.equ LED0,      IOBASE+0x0000039


***************
**システムコール番号
***************
.equ SYSCALL_NUM_GETSTRING,     1
.equ SYSCALL_NUM_PUTSTRING,     2
.equ SYSCALL_NUM_RESET_TIMER,   3
.equ SYSCALL_NUM_SET_TIMER,     4


***************************************************************
**スタック領域の確保
***************************************************************
.section .bss
.even
SYS_STK:
	.ds.b   0x4000  |システムスタック領域
	.even
SYS_STK_TOP:        |システムスタック領域の最後尾
task_p:
	.ds.l 1         |タイマ用

***************************************************************
**初期化**内部デバイスレジスタには特定の値が設定されている．
**その理由を知るには，付録Bにある各レジスタの仕様を参照すること．
***************************************************************
.section .text
.even
.extern start
.global monitor_begin
monitor_begin:
boot:
	*スーパーバイザ&各種設定を行っている最中の割込禁止
	move.w #0x2700,%SR
	lea.l  SYS_STK_TOP, %SP | Set SSP


	****************
	**割り込みコントローラの初期化
	****************
	move.b #0x40, IVR       |ユーザ割り込みベクタ番号を
				| 0x40+levelに設定.
	move.l #0x00ffffff, IMR  |全割り込みマスク|**割り込みを許可

	****************
	**送受信(UART1)関係の初期化(割り込みレベルは4に固定されている)
	****************
	move.w #0x0000, USTCNT1 |リセット
	move.w #0xE10C, USTCNT1 |送受信可能,パリティなし, 1 stop, 8 bit,
				|送受信割り込み禁止
	move.w #0x0038, UBAUD1  | baud rate = 230400 bps

	****************
	**タイマ関係の初期化(割り込みレベルは6に固定されている)
	*****************
	move.w #0x0004, TCTL1   | restart,割り込み不可,|システムクロックの1/16を単位として計時，
	|タイマ使用停止

    *****************
    ** キューの初期化
    *****************
	jsr INIT_Q

	****************
	**割り込み処理ルーチンの初期化
	****************
	move.l #INTERFACE, 0x110			/* level 4, (64+4)*4 */ 
	move.l #timer_interface, 0x118		/* level 6, (64+6)*4 */
	move.l #SYSCALL_INTERFACE, 0x080	/* trap #0 割り込みベクタ設定 */
	move.l #0x00ff3ff9, IMR				/* 割り込み許可*/
	move.w #0x2000,%SR					/* 走行レベルを0にする */

	jmp start
	bra MAIN

	
****************************************************************
***プログラム領域
****************************************************************
.section .text
.even
MAIN:
	**走行モードとレベルの設定(「ユーザモード」への移行処理)
	move.w #0x0000, %SR  | USER MODE, LEVEL 0
	lea.l USR_STK_TOP,%SP  | user stackの設定
	**システムコールによるRESET_TIMERの起動
	move.l #SYSCALL_NUM_RESET_TIMER,%D0
	trap   #0
	**システムコールによるSET_TIMERの起動
	move.l #SYSCALL_NUM_SET_TIMER, %D0
	move.w #50000, %D1
	move.l #TT,    %D2
	trap #0
	
******************************
* sys_GETSTRING, sys_PUTSTRINGのテスト
*ターミナルの入力をエコーバックする
******************************
LOOP:
	move.l #SYSCALL_NUM_GETSTRING, %D0
	move.l #0,   %D1        | ch    = 0
	move.l #BUF, %D2        | p    = #BUF
	move.l #256, %D3        | size = 256
	trap #0
	move.l %D0, %D3         | size = %D0 (length of given string)
	move.l #SYSCALL_NUM_PUTSTRING, %D0
	move.l #0,  %D1         | ch = 0
	move.l #BUF,%D2         | p  = #BUF
	trap #0
	bra LOOP

******************************
*タイマのテスト
* ’******’を表示し改行する．
*５回実行すると，RESET_TIMERをする．
******************************
TT:
	movem.l %D0-%D7/%A0-%A6,-(%SP)
	cmpi.w #5,TTC            | TTCカウンタで5回実行したかどうか数える
	beq TTKILL               | 5回実行したら，タイマを止める
	move.l #SYSCALL_NUM_PUTSTRING,%D0
	move.l #0,    %D1        | ch = 0
	move.l #TMSG, %D2        | p  = #TMSG
	move.l #8,    %D3        | size = 8
	trap #0
	addi.w #1,TTC            | TTCカウンタを1つ増やして
	bra TTEND                |そのまま戻る
TTKILL:
	move.l #SYSCALL_NUM_RESET_TIMER,%D0
	trap #0
TTEND:
	movem.l (%SP)+,%D0-%D7/%A0-%A6
	rts


****************************************************************
***初期値のあるデータ領域
****************************************************************
.section .data
TMSG:
	.ascii  "******\r\n"      | \r:行頭へ(キャリッジリターン)
	.even                     | \n:次の行へ(ラインフィード)
TTC:
	.dc.w  0
	.even

****************************************************************
***初期値の無いデータ領域
****************************************************************
.section .bss
BUF:
	.ds.b 256           | BUF[256]
	.even
USR_STK:
	.ds.b 0x4000        |ユーザスタック領域
	.even
USR_STK_TOP:            |ユーザスタック領域の最後尾


.section .text
.even

/* STEP 4-2: INTERUT INTERFACE, STEP 6-3: INTERGET INTERFACE */
** ここから送受信割り込みインタフェース
** 担当：齊藤

********************************
**送受信割り込みインターフェース
********************************　

******************************************************************************************************
**【手順説明】
** 受信レジスタ URX1 を %D3.W にコピー
** %D3.W の下位 8bit(データ部分) を %D2.B にコピー
** 今起こっている割り込みが，受信割り込みであるかを，%D3.W の 第 13 ビット目を用いてチェックする．
** 受信割り込みであった場合，チャンネル ch = %D1.L =0, データ data = %D2.B としてINTERGET を呼び出す. 
** 今起こっている 割り込みが，送信割り込みであるかを，送信レジスタ UTX1の第 15 ビット目を用いてチェックする．
** 送信割り込みであった場合，ch=%D1.L=0 として INTERPUT を呼び出す
******************************************************************************************************

******************************************************************************************************
**【受信＆送信レジスタの説明】
** UTX1 15bit 0:送信FIFOが空でない（INTERPUTで送信キューからOUTQ） 1:送信FIFOが空
** URX1 13bit 0:受信FIFOが空              				 1:受信FIFOにデータがある（INTERGETで受信キューにINQ）
******************************************************************************************************

INTERFACE:
	movem.l %d1-%d3/%a0, -(%sp)
INTERGET_INTERFACE:
	move.w  URX1, %d3	|URX1をd3にコピー
	move.b  %d3, %d2    |d3の下位8bitをコピー 　data = %d2.b
	andi.w  #0x2000,%d3	|13ビット目をチェック（bit13=1なら%d3が0x2000となる）
	cmpi.w  #0x2000,%d3	|%d3が0x2000であるかチェック
	bne     INTERPUT_INTERFACE |13ビット目が１だったら受信割込
	move.l  #0, %d1 	|受信割り込みだったので、ch=%d1.l=0としてINTERGETを呼び出す
	jsr     INTERGET        
	bra	INTERFACE_FINISH
INTERPUT_INTERFACE:
	move.w  UTX1, %d3
	andi.w  #0x8000, %d3
	cmpi.w  #0x0000, %d3 
	beq    INTERFACE_FINISH |UTX1 15bit = 0（送信FIFOが空でない）INTERPUT_FINISHへ
	move.l #0, %d1        	|送信割り込みだったので、ch=%d1.l=0としてINTERPUTを呼び出す
	jsr    INTERPUT 
INTERFACE_FINISH:
	movem.l (%sp)+, %d1-%d3/%a0
	rte
	

/* STEP 0-1: キューの初期化ルーチン */
** (2) 送信キュー・受信キューの両方について，キューのデータ用および前述の変数用の領域を確保
INIT_Q:	
	movem.l %a0-%a1 ,-(%sp)

/* キュー0の初期化 */
	movea.l	#Que0, %a0		/*構造体Que0の先頭アドレス*/
	move.l  #top, %a1	
	add.l	%a0, %a1 		/*a1でキュー０の先頭番地を指定*/
	move.l  %a1, out(%a0) 	/*enqueポインタ初期化*/
	move.l  %a1, in(%a0) 	/*dequeポインタ初期化*/
	move.b	#0, s(%a0) 		/*カウンタの初期化*/

    /* キュー1の初期化 */
	movea.l #Que1, %a0 		/*構造体Que１の先頭アドレス*/
	move.l  #top, %a1
	add.l   %a0, %a1 		/*a1でキュー1の先頭番地を指定*/
	move.l  %a1, out(%a0) 	/*enqueポインタ初期化*/
	move.l  %a1, in(%a0) 	/*dequeポインタ初期化*/
	move.b  #0, s(%a0) 		/*カウンタの初期化*/	

	movem.l (%sp)+, %a0-%a1
	rts


/* STEP 0-2: キューへの入力(INQ), 出力(OUTQ) ルーチンの作成 */
** INQ(no, data)
** argument:    (1) cue number no = %d0
**              (2) 8-bit data to write = %d1
** return:      result flag = %d0 (0: failure, 1: success)

/* (1) */
INQ:						/* キューへの入力 */
	move.w	%sr, -(%sp)		/* (1) 現走行レベルの退避 */
	move.w	#0x2700, %sr	/* (2) 割り込み禁止 */
	movem.l	%a0-%a3, -(%sp)	/* レジスタの退避 */
	movea.l	#Que0, %a0		/* キュー0参照用アドレス */
	cmpi.l	#0, %d0	        /* キュー番号の確認 */
	beq	INQ_CHECK       	/*キュー1を使用*/
	movea.l	#Que1, %a0		/* キュー1参照用アドレス */
/* (3) */
INQ_CHECK:
	cmpi.w	#256 ,s(%a0)	/* s == 256 ?：キュー内のデータの個数を確認 */
	bne	INQ_START			/* true:  キューが一杯でなければ書き込み可能 */
	moveq.l	#0, %d0			/* false: (3-1) %D0 を0（失敗：queue full）に設定：書き込み失敗 */
	bra	INQ_END             /* false: (3-2) (7)へ */
/* (4), (5-2) */
INQ_START:
/* (4) m[in] = data */
	movea.l	in(%a0), %a1	/* 書き込み先アドレスを格納 */
	move.b	%d1, (%a1)		/* 書き込み処理 */
	movea.l	%a0, %a2
	adda.l	#bottom, %a2	/* キューの末尾のアドレスを格納 */

    /* (5) if (in == bottom) */
	cmpa.l	in(%a0), %a2	/* 書き込んだ位置がキューの末尾か確認 */
	beq	INQ_TOP

	/* (5-2) else in++  */
	addi.l	#1, in(%a0)		/* 書き込み位置のアドレスを1加算 */
	bra	INQ_SUCCESS

/* (5-1) */
INQ_TOP:
/*  (5-1) in=top */
	move.l	#top, %a3
	add.l	%a0, %a3		/* topのアドレスを求める */
	move.l	%a3, in(%a0)	/* 書き込み位置をキューの先頭に移動 */
/* (6) */
INQ_SUCCESS:
/* s++, %D0 を1（成功）に設定 */
	addi.w	#1, s(%a0)		/* 個数を1加算 */
	moveq.l	#1, %d0			/* 書き込み成功 */

/* (7) */
INQ_END:	
	movem.l	(%sp)+, %a0-%a3	/* レジスタの回復 */
	move.w	(%sp)+, %sr		/* (7) 旧走行レベルの回復 */
	rts

**************************************************
***a0:選択された構造体の先頭アドレス（変更不可）
***a1:構造体の先頭アドレスのコピー（変更可
***************************************************

** OUTQ(no, data)
** argument:    cue number no = %d0
** return:      (1) result flag = %d0 (0: failure, 1: success)
**              (2) 8-bit data to read = %d1
	
/* (1), (2) */	
OUTQ:
	move.w	%sr, -(%sp) 	/* (1) 現走行レベルの退避 */
	move.w	#0x2700, %sr 	/* (2) 割り込み禁止 */
	movem.l %a0-%a3, -(%sp) /* レジスタ退避 */
	movea.l #Que0, %a0		/* キュー0参照用アドレス */

    /* Que0 or Que1 */
	cmpi.l	#0, %d0	        /* キュー番号の確認 */
	beq	OUTQ_CHECK      	/* キュー0を使用 */
	              			/* キュー1を使用 */
	movea.l #Que1, %a0		/* キュー1参照用アドレス */
/* (3) */	
OUTQ_CHECK:
/* (3) s == 0 ならば%D0 を0（失敗：queue empty）に設定し，(7) へ */
	cmpi.w	#0, s(%a0)      /* キュー内のデータの個数を確認 */
	bne	OUTQ_START      	/* キューが一杯でなければ読み出し可能 */
	moveq.l	 #0, %d0 		/*失敗*/
	bra	OUTQ_END
/* (4), (5-2) */
OUTQ_START:
	movea.l out(%a0), %a1   /* 読み出し先アドレスを格納*/
	move.b  (%a1), %d1      /* (4) data = m[out]；読み出し処理*/
	movea.l	%a0, %a2
	adda.l	#bottom, %a2	/* キューの末尾のアドレスを格納 */

    /* (5) if (out == bottom) */
	cmpa.l	out(%a0), %a2	/* 読み込んだ位置がキューの末尾か確認 */
	beq	OUTQ_TOP

	/* (5-2) else out++  */
	addi.l	#1, out(%a0)	/* 読み出し位置のアドレスを1加算 */
	bra OUTQ_SUCCESS

/* (5-1) */
OUTQ_TOP:	
/*  (5-1) out=top */
	move.l	#top, %a3
	add.l	%a0, %a3		/* topのアドレスを求める */
	move.l	%a3, out(%a0)	/* 読み出し位置をキューの先頭に移動 */

/* (6) */
OUTQ_SUCCESS:
/* s––, %D0 を1（成功）に設定 */
	subi.w	#1, s(%a0)		/* 個数を1減算 */
	moveq.l	#1, %d0			/* 読み出し成功 */

/* (7)  */
OUTQ_END:	
	movem.l	(%sp)+, %a0-%a3	/* レジスタの回復 */
	move.w	(%sp)+, %sr		/* (7) 旧走行レベルの回復 */
	rts


**************************************************
***a0:選択された構造体の先頭アドレス（変更不可）
***a1:構造体の先頭アドレスのコピー（変更可）
***************************************************

**ここからINTERPUT・PUTSTRING
**担当：諸隈・宮田・瀬尾

INTERPUT:
    **(1) 割り込み禁止（走行レベルを7に設定）
    move.w  #0x2700, %SR
    movem.l %d0, -(%sp)
	
    **(2) ch ≠ 0 ならば、何もせずに復帰
    cmp.l   #0, %d1
    bne     INTERPUT_Exit

    **(3) OUTQ(1, data) を実行する (= 送信キューから8bitデータを1つ取り出しdataに代入)
    move.l  #1, %d0     | キュー番号を指定 (1は送信キュー)
    jsr     OUTQ

    **(4) OUTQの戻り値が0 (失敗) ならば、送信割り込みをマスク (USTCNT1を操作) して復帰
    cmp.l  #0, %d0           | %D0にOUTQの戻り値が格納されている
    beq     INTERPUT_MUSK | OUTQが失敗した場合は何も送信せずに復帰

    **(5) dataを送信レジスタUTX1に代入して送信 (上位8ビット分のヘッダを忘れずに)
    **上位8ビットのヘッダを付与しておく
    add.w  #0x0800, %d1
    move.w  %d1, UTX1
    
INTERPUT_Exit:
    **(6) 旧走行レベルの回復
    movem.l (%sp)+, %d0
    rts

INTERPUT_MUSK:
    move.w #0xE108, USTCNT1
    bra INTERPUT_Exit

/* STEP 5: 送信制御部の完成（PUTSTRING）*/

*****************************************
*** a0=i
*** d0=sz(実際に送信したデータ数)
*** d1=ch
*** d2=p(データ読み込み先の先頭アドレス)
*** d3=size(送信するデータ数)
*****************************************

PUTSTRING:
    movem.l	%a0-%a3, -(%sp)  /* レジスタ退避 */

    ** (1) ch != 0 ならば，(11) へ．(=なにもせず復帰)
    cmp.l   #0, %d1          /* ch≠0ならば何もせず復帰 */
    bne     PUTSTRING_END
	
	** (2) sz <- 0, i <- p
	lea.l	sz, %a0         /* sz <- 0 */
	lea.l	i, %a1          /*  i <- p */
    move.l	#0, (%a0)
	move.l	%d2, (%a1)

    ** (3) size = 0 ならば，(10)へ
	cmp.l	#0, %d3
	beq	PUTSTRING_RETURN

PUTSTRING_LOOP:
    ** (4) sz = size ならば，(9)へ
	cmp.l	(%a0), %d3      /* sz = sizeならばUnmusk */
    beq	PUTSTRING_UNMUSK
	
    ** (5) INQ(1, i) を実行し，送信キューへi番地のデータを書き込む．
    move.l	#1, %d0         /* 送信キューを選択 */
    movea.l	(%a1), %a3      /* 送信するデータを入力 */
    move.b	(%a3), %d1      
	jsr	INQ	/*INQ(1, i)*/
    
    ** (6) INQ の復帰値が0 (失敗/ queue full) なら(9) へ
    cmp.l	#0, %d0         /* INQの復帰値が0ならばUnmusk */
    beq	PUTSTRING_UNMUSK

    ** (7) sz++, i++, (10) sz -> %d0
    add.l	#1, (%a0)       /* sz++ */
    add.l	#1, (%a1)       /* i++ */

    ** (8) (4)へ
    bra	PUTSTRING_LOOP
	

PUTSTRING_UNMUSK:
    ** (9) USTCNT1 を操作して送信割り込み許可(アンマスク)
    move.w  #0xe10C, USTCNT1 /*送信割り込みをアンマスク*/

PUTSTRING_RETURN:	
	move.l	(%a0), %d0	

PUTSTRING_END:
    movem.l	(%sp)+, %a0-%a3
    rts

	
/* STEP 6: 受信制御部の完成（GETSTRING, INTERGET）*/
/* STEP 6-1: GETSTRING */
GETSTRING:
    movem.l %d1-%d4/%a0, -(%sp)

** (1) ch!=0ならば，なにも実行せず復帰
    cmpi.l #0x0, %d1
    bne GETSTRING_Exit /* d1 != 0ならば，走行レベルを回復させ処理を終了 */

** (2) sz <- 0, i <- p
    move.l #0, %d4
    movea.l %d2, %a0

GETSTRING_LOOP:
** (3) sz = sizeならば，(9)へ
    cmp.l %d4, %d3
    beq GETSTRING_Exit

** (4) OUTQ(0, data)により，受信キューから8bitデータ読み込み
    move.l #0, %d0
    jsr OUTQ

** (5) OUTQの復帰値（%0の値）が0（＝失敗）なら(9)へ
    cmp.l #0, %d0
    beq GETSTRING_Exit

** (6) i番地にdataをコピー
    move.b %d1, (%a0)

** (7) sz++, i++
    addi.l #1, %d4
    adda.l #1, %a0

** (8) (3)へ
    bra GETSTRING_LOOP

GETSTRING_Exit:
** (9) sz -> %d0
    move.b #'8',LED0
    move.l %d4, %d0
    movem.l (%sp)+, %d1-%d4/%a0
    rts

/* STEP 6-2: INTERGET */
***********************************************
*** INTERGET(ch, data)
*** 【機能】
*** - 受信データを受信キューに格納する
*** - チャネルchが0以外の場合は，なにも実行しない
*** 【入力】
*** - チャネル：ch -> %d1.l
*** - 受信データ：data -> %d2.b
*** 【戻り値】
*** なし
*** 【処理内容】
*** (1) ch!=0ならば，なにも実行せず復帰
*** (2) INQ(0, data)
***********************************************

INTERGET:
    movem.l %d0-%d2, -(%sp)

* (1) ch!=0ならば，なにも実行せず復帰
    cmpi.l #0x0, %d1
    bne INTERGET_Finish  /* 走行レベルを回復させ処理を終了 */

* (2) INQ(0, data)
    move.l #0, %d0
    move.b %d2, %d1
    move.b #'1', LED2   /* 文字'1'をLEDの8桁目に表示 */
    jsr INQ
    move.b #'3', LED3   /* 文字'3'をLEDの6桁目に表示 */

INTERGET_Finish:
    movem.l (%sp)+, %d0-%d2
    rts

/* STEP 7: タイマ制御部の完成（RESET_TIMER, SET_TIMER, CALL_RP, TIMER INTERFACE）*/
/* STEP 7-3: TIMER INTERFACE */
** こっからTIMER関係
** 担当：武石
timer_interface:
    movem.l %d0, -(%sp)         | レジスタ退避
    move.w TSTAT1, %d0          | とりあえずd0 = TSTAT1 にコピー
    andi.w #0x0001, %d0         | d0 = d0 & 0x0001
    bne timer_interface_label   | d0 = TSATA1 の第 0 ビットが 0 ならば timer_interface_label へ
    rte                         | 1 ならば rte で復帰

timer_interface_label:
    move.w #0x0000, TSTAT1      | TSTAT1 = 0 (TSTAT1 のリセット)
    jsr CALL_RP                 | CALL RP を呼び出す
    movem.l (%sp)+, %d0         | レジスタ回復
    rte

/* STEP 7-1: RESET TIMER */
RESET_TIMER:
    move.w #0x0004, TCTL1
    rts

/* STEP 7-2: SET TIMER */
SET_TIMER:
    movem.l	%d1-%d2, -(%sp)     | レジスタ退避
    move.l %d2, task_p          | 先頭アドレス p → %D2.L を，大域変数 task p に代入
    move.w #0x00CE, TPRER1      | TPRER1の値は, 計算すると 206.2576 になった. 推奨値も206なのでいいか
    move.w %d1, TCMP1           | タイマ割り込み発生周期 t を，タイマ 1 コンペアレジスタ TCMP1 に代入
    move.w #0x0015, TCTL1       | TCTL1 = 0000 0000 0001 0101
    movem.l	(%sp)+, %d1-%d2     | レジスタ復帰
    rts

/* STEP 7-3: CALL_RP */
CALL_RP:
    movem.l	%a0, -(%sp)
	movea.l task_p, %a0 
	jsr (%a0)
	movem.l (%sp)+, %a0
	rts


/* STEP 8: システムコールインタフェースの完成 */
** ここからシステムコールインタフェース
** 担当：後藤

SYSCALL_INTERFACE:
** (1) システムコール番号 %D0 を 実行先アドレスに変換する．
** (2) システムコールを呼び出す

    movem.l %a0, -(%sp) |レジスタ退避
    cmp.l #SYSCALL_NUM_GETSTRING, %d0
    beq SYSCALL_1
    cmp.l #SYSCALL_NUM_PUTSTRING, %d0
    beq SYSCALL_2
    cmp.l #SYSCALL_NUM_RESET_TIMER, %d0
    beq SYSCALL_3
    cmp.l #SYSCALL_NUM_SET_TIMER, %d0
    beq SYSCALL_4
SYSCALL_1:
    move.l #GETSTRING, %d0
    bra JUMP_SYSCALL
SYSCALL_2:
    move.l #PUTSTRING, %d0
    bra JUMP_SYSCALL
SYSCALL_3:
    move.l #RESET_TIMER, %d0
    bra JUMP_SYSCALL
SYSCALL_4:
    move.l #SET_TIMER, %d0
    bra JUMP_SYSCALL
JUMP_SYSCALL:
    movea.l %d0, %a0
    jsr (%a0)
SYSCALL_INTERFACE_FINISH:
    movem.l (%sp)+,%a0  |レジスタ復帰
    rte

    
.section .data

/* STEP 0-1: キューの初期化ルーチン */
** (2) データ領域のアドレス（先頭・末尾）を代入，データ数の初期化
Que_START:	.ds.b	536

	/*キューの各先頭アドレス*/
    .equ    Que0, Que_START
    .equ    Que1, Que0 + 0x0000010c
	
	/*キューの各要素のオフセット*/
	.equ	out, 0
	.equ	in, 4
	.equ	s, 8  /*2byte分確保*/
	.equ	top, 10
	.equ	bottom, 266

sz:		.ds.l 1
i: 		.ds.l 1
.end
