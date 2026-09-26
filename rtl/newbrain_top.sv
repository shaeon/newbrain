//============================================================================
// NewBrain: top comun a las placas tipo MiST
//
//   Calypso   (CYC1000, Cyclone 10 LP + RP2040)  proyecto en calypso/
//   SiDi      (Cyclone IV EP4CE22)                proyecto en sidi/, macro SIDI
//   MiST      (Cyclone III EP3C25)                proyecto en mist/, macro MIST
//   Poseidon  (Cyclone IV GX EP4CGX150)           proyecto en poseidon/,
//                                                 macro POSEIDON
//
// Lo unico que cambia entre placas es el reloj de entrada (12 o 27 MHz), los
// LEDs (ocho o uno), los bits de VGA (4 o 6) y el audio (I2S o sigma-delta).
// Todo lo demas, incluido el reloj interno de 32 MHz, es igual: cada
// proyecto trae su propio PLL con el mismo nombre y las mismas salidas.
//
// Estructura tomada de common/template de calypso-ports y, para la SiDi, del
// core de Oric de rampa069 (Oric_Mist_48K/sidi).
//============================================================================
`default_nettype none

// Placas con un solo LED, y placas con reloj de 27 MHz y VGA de 6 bits
`ifdef SIDI
`define UN_SOLO_LED
`define RELOJ_27
`endif
`ifdef MIST
`define UN_SOLO_LED
`define RELOJ_27
`endif
`ifdef POSEIDON
`define UN_SOLO_LED
`endif

