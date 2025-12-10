/**
 * @brief 3x3 RGB888 Fully Parallel Convolution with AXI Kernel Select
 * @details
 * - Architecture: Fully Parallel & Pipelined (No FSM)
 * - Resources: 27 Multipliers (9*3), 3 Parallel ReLUs
 * - Latency: 1 Clock
 * - Kernel Selection: Controlled by i_reg0[1:0] (00, 01, 10: Presets, 11: User Custom)
 */
module Conv3x3_RGB888 (
    input                 iClk,
    input                 iRst_n,

    // --- 컨트롤 신호 ---
    input                 i_enable,     // 입력 데이터 유효 신호
    input                 i_Clk_en,

    // --- 9-Pixel 윈도우 입력 (24bit RGB) ---
    input        [23:0]   i_p1, i_p2, i_p3,
    input        [23:0]   i_p4, i_p5, i_p6,
    input        [23:0]   i_p7, i_p8, i_p9,
    
    // --- AXI Register (Kernel Selection) ---
    input        [31:0]   i_reg0,       // [1:0] Mode Select
    input        [31:0]   i_reg1,       // Custom Kernel K1~K4
    input        [31:0]   i_reg2,       // Custom Kernel K5~K8
    input        [31:0]   i_reg3,       // Custom Kernel K9

    // --- 최종 출력 ---
    output reg   [23:0]   o_relu_rgb,   // {R, G, B} Result
    output reg            o_result_valid
);

    //==========================================================================
    // 1. Kernel Parameter Presets
    //==========================================================================
    // Preset 1: Sharpening (Standard)
    parameter signed [7:0] K1_1 = 0,  K2_1 = -1, K3_1 = 0;
    parameter signed [7:0] K4_1 = -1, K5_1 = 5,  K6_1 = -1;
    parameter signed [7:0] K7_1 = 0,  K8_1 = -1, K9_1 = 0;
   
    // Preset 2: Strong Sharpening (Edge Enhance)
    parameter signed [7:0] K1_2 = -1, K2_2 = -1, K3_2 = -1;
    parameter signed [7:0] K4_2 = -1, K5_2 = 9,  K6_2 = -1;
    parameter signed [7:0] K7_2 = -1, K8_2 = -1, K9_2 = -1;
   
    // Preset 3: Identity (No Change)
    parameter signed [7:0] K1_3 = 0,  K2_3 = 0,  K3_3 = 0;
    parameter signed [7:0] K4_3 = 0,  K5_3 = 1,  K6_3 = 0;
    parameter signed [7:0] K7_3 = 0,  K8_3 = 0,  K9_3 = 0;

    //==========================================================================
    // 2. Kernel Selection Logic (MUX)
    //==========================================================================
    reg signed [7:0] K1, K2, K3, K4, K5, K6, K7, K8, K9;

    always @(*) begin
        case(i_reg0[1:0])
            2'b00: begin // Preset 1
                K1=K1_1; K2=K2_1; K3=K3_1;
                K4=K4_1; K5=K5_1; K6=K6_1;
                K7=K7_1; K8=K8_1; K9=K9_1;
            end
            2'b01: begin // Preset 2
                K1=K1_2; K2=K2_2; K3=K3_2;
                K4=K4_2; K5=K5_2; K6=K6_2;
                K7=K7_2; K8=K8_2; K9=K9_2;
            end
            2'b10: begin // Preset 3
                K1=K1_3; K2=K2_3; K3=K3_3;
                K4=K4_3; K5=K5_3; K6=K6_3;
                K7=K7_3; K8=K8_3; K9=K9_3;
            end
            2'b11: begin // Custom (User Defined via AXI)
                K1=i_reg1[7:0];   K2=i_reg1[15:8];  K3=i_reg1[23:16];
                K4=i_reg1[31:24]; K5=i_reg2[7:0];   K6=i_reg2[15:8];
                K7=i_reg2[23:16]; K8=i_reg2[31:24]; K9=i_reg3[7:0];
            end
            default: begin
                 K1=K1_3; K2=K2_3; K3=K3_3;
                 K4=K4_3; K5=K5_3; K6=K6_3;
                 K7=K7_3; K8=K8_3; K9=K9_3;
            end
        endcase
    end

    //==========================================================================
    // 3. Input Unpacking (Channel Separation)
    //==========================================================================
    // R Channel Pixels
    wire [7:0] r1 = i_p1[23:16], r2 = i_p2[23:16], r3 = i_p3[23:16];
    wire [7:0] r4 = i_p4[23:16], r5 = i_p5[23:16], r6 = i_p6[23:16];
    wire [7:0] r7 = i_p7[23:16], r8 = i_p8[23:16], r9 = i_p9[23:16];

    // G Channel Pixels
    wire [7:0] g1 = i_p1[15:8],  g2 = i_p2[15:8],  g3 = i_p3[15:8];
    wire [7:0] g4 = i_p4[15:8],  g5 = i_p5[15:8],  g6 = i_p6[15:8];
    wire [7:0] g7 = i_p7[15:8],  g8 = i_p8[15:8],  g9 = i_p9[15:8];

    // B Channel Pixels
    wire [7:0] b1 = i_p1[7:0],   b2 = i_p2[7:0],   b3 = i_p3[7:0];
    wire [7:0] b4 = i_p4[7:0],   b5 = i_p5[7:0],   b6 = i_p6[7:0];
    wire [7:0] b7 = i_p7[7:0],   b8 = i_p8[7:0],   b9 = i_p9[7:0];

    //==========================================================================
    // 4. Parallel MAC (27 Multipliers Total)
    //==========================================================================
    wire signed [19:0] w_sum_r;
    wire signed [19:0] w_sum_g;
    wire signed [19:0] w_sum_b;

    // R Channel MAC (9 Multipliers) 
    assign w_sum_r = ($signed({1'b0, r1}) * K1) + ($signed({1'b0, r2}) * K2) + ($signed({1'b0, r3}) * K3) +
                     ($signed({1'b0, r4}) * K4) + ($signed({1'b0, r5}) * K5) + ($signed({1'b0, r6}) * K6) +
                     ($signed({1'b0, r7}) * K7) + ($signed({1'b0, r8}) * K8) + ($signed({1'b0, r9}) * K9);

    // G Channel MAC (9 Multipliers)
    assign w_sum_g = ($signed({1'b0, g1}) * K1) + ($signed({1'b0, g2}) * K2) + ($signed({1'b0, g3}) * K3) +
                     ($signed({1'b0, g4}) * K4) + ($signed({1'b0, g5}) * K5) + ($signed({1'b0, g6}) * K6) +
                     ($signed({1'b0, g7}) * K7) + ($signed({1'b0, g8}) * K8) + ($signed({1'b0, g9}) * K9);

    // B Channel MAC (9 Multipliers)
    assign w_sum_b = ($signed({1'b0, b1}) * K1) + ($signed({1'b0, b2}) * K2) + ($signed({1'b0, b3}) * K3) +
                     ($signed({1'b0, b4}) * K4) + ($signed({1'b0, b5}) * K5) + ($signed({1'b0, b6}) * K6) +
                     ($signed({1'b0, b7}) * K7) + ($signed({1'b0, b8}) * K8) + ($signed({1'b0, b9}) * K9);

    //==========================================================================
    // 5. Parallel ReLU (3 Units)
    //==========================================================================
    
    // ReLU Function definition
    function [7:0] func_relu;
        input signed [19:0] value;
        begin
            if (value < 20'sd0)        func_relu = 8'd0;
            else if (value > 20'sd255) func_relu = 8'd255;
            else                       func_relu = value[7:0];
        end
    endfunction

    // 3 Channels processed simultaneously
    wire [7:0] w_relu_r = func_relu(w_sum_r);
    wire [7:0] w_relu_g = func_relu(w_sum_g);
    wire [7:0] w_relu_b = func_relu(w_sum_b);

    //==========================================================================
    // 6. Output Stage (Pipelined)
    //==========================================================================
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            o_relu_rgb     <= 24'd0;
            o_result_valid <= 1'b0;
        end else if (i_Clk_en) begin
            // Pipeline Register: Input valid -> Output valid (1 cycle delay)
            o_result_valid <= i_enable;

            if (i_enable) begin
                o_relu_rgb <= {w_relu_r, w_relu_g, w_relu_b};
            end
        end
    end

endmodule