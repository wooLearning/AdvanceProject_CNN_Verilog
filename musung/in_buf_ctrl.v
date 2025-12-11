`timescale 1ns / 1ps

module in_buf_ctrl #(
    parameter DATA_W = 16,
    parameter ADDR_W = 17       // 480*272 = 130,560 커버
)(
    input  wire                 i_clk,
    input  wire                 i_clk_100M,
    input  wire                 i_rst_n,

    // [1] Camera Interface (Write Side)
    input  wire                 i_cam_vsync,   // Bank Switching Trigger
    input  wire                 i_wr_en,       // Write Enable
    input  wire [ADDR_W-1:0]    i_wr_addr,     // Write Address
    input  wire [DATA_W-1:0]    i_wr_data,     // Write Data

    // [2] Window Interface (Read Side)
    input  wire                 i_rd_en,       // Read Enable
    input  wire [ADDR_W-1:0]    i_rd_addr,     // Read Address
    output reg  [23:0]    o_rd_data,      // Read Data Output
    output reg            start
);

    //==========================================================================
    // 1. Bank Switching Logic
    //==========================================================================
    reg [1:0] vsync_d;      // 문법 수정: reg 배열 선언 방식 변경
    wire      vsync_edge;
    reg       wr_bank_sel;  // 0: RAM0 Write / 1: RAM1 Write
    

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            vsync_d     <= 2'b00;
            wr_bank_sel <= 1'b0; // 초기값: Bank 0부터 쓰기
            start       <= 1'b0;
        end else begin
            // VSYNC Edge Detect
            vsync_d[0] <= i_cam_vsync;
            vsync_d[1] <= vsync_d[0];
            start      <= 1'b0;
            // Edge 발생 시 Bank 상태 반전 (Toggle)
            if (vsync_edge) begin
                wr_bank_sel <= ~wr_bank_sel;
                start <=1'b1;
            end
        end
    end

    // Rising Edge 감지
    assign vsync_edge = (vsync_d[0] && ~vsync_d[1]);
    
    // cdc
    reg [1:0] wr_bank_sync;
    always @(posedge i_clk_100M or negedge i_rst_n) begin
        if (!i_rst_n)
            wr_bank_sync <= 2'b00;
        else
            wr_bank_sync <= {wr_bank_sync[0], wr_bank_sel};
    end
    
    wire wr_bank_sel_100M = wr_bank_sync[1];


    //==========================================================================
    // 2. Control Signal Demux (신호 분배)
    //==========================================================================
    
    // [RAM 0 제어 신호]
    // Write Enable: 카메라(Write)가 켜져있고 + 현재 타겟 뱅크가 0일 때
    wire ram0_wea = i_wr_en && (wr_bank_sel == 1'b0);
    
    // Read Enable: 윈도우(Read)가 켜져있고 + 현재 타겟 뱅크가 1일 때 (즉, 0은 읽기 가능)
    wire ram0_enb = i_rd_en && (wr_bank_sel_100M == 1'b1);

    // [RAM 1 제어 신호]
    // Write Enable: 카메라(Write)가 켜져있고 + 현재 타겟 뱅크가 1일 때
    wire ram1_wea = i_wr_en && (wr_bank_sel == 1'b1);
    
    // Read Enable: 윈도우(Read)가 켜져있고 + 현재 타겟 뱅크가 0일 때 (즉, 1은 읽기 가능)
    wire ram1_enb = i_rd_en && (wr_bank_sel_100M == 1'b0);


    //==========================================================================
    // 3. Instantiate TWO Memory Blocks
    //==========================================================================
    wire [DATA_W-1:0] ram0_dout;
    wire [DATA_W-1:0] ram1_dout;

    // --- RAM 0 Instance ---
    InBuf0 InBuf0 (
        // Port A (Write from Camera)
        .clka   (i_clk),
        .ena    (ram0_wea),       // 1일 때만 동작 (Power Save)
        .wea    (1'b1),           // ena가 1이면 무조건 쓰기 수행 (Xilinx IP 설정에 따라 [0:0]일수도 있음)
        .addra  (i_wr_addr),
        .dina   (i_wr_data),
        
        // Port B (Read to Window)
        .clkb   (i_clk_100M),
        .enb    (ram0_enb),       // 읽을 때만 동작
        .addrb  (i_rd_addr),
        .doutb  (ram0_dout)
    );

    // --- RAM 1 Instance ---
    InBuf1 InBuf1 (
        // Port A (Write from Camera)
        .clka   (i_clk),
        .ena    (ram1_wea),
        .wea    (1'b1),
        .addra  (i_wr_addr),
        .dina   (i_wr_data),
        
        // Port B (Read to Window)
        .clkb   (i_clk_100M),
        .enb    (ram1_enb),
        .addrb  (i_rd_addr),
        .doutb  (ram1_dout)
    );


    //==========================================================================
    // 4. Output Data Mux (Read Data Selection)
    //==========================================================================
    // 현재 카메라가 쓰고 있는 뱅크의 '반대쪽' 뱅크 데이터를 출력
    
    always @(*) begin
        if (wr_bank_sel_100M == 1'b0) begin
            // 카메라가 RAM0에 쓰는 중 -> Window는 RAM1을 읽음
            o_rd_data ={{ram1_dout[15:11], ram1_dout[15:13]},  // Red: 5bit + 상위 3bit = 8bit
                       {ram1_dout[10:5], ram1_dout[10:9]},  // Green: 6bit + 상위 2bit = 8bit
                       {ram1_dout[4:0], ram1_dout[4:2]}};   // Blue: 5bit + 상위 3b ram1_dout;
        end else begin
            // 카메라가 RAM1에 쓰는 중 -> Window는 RAM0을 읽음
            o_rd_data = {{ram0_dout[15:11], ram0_dout[15:13]},  // Red: 5bit + 상위 3bit = 8bit
                         {ram0_dout[10:5], ram0_dout[10:9]},  // Green: 6bit + 상위 2bit = 8bit
                         {ram0_dout[4:0], ram0_dout[4:2]}};
        end
    end
endmodule
