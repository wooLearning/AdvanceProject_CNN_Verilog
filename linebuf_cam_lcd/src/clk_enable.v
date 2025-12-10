module clk_enable(
    input iClk,
    input iRst,
    output oEnable
);
    
    reg [2:0] rCnt;
    
    always @(posedge iClk, negedge iRst) begin
        if(!iRst) begin
            rCnt <= 0;
        end
        else if (rCnt == 3'h7) begin
            rCnt <= 3'b0;
        end else begin
            rCnt <= rCnt + 1'b1;
        end
    end

    
    assign oEnable = (rCnt == 3'h7)  ? 1'b1 : 1'b0;
    
endmodule
