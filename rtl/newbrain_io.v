//============================================================================
// NewBrain - decodificacion y registros de E/S
//
// El decodificado usa SOLO A4..A2, asi que cada puerto se repite cada 32.
// Nombres tomados de los listados simbolicos de la ROM (EFROM.BLST):
//
//   grupo A4:A2 = 001 (EXP1)   A1:A0 = 00 -> 04  INTCON / CLCLK  (rd o wr)
//                              A1:A0 = 10 -> 06  COP   (microbus, rd/wr)
//                              A1:A0 = 11 -> 07  ENREG / ENRG1   (wr)
//   grupo A4:A2 = 010 (TVL)    A0 = 0    -> 08  TVLATCH (wr)
//                              A0 = 1    -> 09  TVLL    (wr)
//   grupo A4:A2 = 011 (TVTL)             -> 0C  registro de modo (wr)
//   grupo A4:A2 = 101 (UST)    A1 = 0    -> 14  UST_A   (rd)
//                              A1 = 1    -> 16  UST_B   (rd)
//
// Con el modulo de expansion presente el decodificado pasa a usar A0-A7
// completos y aparecen puertos propios suyos (Apendice F):
//
//   01  ENREG2   registro de habilitacion 2      (wr)
//   03  registro paralelo enclavado, Centronics  (wr)
//   15  UST2     registro de estado 2            (rd)
//
// Sin expansion, el 15 es un alias del 14, que es lo que hacia antes.
//
// ENRG1: b0 _CLK  b2 TVP  b4 _RTSD  b5 DO  b7 PO
//
// UST_A, segun los listados de ROM (no segun MAME, ver doc/01-hardware.md):
//   b0 multiplexado por ENRG1[7:6]   b1 multiplexado por ENRG1[5:4]
//   b2 MAINSP (1 = hay red)   b5 _CLKINT   b7 _COPINT
//
//   ENRG1[7:6]  b0                  ENRG1[5:4]  b1
//   00          EXTEST              00          POWTEST (1 = arrancando)
//   01          40/80~              01          TVC~ (0 = consola de TV)
//   10          entrada de cinta    10          modelo
//   11          indicador llamada   11          indicador llamada
//
// El reparto sale de uNBIO.pas (cdesp). Las polaridades de 40/80~ y TVC~
// son las que da hoy el core y con las que la ROM arranca en TV: en E06E
// la ROM escribe 52 en ENREG, lee, y solo deja la consola en TV si TVC~ = 0.
// UST_B: b0 RDDK  b1 _CTSD  b5 TPIN  b7 _CTSP   (base 0x5C)
//
// INT = (!_CLK && !_CLKINT) || !_COPINT
//============================================================================
`default_nettype none

module newbrain_io (
    input  wire        clk,
    input  wire        reset,

    // bus Z80
    input  wire [7:0]  addr,
    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    output wire        dout_oe,
    input  wire        iorq_n,
    input  wire        m1_n,
    input  wire        rd_n,
    input  wire        wr_n,
    output wire        int_n,

    // entradas de estado
    input  wire        eim,          // hay modulo de expansion
    input  wire        cfg_rev_video,// arranque en video inverso
    input  wire        cfg_40col,    // arranque en 40 columnas
    input  wire        cfg_tv,       // se quiere pantalla al arrancar
    input  wire        pwrup,        // 1 = mapa de memoria ya asentado
    input  wire        extest,       // UST_A b0
    input  wire        mains_ok,     // UST_A b2, 1 = alimentacion de red
    input  wire        tape_in,      // TPIN
    input  wire        cass_leyendo, // hay una lectura de cinta en curso
    input  wire        v24_rxd,      // RDDK
    input  wire        v24_cts_n,    // _CTSD
    input  wire        prn_cts_n,    // _CTSP
    input  wire        clkint_tick,  // pulso de 1 ciclo a 50 Hz

    // COP420 (fase 3; de momento stub)
    output wire        cop_cs,
    output wire        cop_rd,
    output wire        cop_wr,
    input  wire [7:0]  cop_dout,
    input  wire        copint_n,

    // salidas de control
    output reg  [7:0]  enrg1,
    output reg  [7:0]  enrg2,        // solo con expansion
    output reg  [7:0]  prn_latch,    // salida paralela enclavada
    output wire        tv_enable,    // ENRG1 bit 2 (TVP)
    output reg  [7:0]  tvtl,         // registro de modo de video
    output reg  [15:0] tv_addr,      // contador de direccion de video
    output reg         tv_load       // strobe de inicio de trama
);

    // Un ciclo de E/S valido; M1 alto descarta el ciclo de reconocimiento de INT
    wire io_cyc = ~iorq_n & m1_n;
    wire io_rd  = io_cyc & ~rd_n;
    wire io_wr  = io_cyc & ~wr_n;

    wire [2:0] grp = addr[4:2];

    wire sel_exp1 = (grp == 3'd1);
    wire sel_tvl  = (grp == 3'd2);
    wire sel_tvtl = (grp == 3'd3);
    wire sel_ust  = (grp == 3'd5);

    // Puertos del modulo de expansion, con decodificado completo
    wire sel_enrg2 = eim & (addr == 8'd1);
    wire sel_prn   = eim & (addr == 8'd3);
    wire sel_ust2  = eim & (addr == 8'd21);

    wire sel_clclk = sel_exp1 & (addr[1:0] == 2'b00);
    wire sel_cop   = sel_exp1 & (addr[1:0] == 2'b10);
    wire sel_enrg1 = sel_exp1 & (addr[1:0] == 2'b11);

    assign cop_cs = sel_cop & io_cyc;
    assign cop_rd = sel_cop & io_rd;
    assign cop_wr = sel_cop & io_wr;

    assign dout_oe = io_rd & (sel_cop | sel_ust | sel_ust2);
    assign tv_enable = enrg1[2];

    //------------------------------------------------------------------
    // Interrupcion de reloj
    //------------------------------------------------------------------
    // clkint = 0 significa pendiente. El tick de 50 Hz la activa, y una
    // lectura o escritura de INTCON (04) la borra.
    reg clkint;

    always @(posedge clk) begin
        if (reset) begin
            clkint <= 1'b1;
        end else begin
            if (clkint_tick)              clkint <= 1'b0;
            if (sel_clclk & (io_rd | io_wr)) clkint <= 1'b1;
        end
    end

    assign int_n = ~(((~enrg1[0]) & (~clkint)) | (~copint_n));

    //------------------------------------------------------------------
    // Escrituras
    //------------------------------------------------------------------
    always @(posedge clk) begin
        tv_load <= 1'b0;

        if (reset) begin
            enrg1     <= 8'h00;   // igual que machine_reset: enrg_w(0)
            enrg2     <= 8'h00;
            prn_latch <= 8'h00;
            tvtl    <= 8'h00;
            tv_addr <= 16'h0000;
        end else if (io_wr) begin
            if (sel_enrg1) enrg1     <= din;
            if (sel_enrg2) enrg2     <= din;
            if (sel_prn)   prn_latch <= din;
            if (sel_tvtl)  tvtl  <= din;
            if (sel_tvl) begin
                if (addr[0]) begin
                    // 09 TVLL: carga la base (granularidad de 128) y arranca la trama
                    tv_addr <= {din, 7'b0};
                    tv_load <= 1'b1;
                end else begin
                    // 08 TVLATCH: suma el offset extra de 64 bytes
                    tv_addr[6] <= 1'b1;
                end
            end
        end
    end

    //------------------------------------------------------------------
    // Lecturas
    //------------------------------------------------------------------
    // Selector de banco: se carga al escribir ENREG y se borra al TERMINAR
    // la lectura de UST_A, no al empezarla: si no, el dato cambiaria a mitad
    // del ciclo y el Z80 muestrearia ya el banco por defecto.
    reg [3:0] ust_sel;
    reg       ust_rd_d;
    wire      ust_rd = io_rd & sel_ust;

    always @(posedge clk) begin
        ust_rd_d <= ust_rd;
        if (reset) begin
            ust_sel <= 4'b0000;
        end else if (io_wr & sel_enrg1) begin
            ust_sel <= din[7:4];
        end else if (~ust_rd & ust_rd_d) begin
            ust_sel <= 4'b0000;
        end
    end

    reg ust_b0, ust_b1;
    always @* begin
        case (ust_sel[3:2])
        2'b00:   ust_b0 = extest;
        2'b01:   ust_b0 = 1'b1;           // 40/80~, lo de siempre
        2'b10:   ust_b0 = ~cass_leyendo;  // como cdesp: 0 mientras lee
        default: ust_b0 = 1'b1;           // sin indicador de llamada
        endcase
        case (ust_sel[1:0])
        2'b00:   ust_b1 = ~pwrup;
        2'b01:   ust_b1 = 1'b0;           // TVC~: la consola es la TV
        default: ust_b1 = 1'b1;
        endcase
    end

    always @* begin
        dout = 8'hFF;
        if (sel_ust2) begin
            // Registro de estado 2, configuracion de arranque (Apendice F):
            //   D2 uno = video normal, cero = inverso
            //   D3 uno = alimentacion de red
            //   D4 uno = 40 columnas, cero = 80
            //   D6 uno = se quiere pantalla
            // Los demas se leen a uno.
            dout = {1'b1, cfg_tv, 1'b1, cfg_40col,
                    mains_ok, ~cfg_rev_video, 1'b1, 1'b1};
        end else if (sel_ust) begin
            if (addr[1])
                dout = {prn_cts_n, 1'b1, tape_in, 3'b111, v24_cts_n, v24_rxd};
            else
                // POWTEST vale 1 MIENTRAS se arranca y 0 cuando el mapa ya
                // esta asentado: la ROM hace BIT 1,A / JR NZ y espera al 0.
                dout = {copint_n, 1'b1, clkint, 2'b11, mains_ok, ust_b1, ust_b0};
        end else if (sel_cop) begin
            dout = cop_dout;
        end
    end

endmodule

`default_nettype wire
