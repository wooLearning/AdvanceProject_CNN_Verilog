`timescale 1ns/1ps

module cnn_top_tb;

    localparam ADDR_W = 17;
    localparam DATA_W = 24;
    localparam DEPTH  = 130560;

	reg iClk;
	reg iRst;
	reg iBusy;

	wire [23:0] oOut0;
	wire [23:0] oOut1;
	wire [23:0] oOut2;
	wire [23:0] oOut3;
	wire [23:0] oOut4;
	wire [23:0] oOut5;
	wire [23:0] oOut6;
	wire [23:0] oOut7;
	wire [23:0] oOut8;
	wire oValid;

    cnn_top cnn_top(
		.iClk(iClk),
		.iRst(iRst),
        .iBusy(iBusy),

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

    // 100 MHz clock
    initial begin
        iClk = 1'b0;
        forever #5 iClk = ~iClk; // 10ns period
    end

    
    initial begin
		// reset
        iRst = 1'b0;
        repeat(10) @(posedge iClk);
        iRst = 1'b1;
		
		repeat(10) @(posedge iClk);
		iBusy = 1'b0;
    end
	
endmodule
