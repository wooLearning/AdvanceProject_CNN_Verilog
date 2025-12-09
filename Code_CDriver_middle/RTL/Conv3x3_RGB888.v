/**
 * @brief 3x3 RGB 필터 (Parameterized) 및 3-Stage Pipelined Clipped ReLU (0~255)
 * @details V6: 커널을 signed [7:0] (8bit)로 변경,
 * MAC 누적기를 signed [19:0] (20bit)로 확장.
 */
module Conv3x3_RGB888 (
    input                 iClk,
    input                 iRst_n,

    // --- 컨트롤 신호 ---
    input                 i_enable,           // 1-cycle 펄스로 연산 시작
    input                 i_Clk_en,

    // --- 9-Pixel 윈도우 입력 ---
    input        [23:0]   i_p1, // (Top-Left)
    input        [23:0]   i_p2, // (Top-Mid)
    input        [23:0]   i_p3, // (Top-Right)
    input        [23:0]   i_p4, // (Mid-Left)
    input        [23:0]   i_p5, // (Center)
    input        [23:0]   i_p6, // (Mid-Right)
    input        [23:0]   i_p7, // (Bot-Left)
    input        [23:0]   i_p8, // (Bot-Mid)
    input        [23:0]   i_p9, // (Bot-Right)
    
    //FOR AXI
    input        [31:0]   i_reg0,
    input        [31:0]   i_reg1,
    input        [31:0]   i_reg2,
    input        [31:0]   i_reg3,

    // --- 최종 출력 ---
    output reg   [23:0]   o_relu_rgb,      // {R[7:0], G[7:0], B[7:0]}
    output reg            o_result_valid,    // 3개 결과 동시 유효
    output reg            o_busy             // FSM 동작 중 신호
);

    // [*** 변경됨: V6 ***] : 4비트 -> 8비트 커널
    parameter signed [7:0] K1_1 = 0;
    parameter signed [7:0] K2_1 = -1;
    parameter signed [7:0] K3_1 = 0;
    parameter signed [7:0] K4_1 = -1;
    parameter signed [7:0] K5_1 = 5;
    parameter signed [7:0] K6_1 = -1;
    parameter signed [7:0] K7_1 = 0;
    parameter signed [7:0] K8_1 = -1;
    parameter signed [7:0] K9_1 = 0;
   
   parameter signed [7:0] K1_2 = -1;
    parameter signed [7:0] K2_2 = -1;
    parameter signed [7:0] K3_2 = -1;
    parameter signed [7:0] K4_2 = -1;
    parameter signed [7:0] K5_2 = 9;
    parameter signed [7:0] K6_2 = -1;
    parameter signed [7:0] K7_2 = -1;
    parameter signed [7:0] K8_2 = -1;
    parameter signed [7:0] K9_2 = -1;
   
   parameter signed [7:0] K1_3 = 0;
    parameter signed [7:0] K2_3 = 0;
    parameter signed [7:0] K3_3 = 0;
    parameter signed [7:0] K4_3 = 0;
    parameter signed [7:0] K5_3 = 1;
    parameter signed [7:0] K6_3 = 0;
    parameter signed [7:0] K7_3 = 0;
    parameter signed [7:0] K8_3 = 0;
    parameter signed [7:0] K9_3 = 0;

    // --- FSM 상태 정의 ---
    localparam S_IDLE        = 4'b0001;
    localparam S_CALC_R      = 4'b0010; // R: MAC
    localparam S_CALC_G      = 4'b0011; // G: MAC, R: ReLU
    localparam S_CALC_B      = 4'b0100; // B: MAC, G: ReLU
    localparam S_WAIT_RELU_B = 4'b0101; //         B: ReLU
    localparam S_OUTPUT      = 4'b1000; // 3개 결과 출력

    reg [3:0] r_state, r_state_next;

    // --- 채널 분리 (Unsigned 8-bit) ---
    wire [7:0] ur_p1, ug_p1, ub_p1;
    wire [7:0] ur_p2, ug_p2, ub_p2;
    wire [7:0] ur_p3, ug_p3, ub_p3;
    wire [7:0] ur_p4, ug_p4, ub_p4;
    wire [7:0] ur_p5, ug_p5, ub_p5;
    wire [7:0] ur_p6, ug_p6, ub_p6;
    wire [7:0] ur_p7, ug_p7, ub_p7;
    wire [7:0] ur_p8, ug_p8, ub_p8;
    wire [7:0] ur_p9, ug_p9, ub_p9;

    assign ur_p1 = i_p1[23:16]; assign ug_p1 = i_p1[15:8]; assign ub_p1 = i_p1[7:0];
    assign ur_p2 = i_p2[23:16]; assign ug_p2 = i_p2[15:8]; assign ub_p2 = i_p2[7:0];
    assign ur_p3 = i_p3[23:16]; assign ug_p3 = i_p3[15:8]; assign ub_p3 = i_p3[7:0];
    assign ur_p4 = i_p4[23:16]; assign ug_p4 = i_p4[15:8]; assign ub_p4 = i_p4[7:0];
    assign ur_p5 = i_p5[23:16]; assign ug_p5 = i_p5[15:8]; assign ub_p5 = i_p5[7:0];
    assign ur_p6 = i_p6[23:16]; assign ug_p6 = i_p6[15:8]; assign ub_p6 = i_p6[7:0];
    assign ur_p7 = i_p7[23:16]; assign ug_p7 = i_p7[15:8]; assign ub_p7 = i_p7[7:0];
    assign ur_p8 = i_p8[23:16]; assign ug_p8 = i_p8[15:8]; assign ub_p8 = i_p8[7:0];
    assign ur_p9 = i_p9[23:16]; assign ug_p9 = i_p9[15:8]; assign ub_p9 = i_p9[7:0];

    // --- MAC 유닛 입력을 위한 MUX ---
    reg [7:0] sel_p1, sel_p2, sel_p3, sel_p4, sel_p5, sel_p6, sel_p7, sel_p8, sel_p9;

    always @(*) begin
        case (r_state)
            S_CALC_R: begin
                sel_p1 = ur_p1; sel_p2 = ur_p2; sel_p3 = ur_p3;
                sel_p4 = ur_p4; sel_p5 = ur_p5; sel_p6 = ur_p6;
                sel_p7 = ur_p7; sel_p8 = ur_p8; sel_p9 = ur_p9;
            end
            S_CALC_G: begin
                sel_p1 = ug_p1; sel_p2 = ug_p2; sel_p3 = ug_p3;
                sel_p4 = ug_p4; sel_p5 = ug_p5; sel_p6 = ug_p6;
                sel_p7 = ug_p7; sel_p8 = ug_p8; sel_p9 = ug_p9;
            end
            S_CALC_B: begin
                sel_p1 = ub_p1; sel_p2 = ub_p2; sel_p3 = ub_p3;
                sel_p4 = ub_p4; sel_p5 = ub_p5; sel_p6 = ub_p6;
                sel_p7 = ub_p7; sel_p8 = ub_p8; sel_p9 = ub_p9;
            end
            default: begin
                sel_p1 = 8'd0; sel_p2 = 8'd0; sel_p3 = 8'd0;
                sel_p4 = 8'd0; sel_p5 = 8'd0; sel_p6 = 8'd0;
                sel_p7 = 8'd0; sel_p8 = 8'd0; sel_p9 = 8'd0;
            end
        endcase
    end

 
    // --- 리소스가 공유된 단일 MAC 유닛 ---
    wire signed [19:0] w_mac_result;
   reg signed [7:0] K1,K2,K3,K4,K5,K6,K7,K8,K9;
   
   always@(*) begin
      case(i_reg0[1:0])
         2'b00: begin
               K1=K1_1; K2=K2_1; K3=K3_1;
               K4=K4_1; K5=K5_1; K6=K6_1;
               K7=K7_1; K8=K8_1; K9=K9_1;
               end
         2'b01: begin
               K1=K1_2; K2=K2_2; K3=K3_2;
               K4=K4_2; K5=K5_2; K6=K6_2;
               K7=K7_2; K8=K8_2; K9=K9_2;
               end
         2'b10: begin
               K1=K1_3; K2=K2_3; K3=K3_3;
               K4=K4_3; K5=K5_3; K6=K6_3;
               K7=K7_3; K8=K8_3; K9=K9_3;
               end
         2'b11: begin
               K1=i_reg1[7:0]; K2=i_reg1[15:8]; K3=i_reg1[23:16];
               K4=i_reg1[31:24]; K5=i_reg2[7:0]; K6=i_reg2[15:8];
               K7=i_reg2[23:16]; K8=i_reg2[31:24]; K9=i_reg3[7:0];
               end
      endcase
   end

    assign w_mac_result = ( $signed({1'b0, sel_p1}) * K1 ) + ( $signed({1'b0, sel_p2}) * K2 ) + ( $signed({1'b0, sel_p3}) * K3 ) + 
                          ( $signed({1'b0, sel_p4}) * K4 ) + ( $signed({1'b0, sel_p5}) * K5 ) + ( $signed({1'b0, sel_p6}) * K6 ) + 
                          ( $signed({1'b0, sel_p7}) * K7 ) + ( $signed({1'b0, sel_p8}) * K8 ) + ( $signed({1'b0, sel_p9}) * K9 );
                     
  
    // --- 파이프라인 중간 레지스터 (MAC 결과 저장용) ---
    reg signed [19:0] r_mac_r, r_mac_g, r_mac_b; 


    // --- 단일 ReLU 유닛 입력을 위한 MUX ---
    reg signed [19:0] r_relu_input; 

    always @(*) begin
        case (r_state)
            S_CALC_G:      r_relu_input = r_mac_r;
            S_CALC_B:      r_relu_input = r_mac_g;
            S_WAIT_RELU_B: r_relu_input = r_mac_b;
            default:       r_relu_input = 20'sd0; // 비트 폭 수정
        endcase
    end

    // --- 리소스가 공유된 단일 Clipped ReLU 유닛 ---
    wire [7:0] w_clipped_relu_result;

    assign w_clipped_relu_result = (r_relu_input < 20'sd0)   ? 8'd0 :
                                   (r_relu_input > 20'sd255) ? 8'd255 :
                                   r_relu_input[7:0]; // 0~255 사이 값이므로 하위 8비트만 사용

    // --- 최종 출력 레지스터 (ReLU 결과 저장용) ---
    reg [7:0] r_relu_r, r_relu_g, r_relu_b;


    // --- FSM Sequential Logic (State Register) ---
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            r_state <= S_IDLE;
        end 
        else if (i_Clk_en == 1'b1) begin // FSM은 Clk_en에 따라 천천히 동작
             r_state <= r_state_next;
        end
    end

    // --- FSM Combinational Logic (State Transition & Outputs) ---
    always @* begin
        // 기본값 설정
        r_state_next      = r_state; // Clk_en이 0이면 상태 유지
        o_result_valid    = 1'b0;
        o_busy            = 1'b0; 
        o_relu_rgb        = {r_relu_r, r_relu_g, r_relu_b}; 

        case (r_state)
            S_IDLE: begin
                if (i_enable) begin 
                    r_state_next = S_CALC_R;
                end
            end

            S_CALC_R: begin 
                o_busy = 1'b1; 
                r_state_next = S_CALC_G;
            end

            S_CALC_G: begin 
                o_busy = 1'b1; 
                r_state_next = S_CALC_B;
            end

            S_CALC_B: begin 
                o_busy = 1'b1; 
                r_state_next = S_WAIT_RELU_B;
            end

            S_WAIT_RELU_B: begin 
                r_state_next = S_OUTPUT;
            end
            
            S_OUTPUT: begin 
                o_result_valid = 1'b1;
                o_relu_rgb     = {r_relu_r, r_relu_g, r_relu_b}; 
                r_state_next   = S_IDLE;
            end
            
            default: begin
                r_state_next = S_IDLE;
            end
        endcase
    end

    // --- Data Pipeline Register Logic (Clock Enable V) ---
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            r_mac_r <= 20'sd0;
            r_mac_g <= 20'sd0;
            r_mac_b <= 20'sd0;
            r_relu_r <= 8'd0;
            r_relu_g <= 8'd0;
            r_relu_b <= 8'd0;
        end 
        else if (i_Clk_en == 1'b1) begin 
            
            // --- 1. MAC 결과 캡처 ---
            if (r_state == S_CALC_R) begin
                r_mac_r <= w_mac_result; 
            end
            
            if (r_state == S_CALC_G) begin
                r_mac_g <= w_mac_result;     
                r_relu_r <= w_clipped_relu_result;
            end
            
            if (r_state == S_CALC_B) begin
                r_mac_b <= w_mac_result;     
                r_relu_g <= w_clipped_relu_result;
            end
            
            if (r_state == S_WAIT_RELU_B) begin
                r_relu_b <= w_clipped_relu_result;
            end
        end
    end

endmodule