module Window3x3_RGB888#(
	parameter DATA_W = 24,
	parameter ADDR_W = 17,
	parameter WIDTH = 480,
	parameter HEIGHT = 272,
	parameter DEPTH  = 130560
)(
	input iClk,
	input iRst,
	input iEn,

	/*for bram*/
	output oCs,
	output [ADDR_W-1 : 0] oAddr,
	input  [DATA_W-1 : 0] iPixel,

	/*next block 3x3 pixel */
	output [DATA_W-1:0] oOut0,
	output [DATA_W-1:0] oOut1,
	output [DATA_W-1:0] oOut2,
	output [DATA_W-1:0] oOut3,
	output [DATA_W-1:0] oOut4,
	output [DATA_W-1:0] oOut5,
	output [DATA_W-1:0] oOut6,
	output [DATA_W-1:0] oOut7,
	output [DATA_W-1:0] oOut8,
	output oValid
	
);

//fsm
localparam IDLE = 4'd0;
localparam FIRST_ROW_FILL = 4'd1;
localparam FIRST_ROW_FILL_END = 4'd2;
localparam FIRST_ROW = 4'd3;
localparam FIRST_ROW_END = 4'd4;
localparam MIDDLE_ROW = 4'd5;
localparam MIDDLE_ROW_END = 4'd6;
localparam LAST_ROW = 4'd7;
reg [3:0] cur_state;
reg [3:0] nxt_state;

//reg
reg [ADDR_W-1:0] rAddr;
reg [ADDR_W -1 : 0] rAddr_d1;
reg [ADDR_W -1 : 0] rAddr_d2;

reg [$clog2(WIDTH) -1 : 0] rColCnt;
reg [$clog2(WIDTH) -1 : 0] rColCnt_d0;
reg [$clog2(WIDTH) -1 : 0] rColCnt_d1;
reg [$clog2(HEIGHT) -1 : 0] rRowCnt;

reg [DATA_W-1:0] rLineBuf0 [0:WIDTH-1]; 
reg [DATA_W-1:0] rLineBuf1 [0:WIDTH-1];
reg [DATA_W-1:0] rPix[0:3];
reg [1:0] rPixCnt;

//wire
wire wColEnd;
wire wRowEnd;
wire wOValid = (cur_state != FIRST_ROW_FILL) && (cur_state != FIRST_ROW_FILL_END)
			&&(cur_state != IDLE) ? 1 : 0;