module newbrain_top(
`ifdef RELOJ_27
    input         CLOCK_27,
`elsif POSEIDON
    input         CLOCK_50,
`else
    input         CLK12M,
`endif
`ifdef UN_SOLO_LED
    output        LED,          // uno solo, activo a nivel bajo como en MiST
`else
    output [7:0]  LED,
`endif

    output [VGA_BITS-1:0] VGA_R,
    output [VGA_BITS-1:0] VGA_G,
    output [VGA_BITS-1:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,

    input         SPI_SCK,
    inout         SPI_DO,
    input         SPI_DI,
    input         SPI_SS2,
    input         SPI_SS3,
    input         CONF_DATA0,
`ifndef NO_DIRECT_UPLOAD
    input         SPI_SS4,
`endif

`ifdef I2S_AUDIO
    output        I2S_BCK,
    output        I2S_LRCK,
    output        I2S_DATA,
`endif

`ifdef DELTASIGMA_AUDIO
    // Para placas sin I2S: salida sigma-delta de un bit por canal, con el
    // filtro RC en la placa (ver common/mist-modules/dac.vhd)
    output        AUDIO_L,
    output        AUDIO_R,
`endif

`ifdef USE_AUDIO_IN
    input         AUDIO_IN,
`endif

    // ---- Extras, cada uno detras de su macro (ver el .qsf de cada placa) ----
`ifdef NB_SERIE
    // Los dos puertos serie del NewBrain, en niveles TTL y reposo a 1
    // (para un conector RS232 hace falta un MAX3232 o similar)
    output        V24_TXD,
    output        V24_RTS,      // _RTSD, activo a nivel bajo
    input         V24_RXD,
    input         V24_CTS,      // _CTSD, activo a nivel bajo
    output        PRN_TXD,
    input         PRN_CTS,      // _CTSP, activo a nivel bajo
`endif
`ifdef NB_REMOTE
    // Remote de las cintas: a 1 con el motor en marcha (para un transistor
    // o un rele)
    output        TAPE_REMOTE1,
    output        TAPE_REMOTE2,
`endif
`ifdef NB_LCD
    // Pantalla LCD de 16x2 por I2C (modulo PCF8574, LiquidCrystal_I2C).
    // Colector abierto: las resistencias de subida las pone el modulo. OJO:
    // suelen ir a 5 V; alimentarlo a 3,3 V o con adaptador de niveles.
    inout         LCD_SDA,
    output        LCD_SCL,
`endif

    output [12:0] SDRAM_A,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nWE,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nCS,
    output [1:0]  SDRAM_BA,
    output        SDRAM_CLK,
    output        SDRAM_CKE
);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`elsif RELOJ_27
localparam VGA_BITS = 6;      // la SiDi y el MiST llevan 6 bits por color
`elsif POSEIDON
localparam VGA_BITS = 6;      // y la Poseidon tambien
`else
localparam VGA_BITS = 4;
`endif

`ifdef RELOJ_27
wire clk_entrada = CLOCK_27;
`elsif POSEIDON
wire clk_entrada = CLOCK_50;
`else
wire clk_entrada = CLK12M;
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
`define SEP "-;",
`else
localparam bit BIG_OSD = 0;
`define SEP
`endif

`ifdef USE_AUDIO_IN
wire TAPE_IN = AUDIO_IN;
`else
wire TAPE_IN = 1'b0;
`endif

`include "build_id.v"
parameter CONF_STR = {
    "NEWBRAIN;;",
    // Indice 0: el firmware la carga **sola** al arrancar el core, buscando en
    // la SD un fichero que se llame como el core con esta extension, o sea
    // NEWBRAIN.ROM. Con indice 1 no se carga sola y hay que ir al menu, que
    // es justo lo que pasaba.
    "F0,ROM,Reload ROM;",
    "F2,BASBIN,Load tape;",
    // Imagenes de disco montadas por el firmware: las escrituras van a la SD
    "S0U,DSK,Drive A:;",
    "S1U,DSK,Drive B:;",
    `SEP
    "O45,Scanlines,Off,25%,50%,75%;",
    "O6,Boot,Real 5.6s,Fast;",
    "O7,Disk ROM,No,Yes;",
    "O89,RAM,32K,96K,512K,768K;",
    "OBD,H centre,0,+8,+16,+24,-32,-24,-16,-8;",
    "OEG,V centre,0,+2,+4,+6,-8,-6,-4,-2;",
    "OIJ,Monitor,White,Green,Amber,Cyan;",
    "OK,Aspect,Original,Wide;",
    "OMN,I2C LCD address,27h,3Fh,20h,38h;",
    "OH,Tape monitor,No,Yes;",
    "OP,Test tone,No,Yes;",
    "OL,Tape source,File,Audio in;",
    "TQ,Rewind tape;",
    `SEP
    "T0,Reset;",
    "V,",`BUILD_VERSION,"-",`BUILD_DATE
};

/////////////////  RELOJES  ///////////////////////
// 12 MHz -> 32 MHz. El Z80 va a 32/8 = 4,000 MHz y el punto de video a
// 32/2 = 16 MHz, igual que el cristal de 16 MHz de la maquina real.
wire clk_sys, clk_sdram, clk_27, clk_32v;
wire pll_locked;

// c1 es el reloj del sistema, y de el sale tambien el de la SDRAM (ver
// sdramclk_ddr). c0 ya no se usa: se deja para no regenerar el PLL de cada
// placa, y Quartus lo quita.
pll pll(
    .inclk0(clk_entrada),       // 12 MHz Calypso, 27 SiDi, 50 Poseidon
    .c0(clk_sdram),     // sin usar
    .c1(clk_sys),       // 32 MHz
    .c2(clk_27),        // 27 MHz: pixel en Wide
    .c3(clk_32v),       // 32 MHz: pixel en Original
    .locked(pll_locked)
);

// El reloj de la SDRAM es clk_sys invertido, sacado por un registro DDR del
// propio pin (altddio_out): el nivel alto del reloj pone un 0 en la pata y
// el bajo un 1. Asi sale por el mismo tipo de registro que las ordenes y los
// datos, con retardos emparejados, y va adelantado medio periodo (15,6 ns).
//
// Antes salia de c0, una salida del PLL desfasada -7800 ps, por un camino
// hasta la pata distinto del de los datos: llegaba ~3 ns tarde y la ventana
// de lectura (el adelanto menos el acceso de la SDRAM) no cerraba timing en
// la Calypso ni en la Poseidon. Y antes aun se invertia clk_sys por la trama,
// que es peor: un retardo que no controla nadie. Ver doc/08-sdram.md
`ifdef MIST
localparam FAMILIA = "Cyclone III";
`elsif SIDI
localparam FAMILIA = "Cyclone IV E";
`elsif POSEIDON
localparam FAMILIA = "Cyclone IV GX";
`else
localparam FAMILIA = "Cyclone 10 LP";
`endif

altddio_out #(
    .extend_oe_disable("OFF"),
    .intended_device_family(FAMILIA),
    .invert_output("OFF"),
    .lpm_hint("UNUSED"),
    .lpm_type("altddio_out"),
    .oe_reg("UNREGISTERED"),
    .power_up_high("OFF"),
    .width(1)
) sdramclk_ddr (
    .datain_h(1'b0),
    .datain_l(1'b1),
    .outclock(clk_sys),
    .dataout(SDRAM_CLK),
    .aclr(1'b0),
    .aset(1'b0),
    .oe(1'b1),
    .outclocken(1'b1),
    .sclr(1'b0),
    .sset(1'b0)
);

/////////////////  IO  ////////////////////////////
wire [63:0] status;   // user_io lo declara de 64 bits
wire [1:0]  buttons;
wire        scandoubler_disable, no_csync, ypbpr;

wire        ioctl_download;
wire [7:0]  ioctl_index;
wire        ioctl_wr;
wire [26:0] ioctl_addr;
wire [7:0]  ioctl_dout;

wire        key_pressed, key_strobe, key_extended;
wire [7:0]  key_code;
// Teclado por la linea PS/2 serie de user_io, no por key_strobe: ver
// rtl/newbrain_ps2.v (en la SiDi cada soltar llegaba como otra pulsacion)
wire        ps2_kbd_clk, ps2_kbd_data;
wire [10:0] ps2_key;

wire [31:0] sd_lba;
wire [1:0]  sd_rd, sd_wr;
wire        sd_ack;
wire [8:0]  sd_buff_addr;
wire [7:0]  sd_buff_dout, sd_buff_din;
wire        sd_buff_wr;
wire [1:0]  img_mounted;
wire [63:0] img_size;

user_io #(
    .STRLEN($size(CONF_STR)>>3),
    .SD_IMAGES(2),
    .FEATURES(32'h0 | (BIG_OSD << 13)))
user_io(
    .clk_sys(clk_sys),
    .clk_sd(clk_sys),
    .SPI_SS_IO(CONF_DATA0),
    .SPI_CLK(SPI_SCK),
    .SPI_MOSI(SPI_DI),
    .SPI_MISO(SPI_DO),
    .conf_str(CONF_STR),
    .status(status),
    .scandoubler_disable(scandoubler_disable),
    .ypbpr(ypbpr),
    .no_csync(no_csync),
    .buttons(buttons),
    .key_strobe(key_strobe),
    .key_code(key_code),
    .key_pressed(key_pressed),
    .key_extended(key_extended),
    .ps2_kbd_clk(ps2_kbd_clk),
    .ps2_kbd_data(ps2_kbd_data),
    .ps2_kbd_clk_i(1'b1),
    .ps2_kbd_data_i(1'b1),
    .sd_lba(sd_lba),
    .sd_rd(sd_rd),
    .sd_wr(sd_wr),
    .sd_ack(sd_ack),
    .sd_ack_conf(),
    .sd_ack_x(),
    .sd_conf(1'b0),
    .sd_sdhc(1'b1),
    .sd_dout(sd_buff_dout),
    .sd_dout_strobe(sd_buff_wr),
    .sd_din(sd_buff_din),
    .sd_din_strobe(),
    .sd_buff_addr(sd_buff_addr),
    .img_mounted(img_mounted),
    .img_size(img_size)
);

data_io data_io(
    .clk_sys(clk_sys),
    .SPI_SCK(SPI_SCK),
    .SPI_SS2(SPI_SS2),
`ifdef NO_DIRECT_UPLOAD
    .SPI_SS4(1'b1),
`else
    .SPI_SS4(SPI_SS4),
`endif
    .SPI_DI(SPI_DI),
    .SPI_DO(SPI_DO),
    .ioctl_download(ioctl_download),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .clkref_n(~sdram_free)
);

// La maquina se reinicia al cargar, pero la SDRAM no puede: si el
// controlador esta en reset mientras data_io escribe, la ROM no llega nunca
// a memoria. Son dos resets distintos a proposito.
// Cargar una cinta NO reinicia la maquina: se cambia de cinta con el sistema
// en marcha, igual que se cambiaria el casete.
wire reset     = status[0] | buttons[1] | ~pll_locked
               | (ioctl_download & (ioctl_index[5:0] != 6'd2));
wire mem_reset = ~pll_locked;

// Reparto del fichero de ROM. El generador de caracteres va ANTES de la ROM
// de la controladora de disco a proposito: asi un fichero de 28672 bytes, sin
// disquetera, sigue siendo valido y solo se queda sin esa parte.
//
//   0000-5FFF   24K  ROM del sistema        -> SDRAM 000000  bancos 0,1,2
//   6000-6FFF    4K  generador de caracteres-> block RAM
//   7000-8FFF    8K  ROM de disco, opcional -> SDRAM 006000  banco 3
//   9000-EFFF   24K  ROM del EIM, opcional  -> SDRAM 008000  bancos 4,5,6
//   F000-F3FF    1K  ROM del COP420, opc.   -> block RAM del COP
//
// Ver roms/README.md
// Frontera entre semiperiodo corto (~204 us) y largo (~408 us) del
// desmodulador de audio, en unidades de 4 us.
//
// 330 us, no el punto medio teorico de 306: la entrada de oreja de la
// Calypso pasa por un transistor que hace de comparador y alarga el
// semiperiodo en que conduce, asi que el reparto real no queda centrado.
// Con 330 las cintas cargan; era una opcion del menu y ya no hace falta.
// Ver doc/11-cinta.md
wire [7:0] umbral_audio = 8'd82;       // 82 * 4 us = 328 us

// Imagen de cinta: se carga con el indice 2 de data_io y va al banco 3.
// Mientras dura la carga la cinta esta rebobinada y con tamaño cero, para
// que no se sirva nada a medio escribir; al acabar se empieza por el
// principio de la cinta nueva.
reg [23:0] tape_tam;
wire tape_dl = ioctl_download & (ioctl_index[5:0] == 6'd2);
wire tape_wr = tape_dl & ioctl_wr;
reg [23:0] tape_tam_dl;
reg        tape_dl_d;
always @(posedge clk_sys) begin
    tape_dl_d <= tape_dl;
    if (tape_dl & ~tape_dl_d) begin
        tape_tam    <= 24'd0;
        tape_tam_dl <= 24'd0;
    end else if (tape_wr) begin
        tape_tam_dl <= {3'd0, ioctl_addr[20:0]} + 24'd1;
    end
    if (~tape_dl & tape_dl_d) tape_tam <= tape_tam_dl;
end

wire sdram_free;
// Todo lo que sigue es solo para el fichero de ROM (indice 0). Sin esta
// condicion, cargar una cinta desactivaba la ROM de disco y el COP real (la
// escritura en la direccion 0 los marca como no cargados) y una cinta de mas
// de 24K machacaba el generador de caracteres y la ROM del COP.
wire rom_dl = ioctl_download & (ioctl_index[5:0] == 6'd0);
wire in_sysrom = ioctl_addr < 27'd24576;
wire in_chargen = (ioctl_addr >= 27'd24576) & (ioctl_addr < 27'd28672);
wire in_discrom = (ioctl_addr >= 27'd28672) & (ioctl_addr < 27'd36864);
wire in_eimrom  = (ioctl_addr >= 27'd36864) & (ioctl_addr < 27'd61440);
wire in_coprom  = (ioctl_addr >= 27'd61440) & (ioctl_addr < 27'd62464);
// ROM del Z80 de la controladora de disco (d417), 8K detras de la del COP.
// Solo se guardan los primeros 2K: las dos revisiones acaban antes de 0421h
// y lo demas es FF.
wire in_fdcrom  = (ioctl_addr >= 27'd62464) & (ioctl_addr < 27'd70656);
wire [26:0] fdcrom_dif = ioctl_addr - 27'd62464;
wire [12:0] fdcrom_off = fdcrom_dif[12:0];

wire dl_wr = (rom_dl & ioctl_wr & (in_sysrom | in_discrom | in_eimrom))
           | tape_wr;

// La ROM de disco solo se puede habilitar si el fichero la traia. Si no, la
// comprobacion de la ROM AB (LD A,(8000) / BIT 7,A / JP Z,8001) lee ceros,
// da salto y la CPU se pierde en memoria vacia para siempre.
// El COP real solo se puede elegir si su ROM venia en el fichero
reg coprom_cargada;
always @(posedge clk_sys) begin
    if (rom_dl & ioctl_wr & (ioctl_addr == 27'd0)) coprom_cargada <= 1'b0;
    else if (rom_dl & ioctl_wr & in_coprom)        coprom_cargada <= 1'b1;
end

reg fdcrom_cargada;
always @(posedge clk_sys) begin
    if (rom_dl & ioctl_wr & (ioctl_addr == 27'd0)) fdcrom_cargada <= 1'b0;
    else if (rom_dl & ioctl_wr & in_fdcrom)        fdcrom_cargada <= 1'b1;
end

reg disc_rom_loaded;
always @(posedge clk_sys) begin
    if (rom_dl & ioctl_wr & (ioctl_addr == 27'd0)) disc_rom_loaded <= 1'b0;
    else if (rom_dl & ioctl_wr & in_discrom)       disc_rom_loaded <= 1'b1;
end
wire cg_wr_en = rom_dl & ioctl_wr & in_chargen;
wire [11:0] cg_wr_addr = ioctl_addr[11:0];

// La ROM de disco se coloca detras de la del sistema en la SDRAM
// El hueco del generador de caracteres son 4096 bytes que no van a la SDRAM,
// asi que todo lo que viene detras se desplaza esa cantidad.
wire [23:0] dl_sdram_addr = tape_dl
                          ? (24'h600000 + {3'd0, ioctl_addr[20:0]})
                          : (in_discrom | in_eimrom)
                          ? ({3'd0, ioctl_addr[20:0]} - 24'd4096)
                          : {3'd0, ioctl_addr[20:0]};

/////////////////  MAQUINA  ///////////////////////
wire [15:0] dbg_pc;
wire        dbg_pwrup, dbg_m1_n, dbg_tv_enable, dbg_tv_load, dbg_sdram_ready;
wire        dbg_int_req, dbg_int_ack, dbg_tape, dbg_disc;
wire        v24_txd, v24_rts_n, prn_txd;
wire [1:0]  cass_motor;
wire [127:0] vfd_texto;
wire        cass_out, cass_grabando, cass_leyendo;

// Reloj de pixel: 32 MHz (puntos de 16 MHz, como la maquina) o 27 MHz
// (puntos de 13,5 MHz, que llenan el ancho como en los emuladores). Ver
// doc/04-video.md
wire aspecto_wide = status[20];
wire clk_pix;
newbrain_clkmux clkmux_pix (
    .clk0(clk_32v), .clk1(clk_27), .sel(aspecto_wide), .clk_out(clk_pix)
);
reg ce_pix;
always @(posedge clk_pix) ce_pix <= ~ce_pix;   // 16 o 13,5 MHz

wire [7:0] R, G, B;
wire hs, hs_cs, vs, hblank, vblank;

newbrain #(.CLK_HZ(32_000_000)) newbrain(
    .clk_sys(clk_sys),
    .reset(reset),
    .mem_reset(mem_reset),
    .fast_boot(status[6]),
    // La disquetera necesita las dos ROMs: la d413 en 8000 y la d417 del
    // Z80 de la controladora
    .disc_rom(status[7] & disc_rom_loaded & fdcrom_cargada),
    .fdcrom_wr_en(rom_dl & ioctl_wr & in_fdcrom & (fdcrom_off[12:11] == 2'b00)),
    .fdcrom_wr_addr(fdcrom_off[10:0]),
    .fdcrom_wr_data(ioctl_dout),
    .coprom_wr_addr(ioctl_addr[9:0]),
    .coprom_wr_data(ioctl_dout),
    .coprom_wr_en(rom_dl & ioctl_wr & in_coprom),
    .cass_fuente(status[21]),
    .cass_rebobina(status[26] | tape_dl),
    .cass_umbral(umbral_audio),
    .cass_tam(tape_tam),
    .cass_out(cass_out),
    .cass_grabando(cass_grabando),
    .cass_leyendo(cass_leyendo),
    // Los ajustes van en complemento a dos dentro de tres bits: las cuatro
    // primeras posiciones del menu son positivas y las cuatro ultimas
    // negativas, que es como quedan las etiquetas ordenadas.
    .h_off({{2{status[13]}}, status[13:11], 3'b000}),
    .v_off({{4{status[16]}}, status[16:14], 1'b0}),
    .ram_size(status[9:8]),
    // Mas de 32K solo existe con el modulo de expansion, asi que la opcion
    // de RAM lo implica en vez de pedir otra entrada de menu.
    .eim(|status[9:8]),
    // Configuracion de arranque que la maquina lee del registro de estado 2
    // del modulo de expansion
    // Arranque fijo: video normal, 40 columnas y pantalla, que es lo que
    // hacia el menu por defecto. Los bits 18 a 20 de status quedan libres.
    .cfg_rev_video(1'b0),
    .cfg_40col(1'b1),
    .cfg_tv(1'b1),
    .dl_addr(dl_sdram_addr),
    .dl_data(ioctl_dout),
    .dl_wr(dl_wr),
    .sdram_free(sdram_free),
    .cg_wr_addr(cg_wr_addr),
    .cg_wr_data(ioctl_dout),
    .cg_wr_en(cg_wr_en),
    .clk_pix(clk_pix), .ce_pix(ce_pix), .ancho(aspecto_wide),
    .vid_r(R), .vid_g(G), .vid_b(B),
    .vid_hs(hs), .vid_hs_cs(hs_cs), .vid_vs(vs), .vid_hb(hblank), .vid_vb(vblank),
    .ps2_key(ps2_key),
    .vfd_addr(),
    .vfd_data(),
    .vfd_wr(),
    .vfd_valid(),
    .SDRAM_A(SDRAM_A), .SDRAM_DQ(SDRAM_DQ),
    .SDRAM_DQML(SDRAM_DQML), .SDRAM_DQMH(SDRAM_DQMH),
    .SDRAM_nWE(SDRAM_nWE), .SDRAM_nCAS(SDRAM_nCAS),
    .SDRAM_nRAS(SDRAM_nRAS), .SDRAM_nCS(SDRAM_nCS),
    .SDRAM_BA(SDRAM_BA), .SDRAM_CKE(SDRAM_CKE),
    .tape_in(TAPE_IN),
`ifdef NB_SERIE
    .v24_rxd(V24_RXD),
    .v24_cts_n(V24_CTS),
    .prn_cts_n(PRN_CTS),
`else
    // sin puerto: RXD en reposo (1) y los CTS dando paso (0)
    .v24_rxd(1'b1),
    .v24_cts_n(1'b0),
    .prn_cts_n(1'b0),
`endif
    .v24_txd(v24_txd), .v24_rts_n(v24_rts_n), .prn_txd(prn_txd),
    .cass_motor(cass_motor),
    .vfd_texto(vfd_texto),
    .dbg_pc(dbg_pc),
    .dbg_pwrup(dbg_pwrup),
    .dbg_tv_enable(dbg_tv_enable),
    .dbg_tv_load(dbg_tv_load),
    .dbg_sdram_ready(dbg_sdram_ready),
    .dbg_int_req(dbg_int_req),
    .dbg_int_ack(dbg_int_ack),
    .dbg_tape(dbg_tape),
    .dbg_m1_n(dbg_m1_n),
    .sd_lba(sd_lba),
    .sd_rd(sd_rd),
    .sd_wr(sd_wr),
    .sd_ack(sd_ack),
    .sd_buff_addr(sd_buff_addr),
    .sd_buff_dout(sd_buff_dout),
    .sd_buff_wr(sd_buff_wr),
    .sd_buff_din(sd_buff_din),
    .img_mounted(img_mounted),
    .img_size(img_size[31:0]),
    .dbg_disc(dbg_disc)
);

// Diagnostico de fase 1 sin necesidad de video
//=====================================================================
// Diagnostico por LEDs, SIN inversion.
//
// Los dos primeros son referencias fijas para averiguar de una vez la
// polaridad de la placa y por que extremo empieza la fila: uno esta siempre
// a nivel alto y otro siempre a bajo. El que se vea encendido dice si
// encendido es 1 o 0; el que parpadea dice donde esta el LED 2.
//
//   0  constante 1
//   1  constante 0
//   2  latido de ~1 Hz: si late, el PLL engancho y clk_sys corre
//   3  PWRUP: a 1 cuando el mapa de memoria ya esta asentado
//   4  la SDRAM acabo su secuencia de arranque
//   5  la ROM habilito el video (ENRG1 bit 2)
//   6  INT solicitada por la maquina (destello alargado)
//   7  INT aceptada por el Z80, ciclo de reconocimiento (destello alargado)
//
// La simulacion de la ROM dice que es la interrupcion de reloj la que
// habilita el video, sin necesidad del COP. Si el 6 destella y el 7 no, el
// Z80 no esta aceptando la peticion; si no destella ninguno, la peticion no
// se esta generando.
//=====================================================================
reg [24:0] hb_cnt;
reg        heartbeat;
always @(posedge clk_sys) begin
    if (hb_cnt >= 25'd15_999_999) begin
        hb_cnt    <= 25'd0;
        heartbeat <= ~heartbeat;
    end else hb_cnt <= hb_cnt + 1'b1;
end

reg [21:0] req_stretch, ack_stretch;
always @(posedge clk_sys) begin
    if (dbg_int_req) req_stretch <= 22'h3FFFFF;
    else if (req_stretch != 0) req_stretch <= req_stretch - 1'b1;

    if (dbg_int_ack) ack_stretch <= 22'h3FFFFF;
    else if (ack_stretch != 0) ack_stretch <= ack_stretch - 1'b1;
end

wire [7:0] leds;
assign leds[0] = 1'b1;
// El 1 se enciende cuando entra señal por la entrada de oreja: cualquier
// flanco lo prende medio segundo. Sirve para saber si el cable, el volumen
// y el comparador de la placa hacen su trabajo SIN depender del sonido ni
// del menu. Si al reproducir una cinta este LED no se mueve, el problema
// esta antes del core.
reg [23:0] oreja_stretch;
reg        oreja_d;
always @(posedge clk_sys) begin
    oreja_d <= dbg_tape;
    if (dbg_tape != oreja_d) oreja_stretch <= 24'hFFFFFF;
    else if (oreja_stretch != 0) oreja_stretch <= oreja_stretch - 1'b1;
end
assign leds[1] = |oreja_stretch;
assign leds[2] = heartbeat;
assign leds[3] = dbg_pwrup;
assign leds[4] = dbg_sdram_ready;
// El 5 dice si el video esta habilitado; mientras la controladora de disco
// trabaja, parpadea.
assign leds[5] = dbg_disc ? heartbeat : dbg_tv_enable;
// Con la cinta en marcha los dos ultimos LEDs dicen que hace: el 6 lee y el
// 7 graba. Fuera de eso, las interrupciones como siempre.
wire cinta_activa = cass_leyendo | cass_grabando;
assign leds[6] = cinta_activa ? (cass_leyendo  & heartbeat) : |req_stretch;
assign leds[7] = cinta_activa ? (cass_grabando & heartbeat) : |ack_stretch;

`ifdef UN_SOLO_LED
// La SiDi y la Poseidon solo tienen un LED. Hace de piloto de actividad, como en los
// demas cores: se enciende mientras se carga algo por el menu, mientras la
// cinta lee o graba y mientras trabaja la controladora de disco. Activo a
// nivel bajo.
assign LED = ~(ioctl_download | cinta_activa | dbg_disc);
`else
assign LED = leds;
`endif

newbrain_ps2 teclado_ps2 (
    .clk(clk_sys),
    .reset(reset),
    .ps2_clk(ps2_kbd_clk),
    .ps2_data(ps2_kbd_data),
    .ps2_key(ps2_key)
);

/////////////////  EXTRAS: SERIE, REMOTE Y LCD  /////////////////

`ifdef NB_SERIE
assign V24_TXD = v24_txd;
assign V24_RTS = v24_rts_n;
assign PRN_TXD = prn_txd;
`endif

`ifdef NB_REMOTE
assign TAPE_REMOTE1 = cass_motor[0];
assign TAPE_REMOTE2 = cass_motor[1];
`endif

`ifdef NB_LCD
// Linea 1: lo que hay en el display fluorescente del NewBrain.
// Linea 2: estado de la cinta y la disquetera.
wire [127:0] lcd_linea2 = { (cinta_activa ? "Cinta " : "      "),
                            (dbg_disc     ? "Disco " : "      "),
                            "    " };
// Direcciones habituales de los modulos: PCF8574 (27h, 20h) y PCF8574A
// (3Fh, 38h)
wire [6:0] lcd_dir = (status[23:22] == 2'd0) ? 7'h27 :
                     (status[23:22] == 2'd1) ? 7'h3F :
                     (status[23:22] == 2'd2) ? 7'h20 : 7'h38;
wire lcd_scl, lcd_sda;
newbrain_lcd_i2c #(.CLK_HZ(32_000_000)) lcd (
    .clk(clk_sys), .reset(reset), .direccion(lcd_dir),
    .linea1(vfd_texto), .linea2(lcd_linea2),
    .scl(lcd_scl), .sda(lcd_sda)
);
assign LCD_SCL = lcd_scl ? 1'bz : 1'b0;
assign LCD_SDA = lcd_sda ? 1'bz : 1'b0;
`endif

/////////////////  VIDEO  /////////////////////////
// Color del fosforo, como los monitores monocromo de la epoca. La maquina
// saca un solo bit de luminancia (R = G = B); aqui se tine sin cambiar nada
// mas. Las proporciones son las del core del Amstrad (color_mix.sv de
// gyurco): el ambar lleva el verde a tres cuartos del rojo, y el cian es
// verde y azul a partes iguales. Los bits 18 y 19 de status eran las
// opciones de arranque que se quitaron.
wire [1:0] display = status[19:18];
wire [7:0] luma    = R;
wire [7:0] ambar_g = luma - {2'b00, luma[7:2]};     // 3/4 de la luminancia

reg  [7:0] R_mix, G_mix, B_mix;
always @* begin
    case (display)
    2'd1:    {R_mix, G_mix, B_mix} = {8'd0, luma,    8'd0};  // verde
    2'd2:    {R_mix, G_mix, B_mix} = {luma, ambar_g, 8'd0};  // ambar
    2'd3:    {R_mix, G_mix, B_mix} = {8'd0, luma,    luma};  // cian
    default: {R_mix, G_mix, B_mix} = {R,    G,       B};     // blanco
    endcase
end

// Sincronismo compuesto a 15 kHz. mist_video lo forma como ~(hs ^ vs) cuando
// el scandoubler esta desactivado y el OSD no pide H y V separadas (o hay
// YPbPr). Para ese caso el generador da hs_cs, que en las lineas de vsync
// lleva el pulso al final de la linea: asi el XOR sale con los pulsos anchos
// de PAL y un flanco de bajada al principio de cada una de las 312 lineas.
// Con la hsync normal se perdia un flanco por trama y el monitor contaba 311
// (50,29 Hz). Ver doc/04-video.md. Con H y V separadas, y siempre a 31 kHz
// (el scandoubler necesita la hsync de verdad), va la hsync normal.
wire usa_csync = scandoubler_disable & (~no_csync | ypbpr);

mist_video #(
    .COLOR_DEPTH(8),
    .SD_HCNT_WIDTH(11),
    .USE_BLANKS(1'b1),
    .OSD_COLOR(3'b001),
    .OUT_COLOR_DEPTH(VGA_BITS),
    .BIG_OSD(BIG_OSD))
mist_video(
    .clk_sys(clk_pix),          // la salida de video va con el reloj de pixel
    .SPI_SCK(SPI_SCK),
    .SPI_SS3(SPI_SS3),
    .SPI_DI(SPI_DI),
    .R(R_mix), .G(G_mix), .B(B_mix),
    .HBlank(hblank), .VBlank(vblank),
    .HSync(usa_csync ? hs_cs : hs), .VSync(vs),
    .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
    .VGA_VS(VGA_VS), .VGA_HS(VGA_HS),
    .ce_divider(3'd1),          // pixel = clk_pix / 2: 16 o 13,5 MHz
    .scandoubler_disable(scandoubler_disable),
    .no_csync(no_csync),
    .scanlines(status[5:4]),
    .ypbpr(ypbpr)
);

/////////////////  AUDIO  ////////////////////////
// Monitor de la entrada de cinta. Sale del pin ya sincronizado, no del
// crudo, para que lo que se oye sea exactamente lo que lee la maquina.
// Apagado por defecto: con una cinta conectada y el altavoz abierto molesta
// mas que ayuda, y solo se quiere al buscar el principio de un bloque.
wire escuchar_cinta = status[17];
wire tono_prueba    = status[25];

localparam signed [15:0] NIVEL_CINTA = 16'sd6144;

// Tono de prueba: onda cuadrada de 1 kHz. No depende de la maquina ni de la
// entrada de cinta, asi que separa dos averias que se parecen mucho: "no
// sale sonido" (el camino de audio) y "no entra señal" (la entrada de
// oreja). 32 MHz / 2000 = 16000 ciclos por medio periodo.
reg [13:0] tono_cnt;
reg        tono;
always @(posedge clk_sys) begin
    if (tono_cnt == 14'd15999) begin
        tono_cnt <= 14'd0;
        tono     <= ~tono;
    end else begin
        tono_cnt <= tono_cnt + 1'b1;
    end
end

// Lo que la maquina graba sale siempre, mientras graba: es la salida de
// cinta del NewBrain y se puede llevar a un grabador o al PC.
wire signed [15:0] audio_cinta = tono_prueba
                               ? (tono ? NIVEL_CINTA : -NIVEL_CINTA)
                               : cass_grabando
                               ? (cass_out ? NIVEL_CINTA : -NIVEL_CINTA)
                               : escuchar_cinta
                               ? (dbg_tape ? NIVEL_CINTA : -NIVEL_CINTA)
                               : 16'sd0;

`ifdef I2S_AUDIO
i2s i2s (
    .reset(1'b0),
    .clk(clk_sys),
    .clk_rate(32'd32_000_000),
    .sclk(I2S_BCK),
    .lrclk(I2S_LRCK),
    .sdata(I2S_DATA),
    .left_chan(audio_cinta),
    .right_chan(audio_cinta)
);
`endif

`ifdef DELTASIGMA_AUDIO
// Lo mismo que por I2S: salida de cinta mientras se graba, "Escuchar cinta"
// y el tono de prueba. OJO: esto no es I2S, es sigma-delta, y el modulador
// de dac.vhd quiere la muestra SIN signo, asi que se pasa a binario
// desplazado invirtiendo el bit de signo. El silencio queda en media escala.
wire [15:0] audio_sin_signo = {~audio_cinta[15], audio_cinta[14:0]};

dac #(
    .C_bits(16))
dac_l (
    .clk_i(clk_sys),
    .res_n_i(1'b1),
    .dac_i(audio_sin_signo),
    .dac_o(AUDIO_L)
);

dac #(
    .C_bits(16))
dac_r (
    .clk_i(clk_sys),
    .res_n_i(1'b1),
    .dac_i(audio_sin_signo),
    .dac_o(AUDIO_R)
);
`endif

endmodule

`default_nettype wire
