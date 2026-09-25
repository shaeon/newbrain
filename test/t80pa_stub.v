// Stub de T80pa solo para comprobar sintaxis y elaboracion sin el submodulo.
// NO usar en sintesis.
`default_nettype none
module T80pa (
    input  wire RESET_n, CLK, CEN_p, CEN_n, WAIT_n, INT_n, NMI_n, BUSRQ_n,
    output wire M1_n, MREQ_n, IORQ_n, RD_n, WR_n, RFSH_n, HALT_n, BUSAK_n,
    output wire [15:0] A,
    input  wire [7:0] DI,
    output wire [7:0] DO
);
    assign {M1_n, MREQ_n, IORQ_n, RD_n, WR_n, RFSH_n, HALT_n, BUSAK_n} = 8'hFF;
    assign A = 16'h0000;
    assign DO = 8'h00;
endmodule
`default_nettype wire
