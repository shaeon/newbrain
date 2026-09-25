// Memorias del COP420: 1K de ROM cargable desde la SD y 64 nibbles de RAM.
`default_nettype none

module newbrain_cop_rom (
    input  wire       clk,
    input  wire [9:0] addr,
    output reg  [7:0] dout,
    input  wire [9:0] wr_addr,
    input  wire [7:0] wr_data,
    input  wire       wr_en
);
    reg [7:0] mem [0:1023];
    always @(posedge clk) begin
        if (wr_en) mem[wr_addr] <= wr_data;
        dout <= mem[addr];
    end
endmodule

module newbrain_cop_ram (
    input  wire       clk,
    input  wire       ena,          // la habilitacion de reloj del core
    input  wire [5:0] addr,
    input  wire [3:0] din,
    input  wire       we,
    output reg  [3:0] dout
);
    // SINCRONA y con habilitacion, como la generic_ram_ena del sistema
    // t420 original de Arnim Laeuger: la salida solo se actualiza en los
    // ciclos de ck_en. Con una RAM asincrona (lo que habia antes) el core
    // recogia el dato cuando la direccion ya habia vuelto a otra posicion:
    // LDD 1,15 leia RAM[0][13] en vez de RAM[1][15] y el COP no llegaba a
    // mandar nunca una tecla. Se encontro comparando escritura a escritura
    // la RAM del t400 contra el nucleo de MAME portado a Python.
    reg [3:0] mem [0:63];
    // A cero, como la deja Quartus al configurar la FPGA
    integer k;
    initial begin
        for (k = 0; k < 64; k = k + 1) mem[k] = 4'h0;
        dout = 4'h0;
    end
    always @(posedge clk) if (ena) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule

`default_nettype wire
