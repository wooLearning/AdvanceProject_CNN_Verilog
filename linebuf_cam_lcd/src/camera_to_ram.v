`timescale 1ns / 10ps


module camera_to_ram(
    input   clk_i,
    input   sw_i,
    input   cam_vsync_i,
    input   cam_hsync_i,
    input   [7:0]   cam_data_i,
    output          ram_wr_en_o,
    output  [16:0]  ram_wr_addr_o,
    output  [15:0]  ram_wr_data_o
    );
    
    localparam sig_v_count_max_real = 272;
    localparam sig_h_count_max_real = 480;
    
//    localparam sig_v_count_max_sim = 272;
//    localparam sig_h_count_max_sim = 480;
    
    wire sig_v_count_max;
    wire sig_h_count_max;
    
    reg     sig_cam_vsync;
    reg     sig_cam_hsync;
    reg     [7:0]   sig_cam_data;
    
    reg     sig_cam_vsync_delay;
    reg     sig_cam_hsync_delay;
    reg     [7:0]   sig_cam_data_delay;
    
    reg     sig_temp;
    
    reg     [15:0]  sig_v_count;
    reg     [15:0]  sig_h_count;
    reg     [16:0]  sig_addr_count;
    
    reg             sig_en;
    reg             sig_ram_wr_en;
    reg     [16:0]  sig_ram_wr_addr;
    reg     [15:0]  sig_ram_wr_data;
    
    assign sig_v_count_max = sig_v_count_max_real;//(simulation==0) ? sig_v_count_max_real : sig_v_count_max_sim;
    assign sig_h_count_max = sig_h_count_max_real;//(simulation==0) ? sig_h_count_max_real : sig_h_count_max_sim;
    
    always @(posedge clk_i) begin
        sig_cam_vsync <= cam_vsync_i;
        sig_cam_hsync <= cam_hsync_i;
        sig_cam_data <= cam_data_i;
        
        sig_cam_vsync_delay <= sig_cam_vsync;
        sig_cam_hsync_delay <= sig_cam_hsync;
        sig_cam_data_delay <= sig_cam_data;
    end
    
    always @(posedge clk_i) begin
        if (sig_cam_vsync_delay == 0) begin
            if (sig_cam_hsync_delay == 1) begin
                sig_temp <= ~sig_temp;
            end else begin
                sig_temp <= sig_temp;
            end
        end else begin
            sig_temp <= 0;
        end
    end

    always @(posedge clk_i) begin
        if (sig_cam_vsync == 0) begin
            if ((sig_cam_hsync == 0) && (sig_cam_hsync_delay == 1)) begin
                sig_v_count <= sig_v_count + 1;
            end else begin
                sig_v_count <= sig_v_count;
            end
        end else begin
            sig_v_count <= 0;
        end
    end
    
    always @(posedge clk_i) begin
        if (sig_cam_vsync == 0) begin
            if (sig_cam_hsync == 1) begin
                if (sig_temp == 1) begin
                    sig_h_count <= sig_h_count + 1;
                end else begin
                    sig_h_count <= sig_h_count;
                end
            end else begin
                sig_h_count <= 0;
            end
        end else begin
            sig_h_count <= 0;
        end
    end
    
    always @(posedge clk_i) begin
        if (sig_cam_vsync == 0) begin
            if (sig_ram_wr_en == 1) begin
                sig_addr_count <= sig_addr_count + 1;
            end else begin
                
            end
        end else begin
            sig_addr_count <= 0;
        end
    end
    
    always @(posedge clk_i) begin
        if (sig_cam_vsync == 0) begin
            if (sig_cam_hsync == 1) begin
                if ((sig_v_count < sig_v_count_max_real) && (sig_h_count < sig_h_count_max_real)) begin
                    sig_en <= 1;
                end else begin
                    sig_en <= 0;
                end
            end else begin
                sig_en <= sig_en;
            end
        end else begin
            sig_en <= 0;
        end 
    end
    
    always @(posedge clk_i) begin
        if (sig_en == 1) begin
            if (sig_temp == 0) begin
                sig_ram_wr_en <= 0;
                sig_ram_wr_addr <= 0;
                sig_ram_wr_data[15:8] <= sig_cam_data_delay;
            end else if (sig_temp == 1) begin
                sig_ram_wr_en <= 1;
                sig_ram_wr_addr <= sig_addr_count;
                sig_ram_wr_data[7:0] <= sig_cam_data_delay;
            end
        end else begin
            sig_ram_wr_en <= 0;
            sig_ram_wr_addr <= 0;
            sig_ram_wr_data <= 0;
        end
    end
    
    assign ram_wr_en_o = sig_ram_wr_en;
    assign ram_wr_addr_o = sig_ram_wr_addr;
    assign ram_wr_data_o = sig_ram_wr_data;
    
endmodule
