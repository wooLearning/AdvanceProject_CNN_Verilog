#include <stdio.h>
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_io.h"
#include <xparameters.h>
#include <unistd.h>
#include <stdint.h> // uintptr_t 사용을 위해 필요 (UINTPTR을 쓰면 xil_types.h 덕분에 생략 가능)

/* For UART Config start */
#ifdef STDOUT_IS_16550
 #include "xuartns550_l.h"
 #define UART_BAUD 9600
#endif

// 주소값 매크로 (세미콜론 없음)
#define ADDR 0xA0000000
#define ADDR_START 0xA0000030

void enable_caches() {
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

void disable_caches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheDisable();
#endif
#endif
}

void init_uart() {
#ifdef STDOUT_IS_16550
    XUartNs550_SetBaud(STDOUT_BASEADDR, XPAR_XUARTNS550_CLOCK_HZ, UART_BAUD);
    XUartNs550_SetLineControlReg(STDOUT_BASEADDR, XUN_LCR_8_DATA_BITS);
#endif
}

void init_platform() {
    enable_caches();
    init_uart();
}

void cleanup_platform() {
    disable_caches();
}

int main() {
    int i = 0;
    int mode;
    int arr[9]; // 음수 입력을 위해 int 사용
    int start = 0;
    
    // 주소 변수 타입을 64비트 호환 타입으로 변경
    UINTPTR addr; 

    init_platform();
    
    while(1){
        i = 0;
        addr = ADDR; // 0xA0000000
        start = 0;
        printf("choose mode : 0, 1, 2, 3\n");
        scanf("%d", &mode);
        printf("your mode : %d\n", mode);

        Xil_Out32(addr, mode);
        

        if(mode == 0){//sharp
            printf("%3d %3d %3d\n",  0, -1,  0);
            printf("%3d %3d %3d\n", -1,  5, -1);
            printf("%3d %3d %3d\n",  0, -1,  0);
        } else if(mode == 1){//more sharp
            printf("%3d %3d %3d\n", -1, -1, -1);
            printf("%3d %3d %3d\n", -1,  9, -1);
            printf("%3d %3d %3d\n", -1, -1, -1);
        } else if(mode == 2){//bypass
            printf("%3d %3d %3d\n",  0, 0, 0);
            printf("%3d %3d %3d\n",  0, 1, 0);
            printf("%3d %3d %3d\n",  0, 0, 0);
        } else if(mode == 3){
            printf("input your filter 9 (integers allowed)\n");
            
            while(i < 9){
                scanf("%d", &arr[i]);
                i++;
            }

            for(i = 0; i < 9; i++){
                if(i > 0 && i % 3 == 0) printf("\n");
                printf("%3d ", arr[i]);
            }
            printf("\n-----------\n");

            // 필터 값 전송
            for(i = 0; i < 2; i++){
                addr += 4;
                *(volatile unsigned int*)(addr) = 
                    ((unsigned int)(arr[i*4]   & 0xFF))       | 
                    ((unsigned int)(arr[i*4+1] & 0xFF) << 8)  | 
                    ((unsigned int)(arr[i*4+2] & 0xFF) << 16) | 
                    ((unsigned int)(arr[i*4+3] & 0xFF) << 24);
            }
            addr += 4;
            *(volatile unsigned int*)(addr) = (unsigned int)(arr[8] & 0xFF);

        }
        printf("시작 하시겠습니까?? 1을 입력하면 시작 \n");
        scanf("%d",&start);
        if(start){
            *(volatile unsigned int*)(ADDR_START) = 1;
        }
        // usleep(100);
    }
    cleanup_platform();
    return 0;
}