//part1
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		cur_state <= IDLE;
	end
	else if(iEn == 1'b1)begin
		cur_state <= nxt_state;
	end
	else begin
		cur_state <= cur_state;
	end
end

//part2
always @(*) begin
	case (cur_state)
		IDLE: begin
			if(iEn == 1'b1) nxt_state = FIRST_ROW_FILL; else nxt_state = IDLE;
		end 
		FIRST_ROW_FILL : begin
			if(rAddr_d2 == WIDTH - 1) nxt_state = FIRST_ROW_FILL_END; else nxt_state = FIRST_ROW_FILL;
		end
		FIRST_ROW_FILL_END : begin
			if(rPixCnt == 1) nxt_state = FIRST_ROW; else nxt_state = FIRST_ROW_FILL_END;
		end
		FIRST_ROW: begin
			if(wColEnd) nxt_state = FIRST_ROW_END; else nxt_state = FIRST_ROW;
		end
		FIRST_ROW_END: begin
			if(rPixCnt == 1) nxt_state = MIDDLE_ROW; else nxt_state = FIRST_ROW_END;
		end
		MIDDLE_ROW : begin
			if(wColEnd) nxt_state = MIDDLE_ROW_END; else nxt_state = MIDDLE_ROW;
		end
		MIDDLE_ROW_END : begin
			if(rPixCnt == 1) begin
				nxt_state = MIDDLE_ROW;
				if(rRowCnt == HEIGHT -1)begin
					nxt_state =LAST_ROW;
				end 
			end
			else nxt_state = MIDDLE_ROW_END;
		end
		LAST_ROW: begin
			if(wColEnd) nxt_state = IDLE; else nxt_state = LAST_ROW;
		end
		default:nxt_state = IDLE; 
	endcase
end

integer i;

//rAddr Counter
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rAddr <= 0;
	end
	else if(iEn == 1'b1)begin
		if(rAddr == (WIDTH*HEIGHT - 1)) begin
			rAddr <= 0;
		end
		else if(cur_state == IDLE || cur_state == LAST_ROW) begin
			rAddr <= 0;
		end
		else begin
			rAddr <= rAddr + 1'b1;
		end
	end
	else begin
		rAddr <= rAddr;
	end
end

// rAddr (Delay용)
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rAddr_d1 <= 0;
		rAddr_d2 <= 0;
	end
	else if(cur_state == IDLE) begin
		rAddr_d1 <= 0;
		rAddr_d2 <= 0;
	end
	else if(iEn == 1'b1) begin
		rAddr_d1 <= rAddr;
		rAddr_d2 <= rAddr_d1;
	end
end

//rColCnt Counter columm counter
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rColCnt <= 0;
	end 
	else if (wOValid && iEn == 1'b1) begin
		if (wColEnd) begin
			rColCnt <= 0;
		end
		else begin
			rColCnt <= rColCnt + 1'b1;
		end
	end
end

//Column counter Delay register
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rColCnt_d0 <= 0;
		rColCnt_d1 <= 0;
	end 
	else if (iEn == 1'b1) begin
		rColCnt_d0 <= rColCnt;
		rColCnt_d1 <= rColCnt_d0;
	end
end

//rRowCnt Row Counter
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rRowCnt <= 0;
	end 
	else if (wOValid && iEn == 1'b1) begin
		if (rRowCnt == HEIGHT) begin
			rRowCnt <= 0;
		end
		else if(wColEnd) begin //timing 봐야함
			rRowCnt <= rRowCnt + 1'b1;
		end
	end
end

//line buf rPix rPixCnt
always @(posedge iClk or negedge iRst) begin
	if(!iRst)begin
		for(i=0;i<4;i=i+1) begin
			rPix[i] <= 0;
		end
	end
	else if(iEn == 1'b1) begin

		case (cur_state)
			IDLE : begin
				rPixCnt <= 0;
			end
			FIRST_ROW_FILL: begin
				rLineBuf1[rAddr_d2] <= iPixel;
			end 
			FIRST_ROW_FILL_END: begin
				if(rPixCnt == 1) begin
					rPixCnt <= 0;
				end
				else begin
					rPixCnt <= rPixCnt + 1;
				end
				rPix[3] <= iPixel;
				for(i=3;i>=1; i=i-1) begin
					rPix[i-1] <= rPix[i];
				end
			end
			FIRST_ROW_END, 
			MIDDLE_ROW_END :begin
				if(rPixCnt == 1) begin
					rPixCnt <= 0;
				end
				else begin
					rPixCnt <= rPixCnt + 1;
				end
				
				rPix[3] <= iPixel;
				for(i=3;i>=1; i=i-1) begin
					rPix[i-1] <= rPix[i];
				end
				rLineBuf0[rColCnt_d1] <= rLineBuf1[rColCnt_d1];
				rLineBuf1[rColCnt_d1] <= rPix[0];
			end
			default: begin
				rPix[3] <= iPixel;
				for(i=3;i>=1; i=i-1) begin
					rPix[i-1] <= rPix[i];
				end
				if(rColCnt >= 2)begin
					rLineBuf0[rColCnt_d1] <= rLineBuf1[rColCnt_d1];
					rLineBuf1[rColCnt_d1] <= rPix[0];
				end 
			end

		endcase
	end
end

/*Output Mux*/
assign oOut0 = (cur_state == FIRST_ROW) ? 0 : 
				 (rColCnt == 0) ? 0 : rLineBuf0[rColCnt-1];
assign oOut1 = (cur_state == FIRST_ROW) ? 0 : rLineBuf0[rColCnt];
assign oOut2 = (cur_state == FIRST_ROW) || wColEnd ? 0 : rLineBuf0[rColCnt+1];

assign oOut3 = (rColCnt == 0) ? 0 : rLineBuf1[rColCnt-1];
assign oOut4 = rLineBuf1[rColCnt];
assign oOut5 = wColEnd ? 0: rLineBuf1[rColCnt+1];

assign oOut6 = (wRowEnd) ? 0 : 
				 (rColCnt == 0) ? 0 : rPix[1];
assign oOut7 = (wRowEnd) ? 0 :rPix[2];
assign oOut8 = (wRowEnd) || wColEnd ? 0 :rPix[3];

//End Signal
assign wColEnd = (rColCnt == WIDTH-1);
assign wRowEnd = (rRowCnt == HEIGHT-1);

//Valid Siganl
assign oValid = wOValid;

//For Bram
assign oCs = iEn && !((cur_state == IDLE)) && !((cur_state == LAST_ROW));
assign oAddr = rAddr;

endmodule