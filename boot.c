#include "setup.h"

static struct tag * params;

extern void uart0_init(void);
extern void nand_read(unsigned int addr, unsigned char *buf, unsigned int len);
void puts(char *str);


void setup_start_tag ()
{
	params = (struct tag *) 0x30000100;

	params->hdr.tag = ATAG_CORE;
	params->hdr.size = tag_size (tag_core);

	params->u.core.flags = 0;
	params->u.core.pagesize = 0;
	params->u.core.rootdev = 0;

	params = tag_next (params);

}

void setup_memory_tags ()
{
	params->hdr.tag = ATAG_MEM;
	params->hdr.size = tag_size (tag_mem32);
	
	params->u.mem.start = 0x30000000;
	params->u.mem.size = 64*1024*1024;
	
	params = tag_next (params);

}

static int strlen(char *str)
{
	int len = 0;
	while (*(str++)) {
		len ++;
	}

	return len;
}

static void strcpy(char *dest, char *src)
{
	while ((*dest++ = *src++) != '\0');
		/* nothing */
}


void setup_commandline_tag (char *cmdline)
{
	int len = strlen(cmdline) + 1;

	params->hdr.tag = ATAG_CMDLINE;
	params->hdr.size = (sizeof (struct tag_header) + len + 3) >> 2;

	strcpy (params->u.cmdline.cmdline, cmdline);

	params = tag_next (params);

}

void setup_end_tag ()
{
	params->hdr.tag = ATAG_NONE;
	params->hdr.size = 0;
}



int main()
{

	void (*theKernel)(int zero, int arch, unsigned int params);

	/*帮内核设置串口，内核启动的开始部分会通过串口输出打印*/
	uart0_init();

	puts("copy kernel from nandflash\n\r");
	/*从nandflash把kernel读入内存*/
	nand_read(0x00060000 + 64, (unsigned char *)0x30008000, 0x200000);

	/*设置参数*/
	puts("set boot params\n\r");

	setup_start_tag ();
	setup_memory_tags ();
	setup_commandline_tag ("noinitrd root=/dev/mtdblock3 init=/linuxrc console=ttySAC0,115200");
	setup_end_tag ();

	/*跳转执行*/
	puts("boot kernel\n\r");
	theKernel = (void (*)(int, int, unsigned int))0x30008000;
	theKernel(0, 362, 0x30000100);
	puts("boot error\n\r");
	return -1;

}
