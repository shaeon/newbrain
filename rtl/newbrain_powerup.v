//============================================================================
// NewBrain - temporizadores de RESET y PWRUP
//
// En la maquina real son dos redes RC del motherboard:
//   RESET  t = R128 * C125 = 2.2 s   (las dos CPUs salen de HALT)
//   PWRUP  t = R129 * C127 = 5.6 s   (libera el mapeo forzado a ROM2)
//
// Verificado en el listado de EFROM: la ROM SOLO sondea el bit (bucle PWAIT
// en E009) y no mide el intervalo, asi que acortar los tiempos es seguro.
// La entrada `fast` los divide por 32. Ver doc/01-hardware.md
//============================================================================
`default_nettype none

module newbrain_powerup #(
    parameter CLK_HZ = 32_000_000
) (
    input  wire clk,
    input  wire reset,        // reset externo (OSD / boton / carga de ROM)
    input  wire fast,         // acorta los tiempos 32 veces
    output reg  cpu_reset_n,
    output reg  pwrup
);
    localparam T_RESET   = CLK_HZ * 22 / 10;         // 2.2 s
    localparam T_PWRUP   = CLK_HZ * 56 / 10;         // 5.6 s
    localparam T_RESET_F = T_RESET / 32;
    localparam T_PWRUP_F = T_PWRUP / 32;
    localparam CW        = 32;

    wire [CW-1:0] lim_reset = fast ? T_RESET_F[CW-1:0] : T_RESET[CW-1:0];
    wire [CW-1:0] lim_pwrup = fast ? T_PWRUP_F[CW-1:0] : T_PWRUP[CW-1:0];

    reg [CW-1:0] cnt;

    always @(posedge clk) begin
        if (reset) begin
            cnt         <= 0;
            cpu_reset_n <= 1'b0;
            pwrup       <= 1'b0;
        end else begin
            if (cnt != {CW{1'b1}}) cnt <= cnt + 1'b1;
            if (cnt >= lim_reset) cpu_reset_n <= 1'b1;
            if (cnt >= lim_pwrup) pwrup       <= 1'b1;
        end
    end
endmodule

`default_nettype wire
