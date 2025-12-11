`timescale 1ns / 10ps


module clk_gen2(
    input   clk_i,
    input   [15:0]  count_i,
    output  clk_o
    );
    
    reg     [15:0]  sig_count;
    reg             sig_clk_out;
    
    always @(posedge clk_i) begin
        if (sig_count == count_i) begin
            sig_count <= 0;
        end else begin
            sig_count <= sig_count + 1;
        end
    end
    
    always @(posedge clk_i) begin
        if (sig_count == count_i) begin
            sig_clk_out <= ~(sig_clk_out);
        end else begin
            
        end
    end
    
    assign clk_o = sig_clk_out;
    
endmodule
