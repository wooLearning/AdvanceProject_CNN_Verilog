#include <stdio.h>
#include "source_code.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_io.h"
#include <xparameters.h>

/*    For UART Config start    */
#ifdef STDOUT_IS_16550
 #include "xuartns550_l.h"

 #define UART_BAUD 9600
#endif

void
enable_caches()
{
#ifdef __PPC__
    Xil_ICacheEnableRegion(CACHEABLE_REGION_MASK);
    Xil_DCacheEnableRegion(CACHEABLE_REGION_MASK);
#elif __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheEnable();
#endif
#endif
}

void
disable_caches()
{
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheDisable();
#endif
#endif
}

void
init_uart()
{
#ifdef STDOUT_IS_16550
    XUartNs550_SetBaud(STDOUT_BASEADDR, XPAR_XUARTNS550_CLOCK_HZ, UART_BAUD);
    XUartNs550_SetLineControlReg(STDOUT_BASEADDR, XUN_LCR_8_DATA_BITS);
#endif
    /* Bootrom/BSP configures PS7/PSU UART to 115200 bps */
}

#define ADDR 0xA0000000;

void
init_platform()
{
    /*
     * If you want to run this example outside of SDK,
     * uncomment one of the following two lines and also #include "ps7_init.h"
     * or #include "ps7_init.h" at the top, depending on the target.
     * Make sure that the ps7/psu_init.c and ps7/psu_init.h files are included
     * along with this example source files for compilation.
     */
    /* ps7_init();*/
    /* psu_init();*/
    enable_caches();
    init_uart();
}
void
cleanup_platform()
{
    disable_caches();
}

/*    For UART Config end    */

int main() {
    int i=0;
    int mode;
    char arr[9];
    int addr;
    init_platform();
    printf("choose mode : 0, 1, 2, 3\n");
    while(1){
        addr = ADDR;
    	scanf("%d", mode);
    	printf("your mode : %d\n", mode);
        *(volatile unsigned int*)(addr) = mode;
        addr += 4;// address 1개 
        if(mode == 3){
            printf("input your filter 9");
            while(i < 9){
                scanf("%c",arr[i]);
                arr[i] = arr[i] - '0'
                i++;
            }
            for(i=0; i<2; i++){
                *(volatile unsigned int*)((addr + i*4)) = 
                (arr[i*4]) + (arr[i*4+1]<<8) + (arr[i*4+2]<16) + (arr[i*4+3]<<24) ;
                addr += (i*4);
            }
            *(volatile unsigned int*)(addr) = arr[8];//나머지 1개 (총 9개 넣어줘야함)
        }

        usleep(100);
        /*
        for(i=0; i<9; i++){
            arr[i] = 0;
        }
        */
        cleanup_platform();
        return 0;
    };
}
