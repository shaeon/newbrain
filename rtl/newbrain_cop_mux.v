//============================================================================
// NewBrain - reparto del puerto del COP entre el COP de verdad y el modulo
// de cinta emulado
//
// El COP de verdad lleva siempre el teclado, la pantalla y el reloj. La
// cinta la lleva newbrain_cop_hle en modo solo cinta: cuando el Z80 manda
// un CASSCOM (8x con b3 o b1) como reconocimiento de una interrupcion del
// COP de verdad, el modulo se queda el comando y el puerto hasta que acaba
// la operacion de cinta. Al COP de verdad le llega un NULLCOM (D0) en lugar
// del CASSCOM, para que cierre su interrupcion y siga a lo suyo.
//============================================================================
`default_nettype none

module newbrain_cop_mux (
    // lado del Z80
    input  wire       cs,
    input  wire [7:0] din,
    output wire [7:0] dout,
    output wire       copint_n,
    // COP de verdad
    output wire       real_cs,
    output wire [7:0] real_din,
    input  wire [7:0] real_dout,
    input  wire       real_copint_n,
    // modulo de cinta
    input  wire       cinta_ocupada,
    input  wire [7:0] cinta_dout,
    input  wire       cinta_copint_n
);
    wire es_casscom = (din[7:4] == 4'h8) & (din[3] | din[1]);

    assign dout     = cinta_ocupada ? cinta_dout     : real_dout;
    assign copint_n = cinta_ocupada ? cinta_copint_n : real_copint_n;
    assign real_cs  = cs & ~cinta_ocupada;
    assign real_din = es_casscom ? 8'hD0 : din;
endmodule

`default_nettype wire
