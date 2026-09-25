//============================================================================
// NewBrain - espia del display fluorescente
//
// El display de 16 digitos lo lleva el COP, pero el texto se lo manda el
// Z80 por el puerto 06, y aqui se escucha para sacarlo a una pantalla LCD.
// El protocolo, medido con las dos ROMs originales frente a frente
// (tools/nbcopreal.py):
//
//   1. a una interrupcion del COP, el Z80 lee el vector y contesta con
//      DISPCOM (A0);
//   2. en la SIGUIENTE interrupcion, sin leer vector, escribe 18 bytes
//      seguidos, uno cada 25 us.
//
// De esos 18 bytes, los dos primeros son de control y los 16 siguientes el
// texto AL REVES: el ultimo byte es el caracter de la izquierda. Por
// ejemplo, "NEWBRAIN BASIC" llega como
//   20 00 20 20 43 49 53 41 42 20 4E 49 41 52 42 57 45 4E
//
// TIMCOM (B0) manda 6 bytes del mismo modo; se saltan para no confundirlos
// con texto.
//============================================================================
`default_nettype none

module newbrain_vfd_espia (
    input  wire         clk,
    input  wire         reset,
    input  wire         cs,            // acceso al puerto del COP
    input  wire         rd,
    input  wire         wr,
    input  wire [7:0]   din,           // lo que escribe el Z80
    output reg  [127:0] texto,         // 16 caracteres, el de la izquierda arriba
    output reg          nuevo          // pulso: texto recien completado
);
    reg rd_d, wr_d;
    wire lee   = cs & rd & ~rd_d;
    wire escr  = cs & wr & ~wr_d;
    always @(posedge clk) begin
        rd_d <= cs & rd;
        wr_d <= cs & wr;
    end

    localparam E_NADA = 2'd0, E_ESPERA = 2'd1, E_DATOS = 2'd2, E_FIN = 2'd3;
    reg [1:0]  estado;
    reg [4:0]  cuantos;       // bytes que quedan
    reg        es_texto;      // DISPCOM (si no, TIMCOM: se tira)
    reg [4:0]  idx;
    reg [7:0]  buf_ [0:15];
    integer    k;

    // caracter imprimible, o espacio
    function [7:0] limpio(input [7:0] c);
        limpio = (c[6:0] >= 7'h20 && c[6:0] < 7'h7F) ? {1'b0, c[6:0]} : 8'h20;
    endfunction

    always @(posedge clk) begin
        nuevo <= 1'b0;
        if (reset) begin
            estado <= E_NADA;
            texto  <= {16{8'h20}};
        end else begin
            case (estado)
            E_NADA:
                if (escr && (din == 8'hA0 || din == 8'hB0)) begin
                    es_texto <= (din == 8'hA0);
                    cuantos  <= (din == 8'hA0) ? 5'd18 : 5'd6;
                    estado   <= E_ESPERA;
                end
            E_ESPERA:
                // Si lo siguiente es una lectura, el Z80 esta atendiendo
                // otra interrupcion normal: no hubo datos
                if (lee)
                    estado <= E_NADA;
                else if (escr) begin
                    idx     <= 5'd1;
                    cuantos <= cuantos - 1'b1;
                    estado  <= E_DATOS;
                end
            E_DATOS: begin
                if (lee)
                    estado <= E_NADA;            // se corto: se descarta
                else if (escr) begin
                    // bytes 2..17 -> caracteres 15..0
                    if (es_texto && idx >= 5'd2)
                        buf_[5'd17 - idx] <= limpio(din);
                    idx     <= idx + 1'b1;
                    cuantos <= cuantos - 1'b1;
                    if (cuantos == 5'd1) begin
                        estado <= E_FIN;
                    end
                end
            end
            default: begin                         // E_FIN
                if (es_texto) begin
                    for (k = 0; k < 16; k = k + 1)
                        texto[127 - 8*k -: 8] <= buf_[k];
                    nuevo <= 1'b1;
                end
                estado <= E_NADA;
            end
            endcase
        end
    end

endmodule

`default_nettype wire
