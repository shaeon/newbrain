`timescale 1ns/1ps
//
// Modelo de comportamiento de una SDRAM de 16 bits: 4096 filas, 256 columnas,
// 4 bancos. Comprueba el protocolo, no los tiempos.
//
// Vigila tres cosas que antes no miraba y que costaron una tarde:
//
//   - la fila y el banco completos forman la direccion, sin plegar nada, de
//     modo que un mapeo equivocado se ve como datos en el sitio que no toca
//     en vez de pasar desapercibido;
//   - un READ o WRITE sin ACTIVE previo es error;
//   - un ACTIVE sobre un banco que ya esta abierto, sin precarga de por
//     medio, tambien. Eso es lo que delata que la precarga automatica no se
//     esta emitiendo.
//
module sdram_model (
    input  wire        clk,
    input  wire [12:0] A,
    inout  wire [15:0] DQ,
    input  wire        DQML,
    input  wire        DQMH,
    input  wire        nWE,
    input  wire        nCAS,
    input  wire        nRAS,
    input  wire        nCS,
    input  wire [1:0]  BA,
    input  wire        CKE
);
    localparam ROWS = 4096;

    reg [15:0] mem [0:4194303];        // banco<<20 | fila<<8 | columna
    reg [11:0] act_row [0:3];
    reg [3:0]  act;

    reg [15:0] rd_d1, rd_d2;
    reg        rd_v1, rd_v2;
    assign DQ = rd_v2 ? rd_d2 : 16'bZ;

    integer lmr_count = 0, ref_count = 0, pre_count = 0, errores = 0;

    wire [3:0] cmd = {nCS, nRAS, nCAS, nWE};

    function [21:0] dir;
        input [1:0] b;
        input [11:0] r;
        input [7:0]  c;
        dir = {b, r, c};
    endfunction

    integer i;
    initial begin
        // Sin inicializar, una posicion nunca escrita vale X y las
        // comprobaciones de "no se piso lo de al lado" no significan nada.
        for (i = 0; i < 4194304; i = i + 1) mem[i] = 16'h0000;
        act = 4'b0000;
        rd_v1 = 1'b0;
        rd_v2 = 1'b0;
    end

    always @(posedge clk) begin
        rd_v1 <= 1'b0;
        rd_v2 <= rd_v1;
        rd_d2 <= rd_d1;

        if (CKE) case (cmd)
        4'b0011: begin                       // ACTIVE
            if (act[BA]) begin
                $display("ERROR modelo: ACTIVE sobre el banco %0d ya abierto, falta precarga", BA);
                errores = errores + 1;
            end
            if (A >= ROWS) begin
                $display("ERROR modelo: fila %0d fuera de rango (el chip tiene %0d)", A, ROWS);
                errores = errores + 1;
            end
            act_row[BA] <= A[11:0];
            act[BA]     <= 1'b1;
        end
        4'b0101: begin                       // READ
            if (!act[BA]) begin
                $display("ERROR modelo: READ sin ACTIVE en el banco %0d", BA);
                errores = errores + 1;
            end
            rd_d1 <= mem[dir(BA, act_row[BA], A[7:0])];
            rd_v1 <= 1'b1;
            if (A[10]) act[BA] <= 1'b0;      // precarga automatica
        end
        4'b0100: begin                       // WRITE
            if (!act[BA]) begin
                $display("ERROR modelo: WRITE sin ACTIVE en el banco %0d", BA);
                errores = errores + 1;
            end
            if (!DQML) mem[dir(BA, act_row[BA], A[7:0])][7:0]  <= DQ[7:0];
            if (!DQMH) mem[dir(BA, act_row[BA], A[7:0])][15:8] <= DQ[15:8];
            if (A[10]) act[BA] <= 1'b0;
        end
        4'b0010: begin                       // PRECHARGE
            if (A[10]) act <= 4'b0000; else act[BA] <= 1'b0;
            pre_count = pre_count + 1;
        end
        4'b0001: ref_count = ref_count + 1;  // AUTO REFRESH
        4'b0000: lmr_count = lmr_count + 1;  // LOAD MODE REGISTER
        default: ;
        endcase
    end
endmodule
