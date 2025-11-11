module Window3x3_RGB888 #(
    parameter integer DATA_W      = 24,
    parameter integer ADDR_W      = 17,
    parameter integer WIDTH       = 480,
    parameter integer HEIGHT      = 272,
    parameter integer DEPTH       = 130560,
    // 0: 정상(왼→오), 1: 출력만 좌우 반전(네가 말한 out0<-out2, out3<-out5, out6<-out8 효과)
    parameter integer REVERSE_COLS = 1
)(
    input                   iClk,
    input                   iRst,      // active-low
    input                   iEn,

    /* SPSRAM / BRAM (single-port, sync read, 1-cycle latency) */
    output                  oCs,
    output [ADDR_W-1:0]     oAddr,
    input  [DATA_W-1:0]     iPixel,

    /* 3x3 window (row-major) */
    output [DATA_W-1:0]     oOut0, oOut1, oOut2,
                            oOut3, oOut4, oOut5,
                            oOut6, oOut7, oOut8,
    output                  oValid,

    input                   iBusy      // 1 = stall everything
);

    // ===========================
    // States
    // ===========================
    localparam [3:0]
      S_IDLE     = 4'd0,
      // P0 (first cell of a row): 4 reads 0,1,W+0,W+1
      S_P0_REQ0  = 4'd1,  S_P0_L0  = 4'd2,
      S_P0_REQ1  = 4'd3,  S_P0_L1  = 4'd4,
      S_P0_REQ2  = 4'd5,  S_P0_L2  = 4'd6,
      S_P0_REQ3  = 4'd7,  S_P0_L3  = 4'd8,
      // RUN (other cells): shift + reads (y,x+1),(y+1,x+1)
      S_RUN_SHIFT= 4'd9,
      S_RUN_R0   = 4'd10, S_RUN_L0 = 4'd11,
      S_RUN_R1   = 4'd12, S_RUN_L1 = 4'd13,
      S_EMIT     = 4'd14;

    // ===========================
    // Gate & coordinates
    // ===========================
    wire step_ok = iEn && !iBusy;

    reg  [3:0]        st, nx;
    reg  [15:0]       x, y;                 // current cell (0..WIDTH-1 / 0..HEIGHT-1)
    reg  [ADDR_W-1:0] base_y;               // y*WIDTH
    wire [ADDR_W-1:0] base_dn = base_y + WIDTH[ADDR_W-1:0];

    // (x+1) 안정 주소용 래치
    reg  [ADDR_W-1:0] col_next_lat;

    // ===========================
    // Line buffers (ping-pong)
    //  - top(read) : 이전 행
    //  - write     : 현재 행 저장 → 줄 끝에서 top과 스왑
    // ===========================
    reg sel_top; // 0: top=LB_A, write=LB_B / 1: top=LB_B, write=LB_A
    (* ram_style="distributed" *) reg [DATA_W-1:0] LB_A [0:WIDTH-1];
    (* ram_style="distributed" *) reg [DATA_W-1:0] LB_B [0:WIDTH-1];

    wire [DATA_W-1:0] top_xp1 =
        (x==WIDTH-1) ? {DATA_W{1'b0}} :
        (sel_top ? LB_B[x+1] : LB_A[x+1]);

    wire write_to_A = sel_top ? 1'b1 : 1'b0;

    // ===========================
    // 3×3 shift registers
    // r2_*: top (TL,TM,TR)
    // r1_*: mid (ML,MC,MR)
    // r0_*: bot (BL,BM,BR)
    // ===========================
    reg [DATA_W-1:0] r2_a, r2_b, r2_c;
    reg [DATA_W-1:0] r1_a, r1_b, r1_c;
    reg [DATA_W-1:0] r0_a, r0_b, r0_c;

    // ===========================
    // SRAM port & outputs
    // ===========================
    reg              rCs;
    reg [ADDR_W-1:0] rAddr;
    reg              rValid;

    reg [DATA_W-1:0] out0,out1,out2,out3,out4,out5,out6,out7,out8;

    assign oCs   = rCs;
    assign oAddr = rAddr;
    assign oValid= rValid;

    // 출력 매핑: REVERSE_COLS=1 이면 좌우 반전
    generate
      if (REVERSE_COLS==0) begin : GEN_NORM
        assign oOut0 = out0; assign oOut1 = out1; assign oOut2 = out2;
        assign oOut3 = out3; assign oOut4 = out4; assign oOut5 = out5;
        assign oOut6 = out6; assign oOut7 = out7; assign oOut8 = out8;
      end else begin : GEN_REV
        // (TL,TM,TR) → (TR,TM,TL), etc.
        assign oOut0 = out2; assign oOut1 = out1; assign oOut2 = out0;
        assign oOut3 = out5; assign oOut4 = out4; assign oOut5 = out3;
        assign oOut6 = out8; assign oOut7 = out7; assign oOut8 = out6;
      end
    endgenerate

    // ===========================
    // Next state
    // ===========================
    always @* begin
      nx = st;
      case (st)
        S_IDLE:        if (step_ok) nx = S_P0_REQ0;

        S_P0_REQ0:                   nx = S_P0_L0;
        S_P0_L0:                     nx = S_P0_REQ1;
        S_P0_REQ1:                   nx = S_P0_L1;
        S_P0_L1:                     nx = (y==HEIGHT-1) ? S_P0_L2 : S_P0_REQ2;
        S_P0_REQ2:                   nx = S_P0_L2;
        S_P0_L2:                     nx = (y==HEIGHT-1) ? S_EMIT : S_P0_REQ3;
        S_P0_REQ3:                   nx = S_P0_L3;
        S_P0_L3:                     nx = S_EMIT;

        S_RUN_SHIFT:                 nx = (x==WIDTH-1) ? S_EMIT : S_RUN_R0;
        S_RUN_R0:                    nx = S_RUN_L0;
        S_RUN_L0:                    nx = (y==HEIGHT-1) ? S_EMIT : S_RUN_R1;
        S_RUN_R1:                    nx = S_RUN_L1;
        S_RUN_L1:                    nx = S_EMIT;

        S_EMIT:       if (step_ok)   nx = S_RUN_SHIFT;
        default:                     nx = S_IDLE;
      endcase
    end

    integer i;
    always @(posedge iClk or negedge iRst) begin
      if (!iRst) begin
        st<=S_IDLE; rCs<=1'b0; rAddr<={ADDR_W{1'b0}}; rValid<=1'b0;
        x<=0; y<=0; base_y<={ADDR_W{1'b0}}; sel_top<=1'b0;
        col_next_lat <= {ADDR_W{1'b0}};
        {r2_a,r2_b,r2_c,r1_a,r1_b,r1_c,r0_a,r0_b,r0_c} <= {9*DATA_W{1'b0}};
        {out0,out1,out2,out3,out4,out5,out6,out7,out8} <= {9*DATA_W{1'b0}};
        for (i=0;i<WIDTH;i=i+1) begin LB_A[i]<={DATA_W{1'b0}}; LB_B[i]<={DATA_W{1'b0}}; end
      end else begin
        // 기본(스톨/정지): 레지스터 유지, oCs=0, oValid=0
        if (step_ok) st <= nx;
        rCs    <= 1'b0;
        rValid <= 1'b0;

        case (st)
          // ---------- P0 ----------
          S_P0_REQ0: if (step_ok) begin
            rCs   <= 1'b1;
            rAddr <= base_y + 0;                     // (y,0)
          end
          S_P0_L0: if (step_ok) begin
            r1_a <= {DATA_W{1'b0}};                  // ML (left pad)
            r1_b <= iPixel;                          // MC = (y,0)
            if (write_to_A) LB_A[0] <= iPixel; else LB_B[0] <= iPixel;
          end

          S_P0_REQ1: if (step_ok) begin
            rCs   <= 1'b1;
            rAddr <= base_y + ((WIDTH>1)?1:0);       // (y,1)
          end
          S_P0_L1: if (step_ok) begin
            r1_c <= (WIDTH>1) ? iPixel : {DATA_W{1'b0}};  // MR = (y,1)
            if (WIDTH>1) begin
              if (write_to_A) LB_A[1] <= iPixel; else LB_B[1] <= iPixel;
            end
            // top row from previous line
            r2_a <= {DATA_W{1'b0}};                                           // TL
            r2_b <= (y==0) ? {DATA_W{1'b0}} : (sel_top ? LB_B[0] : LB_A[0]);  // TM
            r2_c <= (y==0) ? {DATA_W{1'b0}} :
                     (WIDTH>1 ? (sel_top ? LB_B[1] : LB_A[1]) : {DATA_W{1'b0}}); // TR
            // 첫 RUN에서 사용할 x+1 래치 = 1
            col_next_lat <= (WIDTH==1) ? {ADDR_W{1'b0}} : {{(ADDR_W-1){1'b0}},1'b1};
          end

          S_P0_REQ2: if (step_ok) begin
            rCs   <= 1'b1;
            rAddr <= base_dn + 0;                    // (y+1,0)
          end
          S_P0_L2: if (step_ok) begin
            r0_a <= {DATA_W{1'b0}};                                   // BL
            r0_b <= (y==HEIGHT-1) ? {DATA_W{1'b0}} : iPixel;          // BM
          end

          S_P0_REQ3: if (step_ok) begin
            rCs   <= 1'b1;
            rAddr <= base_dn + ((WIDTH>1)?1:0);       // (y+1,1)
          end
          S_P0_L3: if (step_ok) begin
            r0_c <= (y==HEIGHT-1) ? {DATA_W{1'b0}} :
                    (WIDTH>1 ? iPixel : {DATA_W{1'b0}});               // BR
          end

          // ---------- RUN ----------
          S_RUN_SHIFT: if (step_ok) begin
            // 표준 좌쉬프트 (a←b, b←c, c←새열)
            r2_a<=r2_b; r2_b<=r2_c;
            r1_a<=r1_b; r1_b<=r1_c;
            r0_a<=r0_b; r0_b<=r0_c;

            // 새 TR은 라인버퍼에서 (y-1, x+1)
            r2_c <= (y==0 || x==WIDTH-1) ? {DATA_W{1'b0}} : top_xp1;

            // 다음 칸 주소 래치 (x+1)
            col_next_lat <= (x==WIDTH-1) ? {ADDR_W{1'b0}} : (x + 16'd1);
          end

          S_RUN_R0: if (step_ok) begin
            rCs   <= 1'b1;
            rAddr <= base_y + col_next_lat;           // (y,   x+1)
          end
          S_RUN_L0: if (step_ok) begin
            if (x==WIDTH-1) r1_c <= {DATA_W{1'b0}};
            else begin
              r1_c <= iPixel;                          // MR = (y,x+1)
              if (write_to_A) LB_A[col_next_lat] <= iPixel;
              else            LB_B[col_next_lat] <= iPixel;
            end
          end

          S_RUN_R1: if (step_ok) begin
            rCs   <= 1'b1;
            rAddr <= base_dn + col_next_lat;          // (y+1, x+1)
          end
          S_RUN_L1: if (step_ok) begin
            r0_c <= (x==WIDTH-1 || y==HEIGHT-1) ? {DATA_W{1'b0}} : iPixel; // BR
          end

          // ---------- EMIT ----------
          S_EMIT: if (step_ok) begin
            // 고정 매핑(내부 기준): TL..TR, ML..MR, BL..BR
            {out0,out1,out2, out3,out4,out5, out6,out7,out8} <=
              {r2_a,r2_b,r2_c, r1_a,r1_b,r1_c, r0_a,r0_b,r0_c};

            rValid <= 1'b1; // 같은 사이클 valid

            // 좌표 진행 및 라인버퍼 스왑
            if (x == WIDTH-1) begin
              x <= 16'd0;
              if (y == HEIGHT-1) begin
                y      <= 16'd0;
                base_y <= {ADDR_W{1'b0}};
              end else begin
                y      <= y + 16'd1;
                base_y <= base_y + WIDTH[ADDR_W-1:0];
              end
              sel_top <= ~sel_top; // 방금 저장한 라인이 다음 줄의 top으로 “살아있음”
            end else begin
              x <= x + 16'd1;
            end
          end

          default: ;
        endcase
      end
    end

endmodule
