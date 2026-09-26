// Stub del PLL de Altera para comprobar la elaboracion sin Quartus.
// c0 sin usar, c1 sistema, c2 pixel (27 MHz), c3 sin usar
`default_nettype none
module pll (input wire inclk0, output wire c0, output wire c1,
            output wire c2, output wire c3, output wire locked);
    assign c0 = inclk0;
    assign c1 = inclk0;
    assign c2 = inclk0;
    assign c3 = inclk0;
    assign locked = 1'b1;
endmodule
`default_nettype wire
