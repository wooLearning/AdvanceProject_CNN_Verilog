`timescale 1ns / 10ps


module ram_to_lcd(
    input   clk_i,
    
    output  [16:0]  ram_rd_addr_o,
    input   [15:0]  ram_rd_data_i,
    
    output  LCD_hsync_o,
    output  LCD_vsync_o,
    output  [4:0]   LCD_R_o,
    output  [5:0]   LCD_G_o,
    output  [4:0]   LCD_B_o
    );
    
    reg     [15:0]  h_count;
    reg             hsync;
    reg             hsync_delay1;
    reg             hsync_delay2;
    
    reg     [15:0]  v_count;
    reg             vsync;
    reg             vsync_delay1;
    reg             vsync_delay2;
    
    reg     [16:0]  ram_rd_addr;
    reg     [15:0]  ram_rd_data;
    
    reg     [4:0]   lcd_r;
    reg     [5:0]   lcd_g;
    reg     [4:0]   lcd_b;
    
    always @(posedge clk_i) begin
        if (h_count < 40) begin
            hsync <= 0;
            h_count <= h_count + 1;
        end else if ((h_count >= 40) && (h_count < 522)) begin
            hsync <= 1;
            h_count <= h_count + 1;
        end else begin
            hsync <= 0;
            h_count <= 0;
            
            if (v_count < 10) begin
                vsync <= 0;
                v_count <= v_count + 1;
            end else if ((v_count >= 10) && (v_count < 284)) begin
                vsync <= 1;
                v_count <= v_count + 1;
            end else begin
                vsync <= 0;
                v_count <= 0;
            end
        end
    end
    
    always @(posedge clk_i) begin
        if (vsync == 0) begin
            ram_rd_addr <= 0;
        end else begin
            if ((v_count >= 12) && (v_count < 284)) begin
                if ((h_count >= 42) && (h_count < 522)) begin
                    ram_rd_addr <= ram_rd_addr + 1;
                end
            end else begin
            
            end
        end
    end
    
    assign ram_rd_addr_o = ram_rd_addr;
    
    always @(negedge clk_i) begin
        hsync_delay1 <= hsync;
        hsync_delay2 <= hsync_delay1;
        
        vsync_delay1 <= vsync;
        vsync_delay2 <= vsync_delay1;
    end
    
    assign LCD_hsync_o = hsync_delay2;
    assign LCD_vsync_o = vsync_delay2;
    
    always @(posedge clk_i) begin
        if (v_count == 12) begin
            if (h_count == 43) begin
                ram_rd_data <= 1;
            end else if (h_count == 522) begin
                ram_rd_data <= 1;
            end else begin
                ram_rd_data <= ram_rd_data_i;
            end
        end else if (v_count == 283) begin
            if (h_count == 43) begin
                ram_rd_data <= 1;
            end else if (h_count == 522)begin
                ram_rd_data <= 1;
            end else begin
                ram_rd_data <= ram_rd_data_i;
            end
        end else begin
            ram_rd_data <= ram_rd_data_i;
        end
    end
    
    always @(negedge clk_i) begin
        lcd_r <= ram_rd_data[4:0];
        lcd_g <= ram_rd_data[10:5];
        lcd_b <= ram_rd_data[15:11];
    end
    
    assign LCD_R_o = lcd_r;
    assign LCD_G_o = lcd_g;
    assign LCD_B_o = lcd_b;
    
endmodule
