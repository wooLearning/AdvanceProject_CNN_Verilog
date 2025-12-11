module clk_enable(
    input iClk,
    //input iRst,
    output oEnable
);
    
    reg [3:0] rCnt;
    
    always @(posedge iClk) begin
        if (rCnt == 4'h1) begin
            rCnt <= 4'b0;
        end else begin
            rCnt <= rCnt + 1'b1;
        end
    end

    
    assign oEnable = (rCnt == 4'h1)  ? 1'b1 : 1'b0;

endmodule
