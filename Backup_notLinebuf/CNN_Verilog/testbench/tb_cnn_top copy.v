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
        .iRsnButton(iRsn),
        //.iStart(iStart),
        .oLcdClk(oLcdClk),
        .oLcdHSync(oLcdHSync),
        .oLcdVSync(oLcdVSync),
        .oLcdDe(oLcdDe),
        .oLcdBackLight(oLcdBackLight),
        .oLcdR(oLcdR),
        .oLcdG(oLcdG),
        .oLcdB(oLcdB),

		//디버깅용
		.oRgbValid(oRgbValid),
		.oData(oData)
    );
    
    // 100 MHz clock
    initial begin
        iClk = 1'b0;
        forever #5 iClk = ~iClk; // 10ns period
    end

    // --- 테스트벤치 로직 ---

    // 기대값 저장을 위한 메모리
    reg [15:0] expected_memory [0:DEPTH-1];

    // 비교 로직을 위한 변수
    integer pixel_index;
    integer error_count;
    integer line_error_count; // --- NEW --- 라인별 에러 카운터
	integer current_line;
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
    reg a;
    // 2. 리셋 및 변수 초기화
    initial begin
        // reset
        iRsn = 1'b0;
        iStart = 1'b1;
        pixel_index = 0;      // 픽셀 카운터 초기화
        error_count = 0;      // 전체 에러 카운터 초기화
        line_error_count = 0; // --- NEW --- 라인 에러 카운터 초기화
        
        repeat(10) @(posedge iClk);
        iRsn = 1'b1; // 리셋 해제
        a= 1;
    
    end
	
    reg [15:0] expected_rgb565;
    always @(posedge cnn_top.u_RGB888ToRGB565.done_valid_reg)begin
        for(i = 0; i<DEPTH;i=i+1) begin
            expected_rgb565 = expected_memory[i];
            // if(i <10)begin
            //     $display("%h  //// %h",expected_rgb565,cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            // end
            // if(i<130560 && i<130540) begin
            //     $display("%h  //// %h",expected_rgb565,cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            // end
            if(cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i] != expected_rgb565 ) begin
                a = 0;
                $display("ERROR!!!: %d expected: %h , outbuf: %h \n",i,expected_rgb565,cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
            end
        end
        if(a == 1) begin
            $display("All Completed\n");
        end
        else begin
            $display("Failed\n");
        end
         
    end

	/*
    reg [15:0] expected_rgb565;
    // 3. 픽셀 비교 로직
    always @(posedge oRgbValid) begin
        
        if (iRsn && oRgbValid) begin
            
            if (pixel_index < DEPTH) begin
             
                expected_rgb565 = expected_memory[pixel_index];

                // 기대값과 실제 출력값 비교
                if (oData !== expected_rgb565) begin
                    $display("ERROR @ pixel %0d: Expected 0x%h, Got 0x%h", 
                             pixel_index, expected_rgb565, oData);
                    error_count = error_count + 1;
                    line_error_count = line_error_count + 1; // --- NEW ---
                end
                
                pixel_index = pixel_index + 1; // 다음 픽셀 인덱스로 이동

                // --- NEW --- 라인(WIDTH) 단위로 체크하는 로직
                // pixel_index가 480, 960, ... (WIDTH의 배수)가 될 때 실행
                if ((pixel_index % WIDTH) == 0 && pixel_index > 0) begin
                    current_line = (pixel_index / WIDTH) - 1; // 0번째 줄부터 시작
                    
                    if (line_error_count == 0) begin
                        $display(">> [SUCCESS] Line %0d (pixels %0d-%0d) passed.", 
                                 current_line, (pixel_index - WIDTH), (pixel_index - 1));
                    end else begin
                        $display(">> [ FAILED ] Line %0d had %0d errors.", 
                                 current_line, line_error_count);
                    end
                    
                    line_error_count = 0; // 다음 라인을 위해 라인 에러 카운터 리셋
                end
                // --- END NEW ---
                
            end
            
            // 4. 모든 픽셀 비교 완료 시 시뮬레이션 종료
            // (마지막 픽셀 처리 후, 다음 oLcdDe에서 pixel_index == DEPTH가 됨)
			
            if (pixel_index == DEPTH) begin
                if (error_count == 0) begin
                    $display("---------------------------------");
                    $display(">> TEST PASSED: All %0d pixels match.", DEPTH);
                    $display("---------------------------------");
                end else begin
                    $display("---------------------------------");
                    $display(">> TEST FAILED: %0d errors out of %0d pixels.", error_count, DEPTH);
                    $display("---------------------------------");
                end
                $finish; // 시뮬레이션 종료
            end
				
        end
    end
        */

endmodule