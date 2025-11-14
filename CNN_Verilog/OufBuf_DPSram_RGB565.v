`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/10 16:41:59
// Design Name: 
// Module Name: OufBuf_DPSram_RGB565
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OufBuf_DPSram_RGB565(
    input wire iClk,
    input wire iRsn,
    input wire iEnClk,
    input wire iWrEn,
    input wire [16:0] iWrAddr,
    input wire [16:0] iRdAddr,
    input wire [15:0] iData,

    output reg [15:0] oData
    );

// Array
    reg [15:0] rOufBuf [0 : 130559];

// Write
    always @(posedge iClk) begin
        if(iEnClk == 1'b1 && iWrEn == 1'b1) begin
                rOufBuf[iWrAddr] <= iData;
        end
    end


// Read
    always @(posedge iClk) begin
        if(!iRsn) begin
            oData <= 16'd0;
        end
        else if(iEnClk) begin
                oData <= rOufBuf[iRdAddr];
        end
    end

endmodule
