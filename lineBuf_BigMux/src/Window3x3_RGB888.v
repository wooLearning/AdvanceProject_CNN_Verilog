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

//bit 잘 분배해서 end idle만 해서 1bit 비교 가능?
localparam IDLE = 4'd0;
localparam FIRST_ROW = 4'd1;
localparam FIRST_ROW_END = 4'd2;
localparam ODD_ROW= 4'd3;
localparam ODD_ROW_END= 4'd4;
localparam EVEN_ROW = 4'd5;
localparam EVEN_ROW_END = 4'd6;
localparam LAST_ROW = 4'd7;

//fsm
reg [3:0] cur_state;
reg [3:0] nxt_state;
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
			if(iEn == 1'b1) nxt_state = FIRST_ROW; else nxt_state = IDLE;
		end 
		FIRST_ROW: begin
			if(wColEnd) nxt_state = FIRST_ROW_END; else nxt_state = FIRST_ROW;
		end
		FIRST_ROW_END : begin
			if(rPixCnt == 0) nxt_state = ODD_ROW; else nxt_state = FIRST_ROW_END;
		end
		ODD_ROW: begin
			if(wColEnd) nxt_state = ODD_ROW_END; else nxt_state = ODD_ROW;
		end
		ODD_ROW_END: begin
			if(wRowEnd) nxt_state = LAST_ROW; else nxt_state = EVEN_ROW;
		end
		EVEN_ROW: begin
			if(wColEnd) nxt_state = EVEN_ROW_END; else nxt_state = EVEN_ROW;
		end
		EVEN_ROW_END: begin
			if(wRowEnd) nxt_state = LAST_ROW; else nxt_state = ODD_ROW;
		end
		LAST_ROW: begin
			if(wColEnd) nxt_state = IDLE; else nxt_state = LAST_ROW;
		end
		default:nxt_state = IDLE; 
	endcase
end

integer i;

reg [ADDR_W-1:0] rAddr;
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rAddr <= 0;
	end
	else if(iEn == 1'b1)begin
		if(rAddr == (WIDTH*HEIGHT - 1)) begin
			rAddr <= 0;
		end
		else if(cur_state == IDLE) begin
			rAddr <= 0;
		end
		else if(cur_state != FIRST_ROW_END 
			&& cur_state != ODD_ROW_END 
			&& cur_state != EVEN_ROW_END && iEn == 1'b1)begin
			rAddr <= rAddr + 1'b1;
		end
	end
	else begin
		rAddr <= rAddr;
	end
end

// 파이프라인 레지스터 (Delay용)
reg [ADDR_W -1 : 0] rAddr_d1;
reg [ADDR_W -1 : 0] rAddr_d2;
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

wire wColEnd = (rColCnt == WIDTH-1);
wire wRowEnd = (rRowCnt == HEIGHT-1);

reg [$clog2(WIDTH) -1 : 0] rColCnt;

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

reg [$clog2(HEIGHT) -1 : 0] rRowCnt;
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

integer i;
reg [DATA_W-1:0] rLineBuf0 [0:WIDTH-1]; 
reg [DATA_W-1:0] rLineBuf1 [0:WIDTH-1];
reg [DATA_W-1:0] rPix[0:2];
reg [2:0] rPixCnt;

always @(posedge iClk or negedge iRst) begin
	if(!iRst)begin
		for (i=0; i<WIDTH;i=i+1 ) begin
			rLineBuf0[i] <= 0;
			rLineBuf1[i] <= 0;
		end
		for(i=0;i<3;i=i+1) begin
			rPix[i] <= 0;
		end
		rPixCnt <= 0;
	end
	else if(iEn == 1'b1) begin
		case (cur_state)
			IDLE : begin
				rPixCnt <= 0;
			end
			FIRST_ROW: begin
				if(rAddr_d2 <= WIDTH -1) begin
					rLineBuf0[WIDTH-1] <= iPixel;
					for(i=WIDTH-2; i>=0; i=i-1) begin
						rLineBuf0[i] <= rLineBuf0[i+1];
					end
				end
				else begin// if(rAddr_d2 <= WIDTH * 2 -1)
					rPix[2] <= iPixel;
					rPix[1] <= rPix[2];
					rPix[0] <= rPix[1];
					rLineBuf1[WIDTH-1] <= rPix[0];
					for(i=WIDTH-2; i>=0; i=i-1) begin
						rLineBuf1[i] <= rLineBuf1[i+1];
					end
					//First rPixcnt
					if(wColEnd) begin
						rPixCnt <= 0;
					end
					else if(rPixCnt == 4) begin
						rPixCnt <= rPixCnt;
					end
					else begin
						rPixCnt <= rPixCnt +1;
					end	
				end		
			end 

			FIRST_ROW_END: begin
				rLineBuf1[WIDTH-1] <= rPix[0];
				for(i=WIDTH-2; i>=0; i=i-1) begin
					rLineBuf1[i] <= rLineBuf1[i+1];
				end
			end

			ODD_ROW: begin
				rPix[2] <= iPixel;
				rPix[1] <= rPix[2];
				rPix[0] <= rPix[1];
				if(rColCnt >= 1) begin
					rLineBuf0[rColCnt - 1] <= rPix[0];
				end
			end

			ODD_ROW_END: begin
				rLineBuf0[WIDTH -1] <= rPix[0];
			end

			EVEN_ROW: begin
				rPix[2] <= iPixel;
				rPix[1] <= rPix[2];
				rPix[0] <= rPix[1];
				if(rColCnt >= 1) begin
					rLineBuf1[rColCnt - 1] <= rPix[0];
				end
			end

			EVEN_ROW_END: begin
				rLineBuf1[WIDTH -1] <= rPix[0];
			end
		endcase
	end
end

reg wOValid;//그지같이 해놓음 코드 깔끔하게 하기
reg [DATA_W-1:0] wOut[0:8];
//part3
always @(*) begin
	case (cur_state)

		FIRST_ROW: begin
			wOut[0] = 0;
			wOut[1] = 0;
			wOut[2] = 0;
			if(rPixCnt >= 2) begin
				wOValid = 1;
			end
			else begin 
				wOValid = 0;	
			end
			if(rPixCnt == 2) begin
				wOut[3] = 0;
				wOut[4] = rLineBuf0[rColCnt];
				wOut[5] = rLineBuf0[rColCnt+1];
				wOut[6] = 0;
				wOut[7] = rPix[1];
				wOut[8] = rPix[2];
			end
			else if(rColCnt == WIDTH - 1) begin
				wOut[3] = rLineBuf0[rColCnt-1];
				wOut[4] = rLineBuf0[rColCnt];
				wOut[5] = 0;
				wOut[6] = rPix[0];
				wOut[7] = rPix[1];
				wOut[8] = 0;
			end
			else if(rPixCnt >= 3)begin
				wOut[3] = rLineBuf0[rColCnt-1];
				wOut[4] = rLineBuf0[rColCnt];
				wOut[5] = rLineBuf0[rColCnt+1];
				wOut[6] = rPix[0];
				wOut[7] = rPix[1];
				wOut[8] = rPix[2];
			end
		end

		ODD_ROW: begin
			wOValid = 1;
			if(rColCnt == 0) begin
				wOut[0] = 0;
				wOut[1] = rLineBuf0[rColCnt];
				wOut[2] = rLineBuf0[rColCnt+1];
				wOut[3] = 0;
				wOut[4] = rLineBuf1[rColCnt];
				wOut[5] = rLineBuf1[rColCnt+1];
				wOut[6] = 0;
				wOut[7] = rPix[1];
				wOut[8] = rPix[2];
			end
			else if(rColCnt == WIDTH -1) begin
				wOut[0] = rLineBuf0[rColCnt-1];
				wOut[1] = rLineBuf0[rColCnt];
				wOut[2] = 0;
				wOut[3] = rLineBuf1[rColCnt-1];
				wOut[4] = rLineBuf1[rColCnt];
				wOut[5] = 0;
				wOut[6] = rPix[0];
				wOut[7] = rPix[1];
				wOut[8] = 0;
			end
			else begin
				wOut[0] = rLineBuf0[rColCnt-1];
				wOut[1] = rLineBuf0[rColCnt];
				wOut[2] = rLineBuf0[rColCnt+1];
				wOut[3] = rLineBuf1[rColCnt-1];
				wOut[4] = rLineBuf1[rColCnt];
				wOut[5] = rLineBuf1[rColCnt+1];
				wOut[6] = rPix[0];
				wOut[7] = rPix[1];
				wOut[8] = rPix[2];
			end
		end

		EVEN_ROW: begin
			wOValid = 1;
			if(rColCnt == 0) begin
				wOut[0] = 0;
				wOut[1] = rLineBuf1[rColCnt];
				wOut[2] = rLineBuf1[rColCnt+1];
				wOut[3] = 0;
				wOut[4] = rLineBuf0[rColCnt];
				wOut[5] = rLineBuf0[rColCnt+1];
				wOut[6] = 0;
				wOut[7] = rPix[1];
				wOut[8] = rPix[2];
			end
			else if(rColCnt == WIDTH -1) begin
				wOut[0] = rLineBuf1[rColCnt-1];
				wOut[1] = rLineBuf1[rColCnt];
				wOut[2] = 0;
				wOut[3] = rLineBuf0[rColCnt-1];
				wOut[4] = rLineBuf0[rColCnt];
				wOut[5] = 0;
				wOut[6] = rPix[0];
				wOut[7] = rPix[1];
				wOut[8] = 0;
			end
			else begin
				wOut[0] = rLineBuf1[rColCnt-1];
				wOut[1] = rLineBuf1[rColCnt];
				wOut[2] = rLineBuf1[rColCnt+1];
				wOut[3] = rLineBuf0[rColCnt-1];
				wOut[4] = rLineBuf0[rColCnt];
				wOut[5] = rLineBuf0[rColCnt+1];
				wOut[6] = rPix[0];
				wOut[7] = rPix[1];
				wOut[8] = rPix[2];
			end
		end

		LAST_ROW: begin
			wOValid = 1;
			wOut[6] = 0;
			wOut[7] = 0;
			wOut[8] = 0;
			if(rRowCnt[0] == 0) begin
				if(rColCnt == 0) begin
					wOut[0] = 0;
					wOut[1] = rLineBuf1[rColCnt];
					wOut[2] = rLineBuf1[rColCnt+1];
					wOut[3] = 0;
					wOut[4] = rLineBuf0[rColCnt];
					wOut[5] = rLineBuf0[rColCnt+1];
				end
				else if(rColCnt == WIDTH -1) begin
					wOut[0] = rLineBuf1[rColCnt-1];
					wOut[1] = rLineBuf1[rColCnt];
					wOut[2] = 0;
					wOut[3] = rLineBuf0[rColCnt-1];
					wOut[4] = rLineBuf0[rColCnt];
					wOut[5] = 0;
				end
				else begin
					wOut[0] = rLineBuf1[rColCnt-1];
					wOut[1] = rLineBuf1[rColCnt];
					wOut[2] = rLineBuf1[rColCnt+1];
					wOut[3] = rLineBuf0[rColCnt-1];
					wOut[4] = rLineBuf0[rColCnt];
					wOut[5] = rLineBuf0[rColCnt+1];
				end
			end
			else begin
				if(rColCnt == 0) begin
					wOut[0] = 0;
					wOut[1] = rLineBuf0[rColCnt];
					wOut[2] = rLineBuf0[rColCnt+1];
					wOut[3] = 0;
					wOut[4] = rLineBuf1[rColCnt];
					wOut[5] = rLineBuf1[rColCnt+1];
				end
				else if(rColCnt == WIDTH -1) begin
					wOut[0] = rLineBuf0[rColCnt-1];
					wOut[1] = rLineBuf0[rColCnt];
					wOut[2] = 0;
					wOut[3] = rLineBuf1[rColCnt-1];
					wOut[4] = rLineBuf1[rColCnt];
					wOut[5] = 0;
				end
				else begin
					wOut[0] = rLineBuf0[rColCnt-1];
					wOut[1] = rLineBuf0[rColCnt];
					wOut[2] = rLineBuf0[rColCnt+1];
					wOut[3] = rLineBuf1[rColCnt-1];
					wOut[4] = rLineBuf1[rColCnt];
					wOut[5] = rLineBuf1[rColCnt+1];
				end
			end
		end
		default: begin
			wOValid = 0;
			for(i=0;i<9;i=i+1) begin
				wOut[i] = 0;
			end
		end
	endcase
end

assign oOut0 = wOut[0];
assign oOut1 = wOut[1];
assign oOut2 = wOut[2];
assign oOut3 = wOut[3];
assign oOut4 = wOut[4];
assign oOut5 = wOut[5];
assign oOut6 = wOut[6];
assign oOut7 = wOut[7];
assign oOut8 = wOut[8];
assign oValid = wOValid ;//&& !wColEnd;

assign oCs = iEn && ((cur_state == FIRST_ROW)|| (cur_state == ODD_ROW) ||(cur_state == EVEN_ROW));
assign oAddr = rAddr;
endmodule
