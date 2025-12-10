module cnn_top (
	input iClk,
	input iRst,


	output [23:0] oOut0,
	output [23:0] oOut1,
	output [23:0] oOut2,
	output [23:0] oOut3,
	output [23:0] oOut4,
	output [23:0] oOut5,
	output [23:0] oOut6,
	output [23:0] oOut7,
	output [23:0] oOut8,
	output oValid
);

localparam DATA_W = 24;
localparam ADDR_W = 17;
localparam WIDTH = 480;
localparam HEIGHT = 272;
localparam DEPTH  = WIDTH * HEIGHT;

wire wEn;

clk_enable en1(
    .iClk(iClk),
	.iRst(iRst),
	.oEnable(wEn)
);

wire wCs;
wire [ADDR_W-1 : 0] wAddr;
wire [DATA_W-1 : 0] wPixel;

Window3x3_RGB888#(
    .DATA_W(DATA_W),
	.ADDR_W(ADDR_W),
	.WIDTH(WIDTH),
	.HEIGHT(HEIGHT),
	.DEPTH(DEPTH)
)u_Window3x3_RGB888(
	.iClk(iClk),
	.iRst(iRst),
	.iEn(wEn),

	/*for bram*/
	.oCs(wCs),
	.oAddr(wAddr),
	.iPixel(wPixel),

	/*next block 3x3 pixel */
	.oOut0(oOut0),
	.oOut1(oOut1),
	.oOut2(oOut2),
	.oOut3(oOut3),
	.oOut4(oOut4),
	.oOut5(oOut5),
	.oOut6(oOut6),
	.oOut7(oOut7),
	.oOut8(oOut8),
	.oValid(oValid)

);

inbuf_wrapper #(
  	.DATA_W(DATA_W),
	.ADDR_W(ADDR_W),
	.DEPTH(DEPTH)
) u_InputMemory(
  	.clka  (iClk),
	.ena   (wCs),
	.wea   (1'b0),//읽기모드
	.addra (wAddr),
	.dina  (0),//읽기모드
	.douta (wPixel)
);

endmodule