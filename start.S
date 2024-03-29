#define S3C2440_MPLL_200MHZ     ((0x5c<<12)|(0x01<<4)|(0x02))
#define S3C2440_MPLL_400MHZ     ((92<<12)|(1<<4)|(1<<0))
#define MEM_CTL_BASE    0x48000000


.text
.global _start

_start:

/* 1.关看门狗 */
	ldr r0, =0x53000000
	ldr r1, =0
	str r1, [r0]

/* 2.初始化时钟 */
	/* CLKDIVN(0x4C000014) = 0X3, tFCLK:tHCLK:tPCLK = 1:4:8  */

	/* LOCKTIME(0x4C000000) = 0xFFFFFFFF */
	ldr r0, =0x4C000000
	ldr r1, =0xFFFFFFFF
	str r1, [r0]

	ldr r0, =0x4C000014
	ldr r1, =0x5
	str r1, [r0]

	/* 设置CPU工作于异步模式 */
	mrc p15,0,r0,c1,c0,0
	orr r0,r0,#0xc0000000   //R1_nF:OR:R1_iA
	mcr p15,0,r0,c1,c0,0

	/* MPLLCON = S3C2440_MPLL_400MHZ */
	ldr r0, =0x4C000004
	ldr r1, =S3C2440_MPLL_400MHZ
	str r1, [r0]

/*enable icache*/
	mrc	p15, 0, r0, c1, c0, 0
	orr r0, r0, #(1<<12)
	mcr	p15, 0, r0, c1, c0, 0


/* 3.初始化SDRAM */
	ldr r0, =MEM_CTL_BASE
	adr r1, sdram_config
	add r3, r0, #(13*4)
1:
	ldr r2, [r1], #4
	str r2, [r0], #4
	cmp r0, r3
	bne 1b


/* 4.重定位 */
	ldr sp, =0x34000000

	bl nand_init

	ldr r0, =0x00000000
	ldr r1, =_start
	ldr r2, =__bss_start
	sub r2, r2, r1
	
	bl copycode2sdram
	bl clearbss

/* 5.执行main函数 */
	ldr lr, =halt
	ldr pc, =main

halt:
	b halt

sdram_config:
	.long 0x22011110	 //BWSCON
	.long 0x00000700	 //BANKCON0
	.long 0x00000700	 //BANKCON1
	.long 0x00000700	 //BANKCON2
	.long 0x00000700	 //BANKCON3  
	.long 0x00000700	 //BANKCON4
	.long 0x00000700	 //BANKCON5
	.long 0x00018005	 //BANKCON6
	.long 0x00018005	 //BANKCON7
	.long 0x008C04F4	 // REFRESH
	.long 0x000000B1	 //BANKSIZE
	.long 0x00000030	 //MRSRB6
	.long 0x00000030	 //MRSRB7

