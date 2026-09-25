// Sustituto de rtl/u765/u765.sv para Icarus, que no lee su SystemVerilog.
// Mismos puertos. Devuelve 5A, cuenta los accesos y deja la linea INT en
// manos del banco de pruebas.
`default_nettype none
module u765 #(parameter CYCLES = 20'd4000, SPECCY_SPEEDLOCK_HACK = 0) (
    input  wire        clk_sys, ce, reset,
    input  wire [1:0]  ready, motor, available,
    input  wire        fast, a0, nRD, nWR,
    input  wire [7:0]  din,
    output wire [7:0]  dout,
    output reg         int_o,
    input  wire [1:0]  img_mounted,
    input  wire        img_wp,
    input  wire [31:0] img_size,
    output wire [31:0] sd_lba,
    output wire [1:0]  sd_rd, sd_wr,
    input  wire        sd_ack,
    input  wire [8:0]  sd_buff_addr,
    input  wire [7:0]  sd_buff_dout,
    output wire [7:0]  sd_buff_din,
    input  wire        sd_buff_wr
);
    assign dout = a0 ? 8'h5A : 8'h80;
    assign sd_lba = 0; assign sd_rd = 0; assign sd_wr = 0; assign sd_buff_din = 0;
    integer lecturas = 0, escrituras = 0;
    reg [7:0] ultimo;
    reg nrd_d = 1, nwr_d = 1;
    initial int_o = 0;
    always @(posedge clk_sys) begin
        nrd_d <= nRD; nwr_d <= nWR;
        if (nrd_d & ~nRD) lecturas = lecturas + 1;
        if (nwr_d & ~nWR) begin escrituras = escrituras + 1; ultimo <= din; end
    end
endmodule
`default_nettype wire
