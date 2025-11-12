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
	output [23:0] oOut0,
	output [23:0] oOut1,
	output [23:0] oOut2,
	output [23:0] oOut3,
	output [23:0] oOut4,
	output [23:0] oOut5,
	output [23:0] oOut6,
	output [23:0] oOut7,
	output [23:0] oOut8,
	output oValid,

	/*mac wait*/
	input iBusy
);

localparam IDLE = 4'd9;
localparam P0 = 4'd0;
localparam P1 = 4'd1;
localparam P2 = 4'd2;
localparam P3 = 4'd3;
localparam P4 = 4'd4;
localparam P5 = 4'd5;
localparam P6 = 4'd6;
localparam P7 = 4'd7;
localparam P8 = 4'd8;

wire [3:0] wGetMax = (cur_state == P0) ? 4'd6 ://4+2
					 (cur_state == P1) ? 4'd4 : //2+2
					 (cur_state == P2) ? 4'd2 : //2+0
					 (cur_state == P3) ? 4'd8 : //6+2
					 (cur_state == P4) ? 4'd5 : //3+2
					 (cur_state == P5) ? 4'd2 : //2+0
					 (cur_state == P6) ? 4'd6 : //4+2
					 (cur_state == P7) ? 4'd4 : //2+2
					 (cur_state == P8) ? 4'd2 : 4'd1;

