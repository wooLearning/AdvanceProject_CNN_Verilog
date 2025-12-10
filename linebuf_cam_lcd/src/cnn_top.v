module cnn_top(
	input wire iClk,
	input wire iRstButton,

	/*FOR InBuf Control*/
	output wire [16:0] inbuf_rd_addr_w,
	output oCs,
	input wire [15:0] inbuf_rd_data_w,

	/*FOR LCD OUTPUT*/
    output wire oLcdHSync,
    output wire oLcdVSync,
    output wire [4:0] oLcdR,
    output wire [5:0] oLcdG,
    output wire [4:0] oLcdB,

	// axi lite interface
	input wire [31:0] iReg0,
	input wire [31:0] iReg1,
	input wire [31:0] iReg2,
	input wire [31:0] iReg3	
);

localparam DATA_W = 24;
localparam ADDR_W = 17;
localparam WIDTH = 480;
localparam HEIGHT = 272;
localparam DEPTH  = WIDTH * HEIGHT;


wire wEnClk;
wire [15:0] wRamRdData;
wire [16:0] wRamRdAddr;

wire wValid;
wire [ADDR_W-1:0] wAddr;
wire [DATA_W-1:0] wOut0;
wire [DATA_W-1:0] wOut1;
wire [DATA_W-1:0] wOut2;
wire [DATA_W-1:0] wOut3;
wire [DATA_W-1:0] wOut4;
wire [DATA_W-1:0] wOut5;
wire [DATA_W-1:0] wOut6;
wire [DATA_W-1:0] wOut7;
wire [DATA_W-1:0] wOut8;
wire [23:0] wDataRGB88;
wire wValid1;
wire wWrEn;
wire [16:0] wRamWrAddr;
wire [15:0] wRamWrData;


assign inbuf_rd_addr_w = wAddr;
assign wPixel = {{inbuf_rd_data_w[4:0], inbuf_rd_data_w[4:2]},  // Red: 5bit + 상위 3bit = 8bit
                         {inbuf_rd_data_w[10:5], inbuf_rd_data_w[10:9]},  // Green: 6bit + 상위 2bit = 8bit
                         {inbuf_rd_data_w[15:11], inbuf_rd_data_w[15:13]}};

clk_enable en1(
    .iClk(iClk),
	.iRst(iRstButton),
	.oEnable(wEnClk)
);

Window3x3_RGB888#(
    .DATA_W(DATA_W),
	.ADDR_W(ADDR_W),
	.WIDTH(WIDTH),
	.HEIGHT(HEIGHT),
	.DEPTH(DEPTH)
)u_Window3x3_RGB888(
	.iClk(iClk),
	.iRst(iRstButton),
	.iEn(wEnClk),

	/*for inbuf Control*/
	.oCs(oCs),
	.oAddr(wAddr),
	.iPixel(wPixel),

	/*next block 3x3 pixel */
	.oOut0(wOut0),
	.oOut1(wOut1),
	.oOut2(wOut2),
	.oOut3(wOut3),
	.oOut4(wOut4),
	.oOut5(wOut5),
	.oOut6(wOut6),
	.oOut7(wOut7),
	.oOut8(wOut8),
	.oValid(wValid)
);

Conv3x3_RGB888 u_Conv3x3_RGB888(
	.iClk(iClk),
	.iRst_n(iRstButton),
	.i_enable(wValid),
	.i_Clk_en(wEnClk),
	.i_p1(wOut0),
	.i_p2(wOut1),
	.i_p3(wOut2),
	.i_p4(wOut3),
	.i_p5(wOut4),
	.i_p6(wOut5),
	.i_p7(wOut6),
	.i_p8(wOut7),
	.i_p9(wOut8),
	.i_reg0(iReg0),
	.i_reg1(iReg1),
	.i_reg2(iReg2),
	.i_reg3(iReg3),
	.o_relu_rgb(wDataRGB88),
	.o_result_valid(wValid1)
);

RGB888ToRGB565 u_RGB888ToRGB565(
	.iClk(iClk),
	.iRst_n(iRstButton),
	.i_data_rgb888(wDataRGB88),
	.i_valid(wValid1),
	.i_Clk_en(wEnClk),
	.o_addr(wRamWrAddr),
	.o_data(wRamWrData),
	.o_valid(wWrEn)
);


OufBuf_DPSram_RGB565 u_OufBuf_DPSram_RGB565(
	.iClk(iClk),
	.iRsn(iRstButton),
	.iEnClk(wEnClk),
	.iWrEn(wWrEn),
	.iWrAddr(wRamWrAddr),
	.iRdAddr(wRamRdAddr),
	.iData(wRamWrData),
	.oData(wRamRdData)
);

LcdCtrl_RGB565 u_LcdCtrl_RGB565(
	.iClk(iClk),
	.iRsn(iRstButton),
	.iEnClk(wEnClk),
	.iRamRdData(wRamRdData),
	.oRamRdAddr(wRamRdAddr),
	.oLcdHSync(oLcdHSync),
	.oLcdVSync(oLcdVSync),
	.oLcdR(oLcdR),
	.oLcdG(oLcdG),
	.oLcdB(oLcdB)
);

endmodule