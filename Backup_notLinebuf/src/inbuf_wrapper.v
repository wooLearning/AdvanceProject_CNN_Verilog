module inbuf_wrapper #(
    parameter integer DATA_W = 24,
    parameter integer ADDR_W = 17,
    parameter integer DEPTH  = 130560
)(
    input  wire                  clka,
    input  wire                  ena,
    input  wire                  wea,     // 1'b1 write, 1'b0 read
    input  wire [ADDR_W-1:0]     addra,   // 0..DEPTH-1
    input  wire [DATA_W-1:0]     dina,
    output wire [DATA_W-1:0]     douta
);


    // Vivado BMG IP 인스턴스 (IP 이름은 생성한 것과 동일해야 함)
    InputMemory_RGB888 InputMemory_RGB888 (
        .clka  (clka),
        .ena   (ena),
        .wea   (wea),
        .addra (addra),
        .dina  (dina),
        .douta (douta)
    );

endmodule
