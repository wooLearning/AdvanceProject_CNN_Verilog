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

int main()
{
    int i;
    char aschii[32];

    init_platform();
    print("Text LCD SDK Application\n\r");
    print("Please Input Character to display lcd\n\r");
    while(1){
    	scanf("%s", aschii);
    	printf("%s\n", aschii);

    for(i=0; i<8; i++){
        *(volatile unsigned int*)((0xA0000000 + i*4)) = aschii[i*4+3] + (aschii[i*4+2]<<8) + (aschii[i*4+1]<<16) + (aschii[i*4]<<24) ;
    }
    usleep(100);
    for(i=0; i<32; i++){
    	aschii[i] = " ";
    }

//    usleep(1000);
    };
    cleanup_platform();
    return 0;

};
