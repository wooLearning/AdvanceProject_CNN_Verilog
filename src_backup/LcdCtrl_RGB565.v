`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/10 16:42:45
// Design Name: 
// Module Name: LcdCtrl_RGB565
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


module LcdCtrl_RGB565(
    input wire iClk,
    input wire iRsn,
    input wire iEnClk,
    input wire [15:0] iRamRdData,

    output reg [16:0] oRamRdAddr,
    output reg oLcdHSync,
    output reg oLcdVSync,
    output reg [4:0] oLcdR,
    output reg [5:0] oLcdG,
    output reg [4:0] oLcdB 
    );

    reg [15:0] h_count;
    reg [15:0] v_count;

    reg hsync;
    reg vsync;

    reg hsync_delay1;
    reg vsync_delay1;


// sync & count
    always @(posedge iClk or negedge iRsn) begin
        if(!iRsn) begin
            h_count <= 0;
            v_count <= 0;
            hsync <= 0;
            vsync <= 0;
        end
        else if(iEnClk) begin
            if(h_count < 40) begin
                hsync <= 0;
                h_count <= h_count + 1;
            end
            else if((h_count >= 40) && (h_count < 522)) begin
                hsync <= 1;
                h_count <= h_count + 1;
            end
            else begin
                hsync <= 0;
                h_count <= 0;

                if (v_count < 10) begin
                    vsync <= 0;
                    v_count <= v_count + 1;
                end 
                else if ((v_count >= 10) && (v_count < 284)) begin
                    vsync <= 1;
                    v_count <= v_count + 1;
                end 
                else begin
                    vsync <= 0;
                    v_count <= 0;
                end
            end
        end
    end

// RAM address
    always @(posedge iClk or negedge iRsn) begin
        if(!iRsn) begin
            oRamRdAddr <= 0;
        end
        else if(iEnClk) begin
            if(vsync == 0) begin
                oRamRdAddr <= 0;
            end
            else begin
                if ((v_count >= 12) && (v_count < 284)) begin
                    if ((h_count >= 43) && (h_count < 523)) begin
                        oRamRdAddr <= oRamRdAddr + 1;
                    end
                end
            end
        end
    end

// pipeline delay
    always @(posedge iClk or negedge iRsn) begin
        if(!iRsn) begin
            hsync_delay1 <= 0;
            vsync_delay1 <= 0;
            oLcdHSync <= 0;
            oLcdVSync <= 0;
        end
        else if(iEnClk) begin
            hsync_delay1 <= hsync;
            vsync_delay1 <= vsync;
            oLcdHSync <= hsync_delay1;
            oLcdVSync <= vsync_delay1;
        end
    end

// LCD RGB Data
    always @(posedge iClk or negedge iRsn) begin
        if(!iRsn) begin
            oLcdR <= 0;
            oLcdG <= 0;
            oLcdB <= 0;
        end
        else if(iEnClk) begin
            oLcdR <= iRamRdData[15:11];
            oLcdG <= iRamRdData[10:5];
            oLcdB <= iRamRdData[4:0];
        end
    end

endmodule
