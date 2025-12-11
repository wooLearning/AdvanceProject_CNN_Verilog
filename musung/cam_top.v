`timescale 1ns / 10ps

module top(
input  wire            PL_CLK_100MHZ,
input  wire            RstButton,
inout  wire            CAMERA_SCCB_SCL,
inout  wire            CAMERA_SCCB_SDA,
output wire  [ 4:0]    TFT_B_DATA,
output wire  [ 5:0]    TFT_G_DATA,
output wire  [ 4:0]    TFT_R_DATA,
output wire            TFT_DCLK,
output wire            TFT_BACKLIGHT,
output wire            TFT_DE,
output wire            TFT_HSYNC,
output wire            TFT_VSYNC,
input  wire            CAMERA_PCLK,
input  wire  [ 7:0]    CAMERA_DATA,
output wire            CAMERA_RESETn,
input  wire            CAMERA_HSYNC,
input  wire            CAMERA_VSYNC,
output wire            CAMERA_PWDN,
output wire            CAMERA_MCLK,

// axi lite interface
input wire [31:0] iReg0,
input wire [31:0] iReg1,
input wire [31:0] iReg2,
input wire [31:0] iReg3
    );

wire    clk_w;
wire    cam_wr_en_w;
wire    [15:0]    cam_wr_data_w;
wire    [16:0]    cam_wr_addr_w;
wire    [15:0]    lcd_rd_data_w;
wire    [16:0]    lcd_rd_addr_w;
wire    wClkTFT;


clk_gen2    CLK_GEN_MAIN(
    .clk_i(PL_CLK_100MHZ),
    .count_i(16'h0001),
    .clk_o(CAMERA_MCLK)
);//25MHz
clk_enable CLK_GEN_TFT(
    .iClk(CAMERA_MCLK),
    .oEnable(wClkTFT)
);
/*
clk_gen2    CLK_GEN_TFTLCD(
    .clk_i(CAMERA_MCLK),
    .count_i(16'h0001),
    .clk_o(TFT_DCLK)
);
*/
assign TFT_DCLK = wClkTFT;

wire wCs;

camera_to_ram CAMEARA_TO_RAM(
    .clk_i(CAMERA_PCLK),
    .sw_i(1'b1),
    .cam_vsync_i(CAMERA_VSYNC),
    .cam_hsync_i(CAMERA_HSYNC),
    .cam_data_i(CAMERA_DATA),
    .ram_wr_en_o(cam_wr_en_w),
    .ram_wr_addr_o(cam_wr_addr_w),
    .ram_wr_data_o(cam_wr_data_w)
);
//Xilinx IP
// RAM_CAMERA  RAM_CAMERA(
//     .clka(CAMERA_PCLK),
//     .ena(1'b1),
//     .wea(cam_wr_en_w),
//     .addra(cam_wr_addr_w),
//     .dina(cam_wr_data_w),
    
//     .clkb(TFT_DCLK),
//     .enb(wCs),
//     .addrb(lcd_rd_addr_w),
//     .doutb(lcd_rd_data_w)
// );
RstGen u_RstGen(
	.iClk(iClk),
	.iButton(iRstButton),
	.oRsn(wRsn)
);

wire wStart;
wire [23:0] wo_rd_data;
in_buf_ctrl in_buf_ctrl(
    .i_clk(CAMERA_PCLK),
    .i_clk_100M(PL_CLK_100MHZ),
    .i_rst_n(wRsn),

    // [1] Camera Interface (Write Side)
    .i_cam_vsync(CAMERA_VSYNC),   // Bank Switching Trigger
    .i_wr_en(cam_wr_en_w),       // Write Enable
    .i_wr_addr(cam_wr_addr_w),     // Write Address
    .i_wr_data(cam_wr_data_w),     // Write Data

    // [2] Window Interface (Read Side)
    .i_rd_en(wCs),       // Read Enable
    .i_rd_addr(lcd_rd_addr_w),     // Read Address
    .o_rd_data(wo_rd_data),      // Read Data Output
    .start(wStart)
);

cnn_top u_cnn_top(
    .iClk(PL_CLK_100MHZ),
    .iClkTFT(wClkTFT),
    .iRstButton(wRsn),
    
    .lcd_rd_addr_w(lcd_rd_addr_w),
    .oCs(wCs),

    .lcd_rd_data_w(lcd_rd_data_w),
    .oLcdHSync(TFT_HSYNC),
    .oLcdVSync(TFT_VSYNC),
    .oLcdR(TFT_R_DATA),
    .oLcdG(TFT_G_DATA),
    .oLcdB(TFT_B_DATA),
    .iReg0(iReg0),
    .iReg1(iReg1),
    .iReg2(iReg2),
    .iReg3(iReg3)
);

assign    TFT_BACKLIGHT = 1'b1;
assign    TFT_DE = 1'b1;
endmodule
