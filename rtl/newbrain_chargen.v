// Generador de caracteres: 4K, cargado desde data_io.
//
// ATENCION: la organizacion interna es una suposicion. Se asume ordenado por
// linea de barrido (256 bytes por linea, 16 lineas), que es lo que hace la
// implementacion de cdesp y lo que encaja con los 4096 bytes de la EPROM
// original. Si resultara estar ordenado por caracter, basta con cambiar
// LINE_MAJOR a 0. Ver doc/04-video.md
`default_nettype none
module newbrain_chargen #(
    parameter LINE_MAJOR = 1
) (
    input  wire        clk,           // lectura: reloj de pixel
    input  wire        wr_clk,        // escritura: sistema (carga de la ROM)
    input  wire [7:0]  char,
    input  wire [3:0]  line,
    output reg  [7:0]  dout,

    input  wire [11:0] wr_addr,
    input  wire [7:0]  wr_data,
    input  wire        wr_en
);
    reg [7:0] mem [0:4095];
    wire [11:0] addr = LINE_MAJOR ? {line, char} : {char, line};

    // Memoria de doble reloj: se escribe al cargar la ROM (sistema) y se
    // lee al pintar (pixel)
    always @(posedge wr_clk)
        if (wr_en) mem[wr_addr] <= wr_data;
    always @(posedge clk)
        dout <= mem[addr];
endmodule
`default_nettype wire
