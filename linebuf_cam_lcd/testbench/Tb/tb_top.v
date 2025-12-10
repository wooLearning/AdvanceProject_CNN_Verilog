`timescale 1ns/1ps

module tb_cnn_top;

    localparam ADDR_W = 17;
    localparam DATA_W = 24;
    localparam DEPTH  = 130560; // 비교할 총 픽셀 수 (480 * 272)
    localparam WIDTH  = 480;    // --- NEW --- 1줄의 픽셀(가로) 수

    reg iClk;
    reg iRsn;
    /*
    reg iStart;

    wire oLcdClk;
    wire oLcdHSync;
    wire oLcdVSync;
    wire oLcdDe;
    wire oLcdBackLight;
    wire [4:0] oLcdR;
    wire [5:0] oLcdG;
    wire [4:0] oLcdB;
    wire oRgbValid;
    wire [15:0] oData;

    wire [15:0] rgbcom = {oLcdR , oLcdG, oLcdB};
    */


    top top(
    .PL_CLK_100MHZ(iClk),
    .RstButton(iRsn),

    //카메라의 input은 bram에 init coe file로 대체해서 1cycle만 test

    /*
    inout  wire            CAMERA_SCCB_SCL,
    inout  wire            CAMERA_SCCB_SDA,

    //cam
    input  wire            CAMERA_PCLK,
    input  wire  [ 7:0]    CAMERA_DATA,
    output wire            CAMERA_RESETn,
    input  wire            CAMERA_HSYNC,
    input  wire            CAMERA_VSYNC,
    output wire            CAMERA_PWDN,
    output wire            CAMERA_MCLK,
    
    //TFT-LCD
    output wire  [ 4:0]    TFT_B_DATA,
    output wire  [ 5:0]    TFT_G_DATA,
    output wire  [ 4:0]    TFT_R_DATA,
    output wire            TFT_DCLK,
    output wire            TFT_BACKLIGHT,
    output wire            TFT_DE,
    output wire            TFT_HSYNC,
    output wire            TFT_VSYNC,
    */
    // axi lite interface
    .iReg0(32'b0),
    .iReg1(0),
    .iReg2(0),
    .iReg3(0)
    );
   
    // 100 MHz clock
    initial begin
        iClk = 1'b0;
        forever #5 iClk = ~iClk; // 10ns period
    end

    // --- 테스트벤치 로직 ---

    // 기대값 저장을 위한 메모리
    reg [15:0] expected_memory [0:DEPTH-1];
    integer i;
   
    // 1. 기대값 파일 로드
    initial begin
        $readmemh("C:/Users/user/Desktop/AdvancedProject/hw15/testbench/Image/final/out_rgb565.txt", expected_memory);
    end

    reg [3:0] rCnt;
    wire iEn;
    
    always @(posedge iClk, negedge iRsn) begin
        if(!iRsn) begin
            rCnt <= 0;
        end
        else if (rCnt == 4'h7) begin
            rCnt <= 4'b0;
        end else begin
            rCnt <= rCnt + 1'b1;
        end
    end
   assign iEn = (rCnt == 4'h7)  ? 1'b1 : 1'b0;

    reg flag;
    // 2. 리셋 및 변수 초기화
    initial begin
        iRsn = 1'b1;
        flag = 1;
        // reset
        iRsn = 1'b0;
        repeat(10) @(posedge iClk);
        iRsn = 1'b1; // 리셋 해제

    end
   
    reg [15:0] expected_rgb565;
    always @(posedge top.u_cnn_top.u_RGB888ToRGB565.done_valid_reg)begin
        for(i = 0; i<DEPTH;i=i+1) begin
            expected_rgb565 = expected_memory[i];
            // if(i <10)begin
            //     $display("%h  //// %h",expected_rgb565,u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            // end
            // if(i<130560 && i>130540) begin
            //     $display("%h  //// %h",expected_rgb565,u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            // end
            if(top.u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i] != expected_rgb565 ) begin
                flag = 0;
                $display("ERROR!!!: %d expected: %h , outbuf: %h \n",i,expected_rgb565,top.u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            end
        end
        if(flag == 1) begin
            $display("All Completed\n");
            $stop;
        end
        else begin
            $display("Failed\n");
            $stop;
        end
        
    end

endmodule