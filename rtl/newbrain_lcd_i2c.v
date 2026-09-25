//============================================================================
// NewBrain - pantalla LCD de 16x2 por I2C, como LiquidCrystal_I2C de Arduino
//
// El modulo I2C de siempre: un PCF8574 detras de un HD44780, cableado asi
// (el de la libreria LiquidCrystal_I2C):
//
//   P0 RS   P1 RW   P2 E   P3 retroiluminacion   P4..P7 D4..D7
//
// El HD44780 va en modo de 4 bits. Cada byte al HD44780 son cuatro bytes al
// PCF8574 en una sola transaccion I2C: nibble alto con E a uno, igual con E
// a cero (el HD44780 lo coge en esa bajada), y lo mismo con el nibble bajo.
// A 100 kHz cada byte I2C dura 90 us, asi que E dura 90 us (pide 450 ns) y
// entre dos ordenes pasan de sobra los 37 us que tarda el HD44780.
//
// Solo escribe; no mira los ACK. Si no hay pantalla, no pasa nada.
//
// Arranque (la secuencia de la hoja del HD44780 para 4 bits):
//   50 ms de espera, 3 x "3" con esperas de 5 ms y 1 ms, "2" (a 4 bits),
//   28 (2 lineas, 5x8), 0C (encendida, sin cursor), 06 (avanza), 01
//   (borra, 2 ms).
// Despues refresca las dos lineas sin parar: 80 + 16 caracteres, C0 + 16.
// Son unos 16 ms por vuelta.
//
// OJO con la tension: los modulos I2C llevan resistencias a 5 V en SDA y
// SCL. Hay que alimentarlos a 3,3 V o poner un adaptador de niveles.
//============================================================================
`default_nettype none

module newbrain_lcd_i2c #(
    parameter integer CLK_HZ = 32_000_000,
    parameter integer I2C_HZ = 100_000
) (
    input  wire         clk,
    input  wire         reset,
    input  wire [6:0]   direccion,     // 27h, 3Fh...
    input  wire [127:0] linea1,        // 16 caracteres, el de la izquierda arriba
    input  wire [127:0] linea2,
    output wire         scl,           // 1 = suelto (colector abierto)
    output wire         sda
);
    //------------------------------------------------------------------
    // Maestro I2C de solo escritura
    //
    // cuarto de periodo de SCL: cada paso del bit ocupa un cuarto
    //------------------------------------------------------------------
    localparam integer CUARTO = CLK_HZ / (I2C_HZ * 4);
    reg [15:0] div;
    wire       tic = (div == 16'd0);
    always @(posedge clk)
        div <= (reset || div == 16'd0) ? CUARTO[15:0] - 1'b1 : div - 1'b1;

    reg        scl_r = 1'b1, sda_r = 1'b1;
    assign scl = scl_r;
    assign sda = sda_r;

    // una transaccion: direccion + n bytes (hasta 4) y parada
    reg [7:0]  tx [0:4];
    reg [2:0]  tx_n;              // bytes de datos
    reg        tx_go;
    reg        tx_busy;
    reg [3:0]  bit_i;             // 8 bits + ACK
    reg [2:0]  byte_i;
    reg [1:0]  fase;              // cuarto del bit
    reg [2:0]  i2c_e;
    localparam I_REPOSO = 3'd0, I_START = 3'd1, I_BIT = 3'd2, I_STOP = 3'd3;

    always @(posedge clk) begin
        if (reset) begin
            i2c_e   <= I_REPOSO;
            tx_busy <= 1'b0;
            scl_r   <= 1'b1;
            sda_r   <= 1'b1;
        end else begin
            if (tx_go && !tx_busy) begin
                tx_busy <= 1'b1;
                i2c_e   <= I_START;
                fase    <= 2'd0;
            end else if (tic) case (i2c_e)
            I_START: begin
                // SDA baja con SCL alto; luego baja SCL
                case (fase)
                2'd0: begin sda_r <= 1'b1; scl_r <= 1'b1; end
                2'd1: sda_r <= 1'b0;
                2'd2: scl_r <= 1'b0;
                2'd3: begin i2c_e <= I_BIT; bit_i <= 4'd0; byte_i <= 3'd0; end
                endcase
                fase <= fase + 1'b1;
            end
            I_BIT: begin
                case (fase)
                2'd0: sda_r <= (bit_i == 4'd8) ? 1'b1          // ACK: se suelta
                                               : tx[byte_i][3'd7 - bit_i[2:0]];
                2'd1: scl_r <= 1'b1;
                2'd2: ;
                2'd3: begin
                    scl_r <= 1'b0;
                    if (bit_i == 4'd8) begin
                        bit_i <= 4'd0;
                        if (byte_i == tx_n) i2c_e <= I_STOP;
                        else                byte_i <= byte_i + 1'b1;
                    end else
                        bit_i <= bit_i + 1'b1;
                end
                endcase
                fase <= fase + 1'b1;
            end
            I_STOP: begin
                // SDA sube con SCL alto
                case (fase)
                2'd0: sda_r <= 1'b0;
                2'd1: scl_r <= 1'b1;
                2'd2: sda_r <= 1'b1;
                2'd3: begin i2c_e <= I_REPOSO; tx_busy <= 1'b0; end
                endcase
                fase <= fase + 1'b1;
            end
            default: ;
            endcase
        end
    end

    //------------------------------------------------------------------
    // HD44780 a traves del PCF8574
    //------------------------------------------------------------------
    localparam [7:0] BL = 8'h08, EN = 8'h04, RS = 8'h01;

    // espera en milisegundos
    localparam integer MS = CLK_HZ / 1000;
    reg [31:0] espera;

    reg [4:0]  paso;              // secuencia de arranque
    reg [5:0]  car;               // 0..33 en el refresco
    reg        arrancado;
    reg [2:0]  lcd_e;
    localparam L_ESPERA = 3'd0, L_ENVIA = 3'd1, L_FIN_ENVIO = 3'd2, L_SIGUE = 3'd3;

    // Lo que toca mandar ahora: nibble suelto (solo arranque) o byte
    reg        solo_nibble;
    reg [7:0]  valor;
    reg        es_dato;

    // caracter k (0..15) de una linea
    function [7:0] car_de(input [127:0] l, input [3:0] k);
        car_de = l[127 - 8*k -: 8];
    endfunction

    // arma la transaccion de un nibble o de un byte
    task arma(input [7:0] v, input dato, input nib);
        reg [7:0] rs;
        begin
            rs = (dato ? RS : 8'h00) | BL;
            tx[0] <= {direccion, 1'b0};
            if (nib) begin
                tx[1] <= {v[3:0], 4'h0} | rs | EN;
                tx[2] <= {v[3:0], 4'h0} | rs;
                tx_n  <= 3'd2;
            end else begin
                tx[1] <= {v[7:4], 4'h0} | rs | EN;
                tx[2] <= {v[7:4], 4'h0} | rs;
                tx[3] <= {v[3:0], 4'h0} | rs | EN;
                tx[4] <= {v[3:0], 4'h0} | rs;
                tx_n  <= 3'd4;
            end
        end
    endtask

    always @(posedge clk) begin
        tx_go <= 1'b0;
        if (reset) begin
            lcd_e     <= L_ESPERA;
            espera    <= 32'd50 * MS;     // el HD44780 pide 40 ms tras encender
            paso      <= 5'd0;
            car       <= 6'd0;
            arrancado <= 1'b0;
        end else case (lcd_e)
        L_ESPERA:
            if (espera != 0) espera <= espera - 1'b1;
            else lcd_e <= L_SIGUE;
        L_SIGUE: begin
            // decide lo siguiente que se manda
            if (!arrancado) begin
                case (paso)
                5'd0: begin arma(8'h03, 1'b0, 1'b1); espera <= 5 * MS; end
                5'd1: begin arma(8'h03, 1'b0, 1'b1); espera <= 1 * MS; end
                5'd2: begin arma(8'h03, 1'b0, 1'b1); espera <= 1 * MS; end
                5'd3: begin arma(8'h02, 1'b0, 1'b1); espera <= 1 * MS; end
                5'd4: begin arma(8'h28, 1'b0, 1'b0); espera <= 0; end
                5'd5: begin arma(8'h0C, 1'b0, 1'b0); espera <= 0; end
                5'd6: begin arma(8'h06, 1'b0, 1'b0); espera <= 0; end
                default: begin arma(8'h01, 1'b0, 1'b0); espera <= 2 * MS; end
                endcase
                if (paso == 5'd7) arrancado <= 1'b1;
                paso <= paso + 1'b1;
            end else begin
                // refresco: 0 = 80, 1..16 linea 1, 17 = C0, 18..33 linea 2
                if (car == 6'd0)       arma(8'h80, 1'b0, 1'b0);
                else if (car <= 6'd16) arma(car_de(linea1, car - 6'd1), 1'b1, 1'b0);
                else if (car == 6'd17) arma(8'hC0, 1'b0, 1'b0);
                else                   arma(car_de(linea2, car - 6'd18), 1'b1, 1'b0);
                car    <= (car == 6'd33) ? 6'd0 : car + 1'b1;
                espera <= 0;
            end
            tx_go <= 1'b1;
            lcd_e <= L_ENVIA;
        end
        L_ENVIA:
            if (tx_busy) lcd_e <= L_FIN_ENVIO;
        L_FIN_ENVIO:
            if (!tx_busy) lcd_e <= L_ESPERA;
        default: lcd_e <= L_ESPERA;
        endcase
    end
endmodule

`default_nettype wire
