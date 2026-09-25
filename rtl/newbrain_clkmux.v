//============================================================================
// NewBrain - conmutador de reloj sin glitches
//
// Elige entre dos relojes sin relacion entre si (aqui, 32 y 27 MHz para el
// pixel). Esquema clasico: cada reloj solo se habilita cuando el otro ya
// esta deshabilitado, y la habilitacion cambia en el flanco de BAJADA de su
// propio reloj, con el reloj a cero. Asi la salida nunca da un pulso corto:
// al cambiar se queda a cero unos ciclos y sigue con el otro reloj.
//
// sel = 0: clk0; sel = 1: clk1. sel puede venir de cualquier dominio: se
// sincroniza en cada lado.
//============================================================================
`default_nettype none

module newbrain_clkmux (
    input  wire clk0,
    input  wire clk1,
    input  wire sel,
    output wire clk_out
);
    reg [1:0] s0 = 2'b11, s1 = 2'b00;    // sincronizadores
    reg       en0 = 1'b1, en1 = 1'b0;

    always @(posedge clk0) s0 <= {s0[0], ~sel & ~en1};
    always @(negedge clk0) en0 <= s0[1];
    always @(posedge clk1) s1 <= {s1[0],  sel & ~en0};
    always @(negedge clk1) en1 <= s1[1];

    assign clk_out = (clk0 & en0) | (clk1 & en1);
endmodule

`default_nettype wire
