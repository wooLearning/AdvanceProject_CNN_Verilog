`timescale 1ns/1ps

module tb_cnn_top;

    localparam ADDR_W = 17;
    localparam DATA_W = 24;
    localparam DEPTH  = 130560; // 비교할 총 픽셀 수 (480 * 272)
    localparam WIDTH  = 480;    // --- NEW --- 1줄의 픽셀(가로) 수

    reg iClk;
    reg iRsn;
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

    // DUT 인스턴스
    cnn_top cnn_top(
        .iClk(iClk),
        .iRstButton(iRsn),
        .iStartButton(iStart),
        .oLcdClk(oLcdClk),
        .oLcdHSync(oLcdHSync),
        .oLcdVSync(oLcdVSync),
        .oLcdDe(oLcdDe),
        .oLcdBackLight(oLcdBackLight),
        .oLcdR(oLcdR),
        .oLcdG(oLcdG),
        .oLcdB(oLcdB)
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
        $readmemh("C:/Users/user/Desktop/AdvancedProject/hw11/CNN_Verilog/image/out_rgb565.txt", expected_memory);
    end

    reg [3:0] rCnt;
   wire iEn;
    
    always @(posedge iClk, negedge iRsn) begin
        if(!iRsn) begin
            rCnt <= 0;
        end
        else if (rCnt == 4'hF) begin
            rCnt <= 4'b0;
        end else begin
            rCnt <= rCnt + 1'b1;
        end
    end
   assign iEn = (rCnt == 4'hF)  ? 1'b1 : 1'b0;
    reg flag;
    // 2. 리셋 및 변수 초기화
    initial begin
        iRsn = 1'b1;
        iStart = 1'b1;
        flag = 1;
        // reset
        iRsn = 1'b0;
        repeat(10) @(posedge iClk);
        iRsn = 1'b1; // 리셋 해제

        repeat(3) @(posedge iEn);
        
        repeat(10) @(posedge iClk);
        iStart = 1'b0;
        repeat(100) @(posedge iClk);
        iStart = 1'b1;
    end
   
    reg [15:0] expected_rgb565;
    always @(posedge cnn_top.u_RGB888ToRGB565.done_valid_reg)begin
        for(i = 0; i<DEPTH;i=i+1) begin
            expected_rgb565 = expected_memory[i];
            // if(i <10)begin
            //     $display("%h  //// %h",expected_rgb565,cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            // end
            // if(i<130560 && i>130540) begin
            //     $display("%h  //// %h",expected_rgb565,cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            // end
            if(cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i] != expected_rgb565 ) begin
                flag = 0;
                $display("ERROR!!!: %d expected: %h , outbuf: %h \n",i,expected_rgb565,cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            end
        end
        if(flag == 1) begin
            $display("All Completed\n");
        end
        else begin
            $display("Failed\n");
        end
    end

endmodule