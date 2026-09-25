//============================================================================
// NewBrain - COP420 de verdad
//
// Envuelve el core T400 con la circuiteria que lo rodea en la placa, para
// poder ejecutar la ROM original `cop420-guw.ic419` en vez del HLE.
//
// El cableado sale de MAME (`newbrain.cpp`):
//
//   IN0      K8, salida Q2 del latch CD4076 (teclado)
//   IN1..IN3 _RD, _CS y _WR del microbus hacia el Z80
//   L0..L7   bus de datos del microbus
//   G0 (out) _COPINT
//   G1, G3   (out) motores de los dos cassettes
//   G1..G3   (in)  el resto de bits del latch de teclado
//   D0       invertido a K4: reset del contador CD4024
//   D1       TDO, salida a cinta
//   D2       invertido a K6: reloj del CD4024 y del CD4076, y habilitacion
//            del DS8881
//   SO / SK  trama serie de 16 bits hacia el display fluorescente
//   SI       TDI = TPIN xor TDO
//
// La ventaja de hacerlo de verdad: **la modulacion de cinta deja de ser
// asunto nuestro**. El COP la hace con su propia ROM, igual que en la maquina
// original, asi que no hay que adivinar el formato. Ver doc/11-cinta.md
//
// El core viene de T400, convertido de VHDL a Verilog con GHDL para que
// Icarus pueda simularlo: ver tools/convierte_t400.sh. Asi la fase 5 entra en
// el mismo banco de pruebas que todo lo demas en vez de quedar a merced de
// Quartus y la placa.
//============================================================================
`default_nettype none

module newbrain_cop_real #(
    parameter integer COP_HZ = 2_565_000,
    parameter CLK_HZ = 32_000_000
) (
    input  wire        clk,
    input  wire        reset,

    // carga de la ROM del COP
    input  wire [9:0]  rom_wr_addr,
    input  wire [7:0]  rom_wr_data,
    input  wire        rom_wr_en,

    // puerto 06 del Z80
    input  wire        cs,
    input  wire        rd,
    input  wire        wr,
    input  wire [7:0]  din,
    output wire [7:0]  dout,
    output wire        copint_n,

    // matriz de teclado, 16 filas por 4 bits
    output wire [3:0]  kbd_row,
    input  wire [3:0]  kbd_col,

    // display fluorescente: trama serie de 16 bits
    output reg  [15:0] vfd_sr,
    output reg         vfd_latch,

    // cinta
    input  wire        tape_in,
    output wire        tape_out,
    output wire [1:0]  motor
);
    //------------------------------------------------------------------
    // Reloj del COP: CKI a 2,565 MHz, divisor interno de 16
    //
    // No estaba documentado en ningun sitio. Se deduce de The NewBrain
    // Dissected: el contador del sistema que avanza con cada interrupcion
    // del COP lo hace 50 veces por segundo. Con la ROM original del COP
    // entre interrupciones pasan 3206 ciclos de instruccion, lo fija su
    // propio bucle y no depende del Z80 (medido con tools/nbcopreal.py, las
    // dos ROMs de verdad frente a frente). 3206 ciclos en 20 ms son
    // 160,3 kHz de ciclo, o sea 2,565 MHz en CKI. A 4 MHz, lo que habia (y
    // lo que usa MAME), salen 78 interrupciones por segundo: el reloj del
    // sistema va un 56% rapido, y la cinta que graba el COP tambien.
    //
    // Se genera con un acumulador de fase: un pulso de ck_en cada 12,48
    // ciclos de 32 MHz de media, con una fluctuacion de un ciclo.
    //------------------------------------------------------------------
    localparam integer COP_HZ_L = COP_HZ;
    localparam integer PASO   = COP_HZ / 1000;        // en kHz
    localparam integer MODULO = CLK_HZ / 1000;
    reg [23:0] fase;
    reg        ck_en;
    always @(posedge clk) begin
        ck_en <= 1'b0;
        if (reset) begin
            fase <= 24'd0;
        end else if (fase + PASO >= MODULO) begin
            fase  <= fase + PASO - MODULO;
            ck_en <= 1'b1;
        end else begin
            fase  <= fase + PASO;
        end
    end

    //------------------------------------------------------------------
    // Secuencia de arranque
    //
    // El core exige que reset_n este bajo al menos tres ciclos de
    // instruccion despues de soltar el encendido, tal y como pide el manual
    // del COP400. Soltar los dos a la vez deja la CPU sin inicializar y el
    // PC clavado en cero.
    //------------------------------------------------------------------
    reg [7:0] res_cnt;
    reg       por_n, res_n;
    always @(posedge clk) begin
        if (reset) begin
            res_cnt <= 8'd0;
            por_n   <= 1'b0;
            res_n   <= 1'b0;
        end else begin
            por_n <= 1'b1;
            if (ck_en) begin
                if (res_cnt == 8'd255) res_n <= 1'b1;
                else res_cnt <= res_cnt + 1'b1;
            end
        end
    end

    //------------------------------------------------------------------
    // Memorias
    //------------------------------------------------------------------
    wire [9:0] pm_addr;
    wire [7:0] pm_data;
    wire [5:0] dm_addr;
    wire       dm_we;
    wire [3:0] dm_din, dm_dout;

    newbrain_cop_rom rom (
        .clk(clk), .addr(pm_addr), .dout(pm_data),
        .wr_addr(rom_wr_addr), .wr_data(rom_wr_data), .wr_en(rom_wr_en)
    );

    newbrain_cop_ram ram (
        .clk(clk), .ena(ck_en), .addr(dm_addr), .din(dm_din), .we(dm_we), .dout(dm_dout)
    );

    //------------------------------------------------------------------
    // Puertos del COP
    //------------------------------------------------------------------
    wire [7:0] l_o;
    wire [3:0] d_o, g_o;
    wire       so, sk, si;

    // El latch CD4076 presenta los cuatro bits de la fila de teclado
    // repartidos entre IN0 y G1..G3, que es como estan cableados.
    //------------------------------------------------------------------
    // Teclado: contador CD4024 de filas y biestable CD4076, como en MAME
    // (newbrain.cpp, cop_d_w / cop_g_r / cop_in_r)
    //
    //   D0 -> invertido, K4: reset del contador
    //   D2 -> invertido, K6: reloj del contador (flanco de BAJADA de K6),
    //         carga del CD4076 con la fila (flanco de SUBIDA de K6) y
    //         habilitacion de sus salidas (con K6 bajo leen todo unos)
    //
    //   El COP lee el CD4076 asi:
    //     G1 = Q1 (K9)   G2 = Q0 (K7)   G3 = Q3 (K3)   IN0 = Q2 (K8)
    //
    // Antes el envoltorio leia la fila del teclado directamente, sin el
    // biestable, con los bits cambiados de sitio, y el contador avanzaba en
    // el flanco de subida: el COP nunca veia una tecla donde la buscaba.
    //------------------------------------------------------------------
    reg [6:0] cd4024 = 7'd0;
    reg [3:0] cd4076 = 4'h0;
    reg       k6_d   = 1'b0;
    wire k4 = ~d_o[0];      // reset del contador
    wire k6 = ~d_o[2];      // reloj del contador y del biestable

    always @(posedge clk) begin
        k6_d <= k6;
        if (reset || k4)
            cd4024 <= 7'd0;
        else if (!k6 && k6_d)                   // K6 baja: siguiente fila
            cd4024 <= cd4024 + 1'b1;
        if (k6 && !k6_d)                        // K6 sube: se lee la fila
            cd4076 <= kbd_col;
    end

    wire [3:0] q403 = k6 ? cd4076 : 4'hF;       // salidas del CD4076

    assign kbd_row = cd4024[3:0];

    //------------------------------------------------------------------
    // Trama serie hacia el display fluorescente
    //------------------------------------------------------------------
    reg sk_d;
    always @(posedge clk) begin
        vfd_latch <= 1'b0;
        sk_d <= sk;
        if (reset) vfd_sr <= 16'd0;
        else if (sk && !sk_d) vfd_sr <= {vfd_sr[14:0], so};
        // el DS8881 se habilita con K6, que es cuando se vuelca la trama
        if (k6 && !k6_d) vfd_latch <= 1'b1;
    end

    //------------------------------------------------------------------
    // Cinta
    //------------------------------------------------------------------
    assign tape_out = d_o[1];
    // TDI = TPIN xor TDO, pero solo con algun motor en marcha (G1 y G3,
    // activos a nivel bajo). Mientras el COP saca por la linea serie los
    // datos del display, por SI le entra la cinta y lo que entra acaba en
    // la RAM que luego usa el barrido del teclado. Sin cinta, lo que hay en
    // la pata depende de como repose la entrada de audio de cada placa: si
    // TDI sale a uno, el COP deja de ver las teclas. Se encontro comparando
    // escritura a escritura en su RAM el t400 contra el nucleo de MAME.
    wire motor_en_marcha = ~g_o[1] | ~g_o[3];
    assign si       = motor_en_marcha ? (tape_in ^ tape_out) : 1'b0;   // TDI
    assign motor    = {g_o[3], g_o[1]};     // _TM2, _TM1
    // _COPINT = NOT G0. En MICROBUS el COP pide atencion poniendo G0 a UNO
    // y la escritura del Z80 lo devuelve a cero (t400_io_g lo hace solo).
    // MAME lo cablea igual: copint = !G0, activa a nivel bajo. Antes iba sin
    // invertir: el Z80 veia una interrupcion permanente mientras el COP no
    // pedia nada, leia y escribia a destiempo y el programa del COP acababa
    // descarrilado.
    assign copint_n = ~g_o[0];

    // Microbus: el Z80 ve el puerto 06 como el bus L del COP
    assign dout = l_o;

    //------------------------------------------------------------------
    // El core
    //------------------------------------------------------------------
    // Los genericos (COP420, divisor 16, MICROBUS) van horneados en la
    // conversion. Ver tools/convierte_t400.sh
    t400_core core (
        .ck_i(clk),
        .ck_en_i(ck_en),
        .por_n_i(por_n),
        .reset_n_i(res_n),
        .cko_i(1'b1),
        .pm_addr_o(pm_addr),
        .pm_data_i(pm_data),
        .dm_addr_o(dm_addr),
        .dm_we_o(dm_we),
        .dm_data_o(dm_din),
        .dm_data_i(dm_dout),
        .io_l_i(din),
        .io_l_o(l_o),
        .io_d_o(d_o),
        .io_g_i({q403[3], q403[0], q403[1], 1'b0}),
        .io_g_o(g_o),
        .io_in_i({~wr, ~cs, ~rd, q403[2]}),
        .si_i(si),
        .so_o(so), .so_en_o(),
        .sk_o(sk), .sk_en_o(),
        .io_l_en_o(), .io_d_en_o(), .io_g_en_o()
    );

endmodule

`default_nettype wire
