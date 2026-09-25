//============================================================================
// NewBrain - teclado
//
// La matriz es de 16 filas x 4 bits, recorrida en la maquina real por el
// contador CD4024 y leida por el COP a traves del latch CD4076.
//
// El byte que el COP entrega al Z80 tiene este formato:
//
//   b7 b6   modificador           b5..b0   codigo de matriz
//   0  0    normal
//   0  1    SHIFT
//   1  0    CONTROL
//   1  1    GRAPHICS
//
// y el codigo de matriz es:
//
//   codigo = columna * 16 + ((fila + 1) mod 16)
//
// donde la columna NO es el numero de bit de la matriz, sino el orden en que
// el COP los serializa: bit2 -> 0, bit1 -> 1, bit0 -> 2, bit3 -> 3.
//
// Esto no es una conjetura: se deduce de KTABLE, la tabla de 64 bytes en
// A1A7 de la ROM AB, contrastada posicion a posicion contra la matriz. Ver
// doc/03-teclado.md
//============================================================================
`default_nettype none

module newbrain_kbd #(
    parameter integer CLK_HZ = 32_000_000
) (
    input  wire        clk,
    input  wire        reset,

    input  wire [10:0] ps2_key,     // {strobe, pressed, extended, code}

    output wire [7:0]  key_byte,
    output wire        key_avail,
    input  wire        key_taken,

    output wire        brk,          // tecla STOP

    // Matriz cruda, para cuando manda el COP420 de verdad: el propio
    // microcontrolador recorre las filas con su contador CD4024.
    input  wire [3:0]  scan_row,
    output wire [3:0]  scan_col
);

    reg [3:0] matrix [0:15];
    reg       old_strobe;
    integer   i;

    wire       ps2_strobe   = ps2_key[10];
    wire       ps2_pressed  = ps2_key[9];
    wire       ps2_extended = ps2_key[8];
    wire [7:0] ps2_code     = ps2_key[7:0];

    //------------------------------------------------------------------
    // PS/2 -> posicion de matriz
    //------------------------------------------------------------------
    reg [3:0] row;
    reg [1:0] col;        // numero de bit dentro de la fila
    reg       valid;

    always @* begin
        row = 4'd0; col = 2'd0; valid = 1'b1;
        if (ps2_extended) begin
            case (ps2_code)
                8'h72: begin row = 4'd1;  col = 2'd0; end  // abajo
                8'h74: begin row = 4'd1;  col = 2'd1; end  // derecha
                8'h6B: begin row = 4'd1;  col = 2'd2; end  // izquierda
                8'h75: begin row = 4'd1;  col = 2'd3; end  // arriba
                8'h11: begin row = 4'd8;  col = 2'd1; end  // AltGr = VIDEO TEXT
                8'h70: begin row = 4'd12; col = 2'd3; end  // Insert
                8'h6C: begin row = 4'd14; col = 2'd3; end  // Inicio
                default: valid = 1'b0;
            endcase
        end else begin
            case (ps2_code)
                8'h76: begin row = 4'd0;  col = 2'd1; end  // Esc = STOP
                8'h3C: begin row = 4'd2;  col = 2'd0; end  // U
                8'h3E: begin row = 4'd2;  col = 2'd1; end  // 8
                8'h3D: begin row = 4'd2;  col = 2'd2; end  // 7
                8'h3B: begin row = 4'd2;  col = 2'd3; end  // J
                8'h43: begin row = 4'd3;  col = 2'd0; end  // I
                8'h46: begin row = 4'd3;  col = 2'd1; end  // 9
                8'h36: begin row = 4'd3;  col = 2'd2; end  // 6
                8'h31: begin row = 4'd3;  col = 2'd3; end  // N
                8'h35: begin row = 4'd4;  col = 2'd0; end  // Y
                8'h45: begin row = 4'd4;  col = 2'd1; end  // 0
                8'h2E: begin row = 4'd4;  col = 2'd2; end  // 5
                8'h3A: begin row = 4'd4;  col = 2'd3; end  // M
                8'h44: begin row = 4'd5;  col = 2'd0; end  // O
                8'h54: begin row = 4'd5;  col = 2'd1; end  // [ -> (
                8'h25: begin row = 4'd5;  col = 2'd2; end  // 4
                8'h41: begin row = 4'd5;  col = 2'd3; end  // ,
                8'h4B: begin row = 4'd6;  col = 2'd0; end  // L
                8'h5B: begin row = 4'd6;  col = 2'd1; end  // ] -> )
                8'h26: begin row = 4'd6;  col = 2'd2; end  // 3
                8'h49: begin row = 4'd6;  col = 2'd3; end  // .
                8'h4C: begin row = 4'd7;  col = 2'd0; end  // ;
                8'h52: begin row = 4'd7;  col = 2'd1; end  // ' -> *
                8'h1E: begin row = 4'd7;  col = 2'd2; end  // 2
                8'h32: begin row = 4'd7;  col = 2'd3; end  // B
                8'h33: begin row = 4'd8;  col = 2'd0; end  // H
                8'h16: begin row = 4'd8;  col = 2'd2; end  // 1
                8'h2A: begin row = 4'd8;  col = 2'd3; end  // V
                8'h34: begin row = 4'd9;  col = 2'd0; end  // G
                8'h4D: begin row = 4'd9;  col = 2'd1; end  // P
                8'h2C: begin row = 4'd9;  col = 2'd2; end  // T
                8'h21: begin row = 4'd9;  col = 2'd3; end  // C
                8'h2B: begin row = 4'd10; col = 2'd0; end  // F
                8'h55: begin row = 4'd10; col = 2'd1; end  // =
                8'h2D: begin row = 4'd10; col = 2'd2; end  // R
                8'h22: begin row = 4'd10; col = 2'd3; end  // X
                8'h23: begin row = 4'd11; col = 2'd0; end  // D
                8'h4E: begin row = 4'd11; col = 2'd1; end  // -
                8'h24: begin row = 4'd11; col = 2'd2; end  // E
                8'h1A: begin row = 4'd11; col = 2'd3; end  // Z
                8'h1B: begin row = 4'd12; col = 2'd0; end  // S
                8'h0E: begin row = 4'd12; col = 2'd1; end  // ` -> +
                8'h1D: begin row = 4'd12; col = 2'd2; end  // W
                8'h1C: begin row = 4'd13; col = 2'd0; end  // A
                8'h5A: begin row = 4'd13; col = 2'd1; end  // Intro = NEW LINE
                8'h15: begin row = 4'd13; col = 2'd2; end  // Q
                8'h42: begin row = 4'd13; col = 2'd3; end  // K
                8'h4A: begin row = 4'd14; col = 2'd0; end  // /
                8'h29: begin row = 4'd14; col = 2'd2; end  // espacio
                8'h12: begin row = 4'd15; col = 2'd0; end  // Shift izq
                8'h59: begin row = 4'd15; col = 2'd0; end  // Shift der
                8'h11: begin row = 4'd15; col = 2'd1; end  // Alt = GRAPHICS
                8'h0D: begin row = 4'd15; col = 2'd2; end  // Tab = REPEAT
                8'h14: begin row = 4'd15; col = 2'd3; end  // Ctrl = CONTROL
                default: valid = 1'b0;
            endcase
        end
    end

    // Fila 15 son los modificadores, no generan pulsacion por si mismos
    wire is_modifier = (row == 4'd15);

    wire shift_on = matrix[15][0];
    wire graph_on = matrix[15][1];
    wire ctrl_on  = matrix[15][3];

    assign brk = matrix[0][1];
    assign scan_col = matrix[scan_row];

    //------------------------------------------------------------------
    // Codificacion
    //------------------------------------------------------------------
    // columna de matriz -> orden de serializacion del COP
    function [1:0] col_order;
        input [1:0] c;
        case (c)
            2'd2: col_order = 2'd0;
            2'd1: col_order = 2'd1;
            2'd0: col_order = 2'd2;
            default: col_order = 2'd3;
        endcase
    endfunction

    wire [5:0] code = {col_order(col), 4'd0} + {2'd0, (row + 4'd1)};

    // b7 b6: 00 normal, 01 shift, 10 control, 11 graphics
    wire [1:0] mods = ctrl_on ? (graph_on ? 2'b11 : 2'b10)
                              : (graph_on ? 2'b11 : {1'b0, shift_on});

    //------------------------------------------------------------------
    // Cola de pulsaciones
    //
    // Antes cabia una sola tecla en espera, y si llegaba otra antes de que
    // el COP recogiera la primera, la pisaba. Con el receptor PS/2 nuevo los
    // eventos llegan en cuanto se teclean y, escribiendo rapido, se solapan:
    // se perdian pulsaciones. Ocho sitios dan para cualquier racha humana.
    //------------------------------------------------------------------
    reg [7:0] cola [0:7];
    reg [2:0] c_esc, c_lee;
    reg [3:0] c_n;
    assign key_avail = (c_n != 4'd0);
    assign key_byte  = cola[c_lee];

    localparam integer MIN_PULSO = CLK_HZ / 1000 * 60;      // 60 ms
    reg  [3:0]  ult_fila;
    reg  [1:0]  ult_col;
    reg  [23:0] edad;
    reg         pend;

    wire mete = (ps2_strobe != old_strobe) && valid && ps2_pressed && !is_modifier;
    wire saca = key_taken && (c_n != 4'd0);

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) matrix[i] <= 4'b0000;
            old_strobe <= 1'b0;
            pend  <= 1'b0;
            edad  <= MIN_PULSO;
            ult_fila <= 4'd0;
            ult_col  <= 2'd0;
            c_esc <= 3'd0;
            c_lee <= 3'd0;
            c_n   <= 4'd0;
        end else begin
            old_strobe <= ps2_strobe;

            // Matriz, con una duracion minima por pulsacion. El COP real
            // barre el teclado cada 20 ms y solo da por buena una tecla que
            // ve estable, asi que una pulsacion muy corta (se teclea mucho
            // mas deprisa en un PS/2 que en el teclado original) se perdia.
            // Si una tecla se suelta antes de MIN_PULSO, la suelta se aplaza
            // hasta cumplirlo. Solo se aplaza una a la vez: si llega otra
            // suelta con una pendiente, la pendiente se aplica ya.
            if (ps2_strobe != old_strobe && valid) begin
                if (ps2_pressed) begin
                    matrix[row][col] <= 1'b1;
                    if (!pend) begin
                        ult_fila <= row;
                        ult_col  <= col;
                        edad     <= 0;
                    end
                end else if (row == ult_fila && col == ult_col
                             && edad < MIN_PULSO) begin
                    pend <= 1'b1;               // aun no: se suelta luego
                end else begin
                    matrix[row][col] <= 1'b0;
                    if (pend) begin
                        matrix[ult_fila][ult_col] <= 1'b0;
                        pend <= 1'b0;
                    end
                end
            end else if (edad < MIN_PULSO) begin
                edad <= edad + 1'b1;
            end else if (pend) begin
                matrix[ult_fila][ult_col] <= 1'b0;
                pend <= 1'b0;
            end

            // solo la pulsacion, y no la de un modificador, genera evento;
            // con la cola llena se pierde la nueva, no las que esperan
            if (mete && c_n != 4'd8) begin
                cola[c_esc] <= {mods, code};
                c_esc <= c_esc + 1'b1;
            end
            if (saca) c_lee <= c_lee + 1'b1;
            c_n <= c_n + ((mete && c_n != 4'd8) ? 4'd1 : 4'd0) - (saca ? 4'd1 : 4'd0);
        end
    end

endmodule

`default_nettype wire
