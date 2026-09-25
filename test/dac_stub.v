// Sustituto de common/mist-modules/dac.vhd (VHDL) para poder elaborar el
// top con Icarus. Mismo modulador sigma-delta de primer orden.
module dac #(parameter C_bits = 8) (
    input  wire              clk_i,
    input  wire              res_n_i,
    input  wire [C_bits-1:0] dac_i,
    output reg               dac_o
);
    reg [C_bits:0] sig_in = {1'b1, {C_bits{1'b0}}};
    always @(posedge clk_i or negedge res_n_i)
        if (!res_n_i) begin
            sig_in <= {1'b1, {C_bits{1'b0}}};
            dac_o  <= 1'b0;
        end else begin
            sig_in <= sig_in + {sig_in[C_bits], dac_i};
            dac_o  <= sig_in[C_bits];
        end
endmodule