integer i;
reg [3:0] rGetCnt;//get counter
reg [ADDR_W-1 : 0] rPixel_cnt;//pixel counter
/*추후 분해 예정*/
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rGetCnt <= 4'b0;	
		rPixel_cnt <= {ADDR_W{1'b0}};
	end
	else if(iEn == 1'b1 && iBusy == 0) begin
		if((wGetMax == rGetCnt) || ((cur_state != nxt_state)) ) begin
			rGetCnt <= 4'b0;
		end
		else begin//chip select
			rGetCnt <= rGetCnt + 1'b1;
		end
		if((wGetMax == rGetCnt)) begin //  || ((cur_state != nxt_state) && (cur_state != IDLE) && (cur_state != P1)  && (cur_state != P4) && (cur_state != P5) && (cur_state != P7))
			rPixel_cnt <= rPixel_cnt + 1'b1;
		end
	end
	else begin
		rGetCnt <= rGetCnt;
		rPixel_cnt <= rPixel_cnt;
	end
end

/*
//480 -> 1_1110_0000
wire wIsLeft = (rPixel_cnt[4:0] == 5'b0) ? 1'b1 : 1'b0;
wire wIsRight = (rPixel_cnt[4:0] == 5'b11111) ? 1'b1 : 1'b0;
*/
wire wIsRight = (rPixel_cnt[4:0] == 5'b11111) ? 1'b1 : 1'b0;

reg [3:0] cur_state;
reg [3:0] nxt_state;
//part1
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		cur_state <= IDLE;
	end
	else if(iEn == 1'b1 && iBusy == 1'b0)begin
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
			if(iEn == 1'b1) nxt_state = P0; else nxt_state = IDLE;
		end 
		P0: begin
			if((rGetCnt == wGetMax)) nxt_state = P1; else nxt_state = P0;
		end
		P1: begin
			if(rPixel_cnt == 39) nxt_state = P2; else nxt_state = P1;
		end
		P2: begin
			if((rGetCnt == wGetMax) ) nxt_state = P3; else nxt_state = P2;
		end

		P3: begin
			if((rGetCnt == wGetMax) ) nxt_state = P4; else nxt_state = P3;
		end
		P4: begin
			if(rPixel_cnt == 79 || rPixel_cnt == 119) nxt_state = P5; else nxt_state = P4;
		end
		P5: begin 
			if(rPixel_cnt == 119 && ((rGetCnt == wGetMax))) begin //130580 마지막 열 시작 480 * 271
				nxt_state = P6;
			end 
			else if((rGetCnt == wGetMax)) begin
				nxt_state = P3;
			end  
			else nxt_state = P5;
		end

		P6: begin
			if((rGetCnt == wGetMax)) nxt_state = P7; else nxt_state = P6;
		end
		P7: begin
			if((rPixel_cnt == 159)) nxt_state = P8; else nxt_state = P7;
		end
		P8: begin
			if((rGetCnt == wGetMax)) nxt_state = IDLE; else nxt_state = P8;
		end
		default:nxt_state = IDLE; 
	endcase
end

reg [ADDR_W -1:0] rAddr;

always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		rAddr <= {ADDR_W{1'b0}};	
	end
	else begin
		if(iEn == 1'b1 && iBusy == 1'b0) begin
			case (cur_state)
				P0: begin
					if(rGetCnt == 0) rAddr <= rPixel_cnt;
					else if(rGetCnt == 2) rAddr <= WIDTH;
					else if(rGetCnt <= 3) rAddr <= rAddr + 1'b1;
					else rAddr <= rAddr;
				end
				P1 : begin
					if(rGetCnt == 0) rAddr <= rPixel_cnt+1'b1;
					else if(rGetCnt == 1) rAddr <= rAddr+WIDTH;
					else rAddr <= rAddr;
				end
				P2 : begin
					rAddr <= 0;
				end

				P3 : begin
					if(rGetCnt == 0) rAddr <= rPixel_cnt - WIDTH;
					else if(rGetCnt == 2) rAddr <= rAddr + WIDTH -1;
					else if(rGetCnt == 4) rAddr <= rAddr + WIDTH -1;
					else if(rGetCnt <= 5) rAddr <= rAddr + 1'b1;
					else rAddr <= rAddr;
				end
				P4 : begin
					if(rGetCnt == 0) rAddr <= rPixel_cnt - WIDTH + 1;
					else if(rGetCnt == 1) rAddr <= rAddr + WIDTH;
					else if(rGetCnt == 2) rAddr <= rAddr + WIDTH;
					else rAddr <= rAddr;
				end
				P5 : begin
					rAddr <= 0;
				end

				P6: begin
					if(rGetCnt == 0) rAddr <= rPixel_cnt - WIDTH;
					else if(rGetCnt == 2) rAddr <= rPixel_cnt;
					else if(rGetCnt <= 3) rAddr <= rAddr + 1'b1;
					else rAddr <= rAddr;
				end
				P7 : begin
					if(rGetCnt == 0) rAddr <= rPixel_cnt + 1'b1 - WIDTH;
					else if(rGetCnt == 1) rAddr <= rAddr+WIDTH;
					else rAddr <= rAddr;
				end
				P8 : begin
					rAddr <= 0;
				end
			endcase
		end
		
	end
end


assign oAddr = rAddr;
assign oCs = !((cur_state == P2) || (cur_state == P5) || (cur_state == P8)) && iEn;

//////////////////
/*register block*/
/////////////////
reg [DATA_W - 1:0] rOut[0:8];//shift register

/*0,1,2*/
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		for(i = 0; i < 3; i = i + 1)begin
			rOut[i] <= {DATA_W{1'b0}};			
		end
	end
	else if(iEn == 1'b1 && iBusy == 1'b0)begin
		case (cur_state)
			P3: begin
				if(rGetCnt == 3 || rGetCnt == 4)begin
					rOut[2] <= iPixel;
					rOut[1] <= rOut[2];
					rOut[0] <= rOut[1];
				end
			end
			P4: begin
				if(rGetCnt == 3)begin
					rOut[2] <= iPixel;
					rOut[1] <= rOut[2];
					rOut[0] <= rOut[1];
				end
			end
			P5: begin
				if(rGetCnt == 0)begin
					rOut[2] <= 0;
					rOut[1] <= rOut[2];
					rOut[0] <= rOut[1];
				end
				if(rGetCnt == 2)begin
					for(i = 0; i < 2; i = i + 1)begin
						rOut[i] <= {DATA_W{1'b0}};			
					end
				end
			end

			P6: begin
				if(rGetCnt == 3 || rGetCnt == 4)begin
					rOut[2] <= iPixel;
					rOut[1] <= rOut[2];
					rOut[0] <= rOut[1];
				end
			end
			P7: begin
				if(rGetCnt == 3)begin
					rOut[2] <= iPixel;
					rOut[1] <= rOut[2];
					rOut[0] <= rOut[1];
				end
			end
			P8: begin
				if(rGetCnt == 0)begin
					rOut[2] <= 0;
					rOut[1] <= rOut[2];
					rOut[0] <= rOut[1];
				end
				if(rGetCnt == 2)begin
					for(i = 0; i < 2; i = i + 1)begin
						rOut[i] <= {DATA_W{1'b0}};			
					end
				end
			end
			default: begin
				for(i = 0; i < 3; i = i + 1)begin
					rOut[i] <= rOut[i];	
				end
			end
		endcase
	end
	else begin
		for(i = 0; i < 3; i = i + 1)begin
			rOut[i] <= rOut[i];	
		end
	end
end

/*3,4,5*/
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		for(i = 3; i < 6; i = i + 1)begin
			rOut[i] <= {DATA_W{1'b0}};			
		end
	end
	else if(iEn == 1'b1 && iBusy == 1'b0)begin
		case (cur_state)
			P0: begin
				if(rGetCnt == 3 || rGetCnt == 4)begin
					rOut[5] <= iPixel;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
			end
			P1 : begin
				if(rGetCnt == 3)begin
					rOut[5] <= iPixel;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
			end
			P2 : begin
				if(rGetCnt == 0)begin
					rOut[5] <= 0;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
				if(rGetCnt == 2)begin
					for(i = 3; i < 6; i = i + 1)begin
						rOut[i] <= {DATA_W{1'b0}};			
					end
				end
			end

			P3: begin
				if(rGetCnt == 5 || rGetCnt == 6)begin
					rOut[5] <= iPixel;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
			end
			P4: begin
				if(rGetCnt == 4)begin
					rOut[5] <= iPixel;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
			end
			P5: begin
				if(rGetCnt == 0)begin
					rOut[5] <= 0;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
				if(rGetCnt == 2)begin
					for(i = 3; i < 6; i = i + 1)begin
						rOut[i] <= {DATA_W{1'b0}};			
					end
				end
			end

			P6: begin
				if(rGetCnt == 5 || rGetCnt == 6)begin
					rOut[5] <= iPixel;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
			end
			P7: begin
				if(rGetCnt == 4)begin
					rOut[5] <= iPixel;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
			end
			P8: begin
				if(rGetCnt == 0)begin
					rOut[5] <= 0;
					rOut[4] <= rOut[5];
					rOut[3] <= rOut[4];
				end
				if(rGetCnt == 2)begin
					for(i = 3; i < 6; i = i + 1)begin
						rOut[i] <= {DATA_W{1'b0}};			
					end
				end
			end

			default: begin
				for(i = 3; i < 6; i = i + 1)begin
					rOut[i] <= rOut[i];	
				end
			end
		endcase
	end
	else begin
		for(i = 3; i < 6; i = i + 1)begin
			rOut[i] <= rOut[i];	
		end
	end
end

/*6,7,8*/
always @(posedge iClk or negedge iRst) begin
	if(!iRst) begin
		for(i = 6; i < 9; i = i + 1)begin
			rOut[i] <= {DATA_W{1'b0}};			
		end
	end
	else if(iEn == 1'b1 && iBusy == 1'b0)begin
		case (cur_state)
			P0: begin
				if(rGetCnt == 5 || rGetCnt == 6)begin
					rOut[8] <= iPixel;
					rOut[7] <= rOut[8];
					rOut[6] <= rOut[7];
				end
			end
			P1 : begin
				if(rGetCnt == 4)begin
					rOut[8] <= iPixel;
					rOut[7] <= rOut[8];
					rOut[6] <= rOut[7];
				end
			end
			P2 : begin
				if(rGetCnt == 0)begin
					rOut[8] <= 0;
					rOut[7] <= rOut[8];
					rOut[6] <= rOut[7];
				end
				if(rGetCnt == 2)begin
					for(i = 6; i < 9; i = i + 1)begin
						rOut[i] <= {DATA_W{1'b0}};			
					end
				end
			end

			P3: begin
				if(rGetCnt == 7 || rGetCnt == 8)begin
					rOut[8] <= iPixel;
					rOut[7] <= rOut[8];
					rOut[6] <= rOut[7];
				end
			end
			P4: begin
				if(rGetCnt == 5)begin
					rOut[8] <= iPixel;
					rOut[7] <= rOut[8];
					rOut[6] <= rOut[7];
				end
			end
			P5: begin
				if(rGetCnt == 0)begin
					rOut[8] <= 0;
					rOut[7] <= rOut[8];
					rOut[6] <= rOut[7];
				end
				if(rGetCnt == 2)begin
					for(i = 6; i < 9; i = i + 1)begin
						rOut[i] <= {DATA_W{1'b0}};			
					end
				end
			end

			default: begin
				for(i = 6; i < 9; i = i + 1)begin
					rOut[i] <= rOut[i];	
				end
			end
		endcase
	end
	else begin
		for(i = 6; i < 9; i = i + 1)begin
			rOut[i] <= rOut[i];	
		end
	end
end

reg wValid;
always @(*) begin
	case (cur_state)
		P1: begin
			if(rGetCnt == 2) wValid = 1'b1; else wValid = 1'b0;
		end
		P2: begin
			if(rGetCnt == 0 || rGetCnt == 1) wValid = 1'b1; else wValid = 1'b0;
		end
		P4: begin
			if(rGetCnt == 2) wValid = 1'b1; else wValid = 1'b0;
		end
		P5: begin
			if(rGetCnt == 0 || rGetCnt == 1) wValid = 1'b1; else wValid = 1'b0;
		end
		P7: begin
			if(rGetCnt == 2) wValid = 1'b1; else wValid = 1'b0;
		end
		P8:begin
			if(rGetCnt == 0 || rGetCnt == 1) wValid = 1'b1; else wValid = 1'b0;
		end
		default: wValid = 1'b0;
	endcase
end
assign oValid = wValid && iEn && (!iBusy);

assign oOut0 = rOut[0];
assign oOut1 = rOut[1];
assign oOut2 = rOut[2];
assign oOut3 = rOut[3];
assign oOut4 = rOut[4];
assign oOut5 = rOut[5];
assign oOut6 = rOut[6];
assign oOut7 = rOut[7];
assign oOut8 = rOut[8];

endmodule
