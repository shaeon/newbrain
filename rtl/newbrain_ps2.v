//============================================================================
// NewBrain - teclado PS/2 recibido por la linea serie de user_io
//
// Por que no se usa key_strobe/key_pressed de user_io: esa interfaz arma
// cada tecla dando por hecho que el firmware manda la secuencia entera (E0,
// F0 y el codigo) en UNA sola transferencia SPI; el estado del prefijo se
// reinicia al empezar cada transferencia. El firmware de la SiDi manda un
// byte por transferencia, asi que el F0 se perdia por el camino y cada
// SOLTAR llegaba como otra PULSACION:
//
//   * dos caracteres por tecla;
//   * y peor, SHIFT, CONTROL y GRAPHICS se quedaban pegados, porque su
//     "soltar" los volvia a apretar: parecia que el juego de caracteres del
//     teclado habia cambiado.
//
// user_io tambien saca el teclado como PS/2 serie, byte a byte, y ahi el
// prefijo nunca se pierde, se trocee como se trocee la SPI. Este modulo lo
// recibe y guarda el estado de E0 y F0 entre bytes.
//
// Salida con el mismo formato que usa newbrain_kbd.v, el de MiSTer:
//   {conmuta, pulsada, extendida, codigo}
// donde `conmuta` cambia de valor con cada tecla (no es un pulso).
//============================================================================
`default_nettype none

module newbrain_ps2 (
    input  wire        clk,
    input  wire        reset,
    input  wire        ps2_clk,
    input  wire        ps2_data,
    output reg  [10:0] ps2_key = 11'd0
);
    // sincronizacion y flanco de bajada del reloj PS/2
    reg [2:0] clk_s  = 3'b111;
    reg [1:0] dat_s  = 2'b11;
    always @(posedge clk) begin
        clk_s <= {clk_s[1:0], ps2_clk};
        dat_s <= {dat_s[0], ps2_data};
    end
    wire bajada = clk_s[2] & ~clk_s[1];

    // Trama: inicio (0), 8 bits empezando por el de menos peso, paridad y
    // parada (1). Si pasa mucho sin flancos se empieza de cero, para no
    // quedarse desalineado para siempre por un bit perdido.
    reg [10:0] sr;
    reg [3:0]  nbits;
    reg [15:0] quieto;
    reg        e0, f0;

    wire [10:0] trama = {dat_s[1], sr[10:1]};

    always @(posedge clk) begin
        if (reset) begin
            nbits  <= 4'd0;
            quieto <= 16'd0;
            e0     <= 1'b0;
            f0     <= 1'b0;
        end else begin
            if (bajada) begin
                quieto <= 16'd0;
                sr     <= trama;
                if (nbits == 4'd10) begin
                    nbits <= 4'd0;
                    // trama completa: inicio a 0 y parada a 1
                    if (!trama[0] && trama[10]) begin
                        case (trama[8:1])
                        8'hE0: e0 <= 1'b1;
                        8'hF0: f0 <= 1'b1;
                        default: begin
                            ps2_key <= {~ps2_key[10], ~f0, e0, trama[8:1]};
                            e0 <= 1'b0;
                            f0 <= 1'b0;
                        end
                        endcase
                    end
                end else begin
                    nbits <= nbits + 1'b1;
                end
            end else if (quieto != 16'hFFFF) begin
                quieto <= quieto + 1'b1;
                if (quieto == 16'hFFFE) nbits <= 4'd0;   // ~2 ms sin reloj
            end
        end
    end
endmodule

`default_nettype wire
