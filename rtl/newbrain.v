//============================================================================
// NewBrain A/AD - maquina
//
// Toda la memoria vive en la SDRAM. Reparto del espacio fisico:
//
//   000000-005FFF   ROM del sistema, 24K (AB, CD, EF)     banco 0
//   006000-007FFF   ROM de la controladora de disco, 8K    banco 0
//   008000-00DFFF   ROM del modulo de expansion, 24K       banco 0
//                   (POS, MTV, ACI)
//   400000-5FFFFF   RAM, hasta 2 MB                        banco 2
//
// La RAM no cabe en block RAM: con la paginacion del modulo de expansion son
// 2 MB, y aun sin ella los 32K se comian la mitad de los M9K del chip. Ver
// doc/05-memoria.md y doc/08-sdram.md
//============================================================================
`default_nettype none

module newbrain #(
    parameter CLK_HZ = 32_000_000
) (
    input  wire        clk_sys,
    input  wire        reset,
    input  wire        mem_reset,     // solo cuando el PLL pierde el enganche
    input  wire        fast_boot,
    input  wire        disc_rom,
    input  wire [9:0]  coprom_wr_addr,
    input  wire [7:0]  coprom_wr_data,
    input  wire        coprom_wr_en,
    input  wire        cass_fuente,     // 0 = fichero, 1 = audio
    input  wire        cass_rebobina,
    input  wire [7:0]  cass_umbral,
    input  wire [23:0] cass_tam,
    output wire        cass_out,        // señal de grabacion, para el audio
    output wire        cass_grabando,
    output wire        cass_leyendo,
    input  wire signed [7:0] h_off,
    input  wire signed [7:0] v_off,
    input  wire        eim,             // hay modulo de expansion
    input  wire        cfg_rev_video,
    input  wire        cfg_40col,
    input  wire        cfg_tv,
    input  wire [1:0]  ram_size,        // 0:32K 1:96K 2:512K 3:768K

    // carga desde data_io
    input  wire [23:0] dl_addr,
    input  wire [7:0]  dl_data,
    input  wire        dl_wr,
    output wire        sdram_free,
    input  wire [11:0] cg_wr_addr,
    input  wire [7:0]  cg_wr_data,
    input  wire        cg_wr_en,

    // pines de SDRAM
    output wire [12:0] SDRAM_A,
    inout  wire [15:0] SDRAM_DQ,
    output wire        SDRAM_DQML,
    output wire        SDRAM_DQMH,
    output wire        SDRAM_nWE,
    output wire        SDRAM_nCAS,
    output wire        SDRAM_nRAS,
    output wire        SDRAM_nCS,
    output wire [1:0]  SDRAM_BA,
    output wire        SDRAM_CKE,

    // video
    input  wire        clk_pix,         // reloj de pixel, 27 MHz
    input  wire        ce_pix,          // en clk_pix, uno de cada dos
    output wire [7:0]  vid_r,
    output wire [7:0]  vid_g,
    output wire [7:0]  vid_b,
    output wire        vid_hs,
    output wire        vid_hs_cs,       // hsync para el sincronismo compuesto
    output wire        vid_vs,
    output wire        vid_hb,
    output wire        vid_vb,

    // teclado y display fluorescente
    input  wire [10:0] ps2_key,
    output wire [4:0]  vfd_addr,
    output wire [7:0]  vfd_data,
    output wire        vfd_wr,
    output wire        vfd_valid,

    // entradas analogicas y serie
    input  wire        tape_in,
    input  wire        v24_rxd,
    input  wire        v24_cts_n,
    input  wire        prn_cts_n,

    // Puertos serie hacia fuera (bits del ENREG, niveles TTL, reposo a 1)
    output wire        v24_txd,         // ENREG b5 (DO)
    output wire        v24_rts_n,       // ENREG b4 (_RTSD)
    output wire        prn_txd,         // ENREG b7 (PO)

    // Remote de las cintas: {cinta 2, cinta 1}, a 1 con el motor en marcha
    output wire [1:0]  cass_motor,

    // Texto del display fluorescente, 16 caracteres
    output wire [127:0] vfd_texto,

    // depuracion
    output wire [15:0] dbg_pc,
    output wire        dbg_pwrup,
    output wire        dbg_m1_n,
    output wire        dbg_tv_enable,
    output wire        dbg_tv_load,
    output wire        dbg_sdram_ready,
    output wire        dbg_int_req,
    output wire        dbg_int_ack,
    output wire        dbg_tape,

    // imagenes de disco en la SD (user_io)
    output wire [31:0] sd_lba,
    output wire [1:0]  sd_rd,
    output wire [1:0]  sd_wr,
    input  wire        sd_ack,
    input  wire [8:0]  sd_buff_addr,
    input  wire [7:0]  sd_buff_dout,
    input  wire        sd_buff_wr,
    output wire [7:0]  sd_buff_din,
    input  wire [1:0]  img_mounted,
    input  wire [31:0] img_size,
    output wire        dbg_disc,

    // ROM d417 de la controladora de disco (primeros 2K)
    input  wire        fdcrom_wr_en,
    input  wire [10:0] fdcrom_wr_addr,
    input  wire [7:0]  fdcrom_wr_data
);
    // Banco 1 de la SDRAM. Cada banco son 2 MB, asi que la RAM entera cabe en
    // uno y no comparte filas con la ROM, que vive en el banco 0.
    localparam [23:0] RAM_BASE  = 24'h400000;
    // La imagen de cinta va al banco 3, que esta libre
    localparam [23:0] TAPE_BASE = 24'h600000;

    //------------------------------------------------------------------
    // Relojes
    //------------------------------------------------------------------
    reg [2:0] clkdiv = 3'd0;
    always @(posedge clk_sys) clkdiv <= clkdiv + 3'd1;

    wire cen_p_raw = (clkdiv == 3'd0);
    wire cen_n_raw = (clkdiv == 3'd4);

    wire cpu_stall;
    wire cen_p = cen_p_raw & ~cpu_stall;
    wire cen_n = cen_n_raw & ~cpu_stall;

    localparam TICK_DIV = CLK_HZ / 50;
    reg [23:0] tickcnt;
    reg        clkint_tick;
    always @(posedge clk_sys) begin
        clkint_tick <= 1'b0;
        if (tickcnt >= TICK_DIV - 1) begin
            tickcnt     <= 0;
            clkint_tick <= 1'b1;
        end else tickcnt <= tickcnt + 1'b1;
    end

    //------------------------------------------------------------------
    // RESET / PWRUP
    //------------------------------------------------------------------
    wire cpu_reset_n, pwrup;
    newbrain_powerup #(.CLK_HZ(CLK_HZ)) powerup (
        .clk(clk_sys), .reset(reset), .fast(fast_boot),
        .cpu_reset_n(cpu_reset_n), .pwrup(pwrup)
    );
    assign dbg_pwrup = pwrup;

    //------------------------------------------------------------------
    // Z80
    //------------------------------------------------------------------
    wire [15:0] cpu_addr;
    wire [7:0]  cpu_dout;
    reg  [7:0]  cpu_din;
    wire        mreq_n, iorq_n, rd_n, wr_n, m1_n, rfsh_n;
    wire        int_n;

    assign dbg_pc        = cpu_addr;
    assign dbg_m1_n      = m1_n;
    assign dbg_tv_enable = tv_enable;
    assign dbg_tv_load   = tv_load;
    assign dbg_sdram_ready = b_free;
    // INT solicitada por la maquina, e INT aceptada por el Z80: el ciclo de
    // reconocimiento es el unico en que M1 e IORQ bajan a la vez.
    assign dbg_int_req = ~int_n;
    assign dbg_int_ack = ~iorq_n & ~m1_n;

    T80pa cpu (
        .RESET_n(cpu_reset_n), .CLK(clk_sys), .CEN_p(cen_p), .CEN_n(cen_n),
        .WAIT_n(1'b1), .INT_n(int_n), .NMI_n(1'b1), .BUSRQ_n(1'b1),
        .M1_n(m1_n), .MREQ_n(mreq_n), .IORQ_n(iorq_n), .RD_n(rd_n),
        .WR_n(wr_n), .RFSH_n(rfsh_n), .HALT_n(), .BUSAK_n(),
        .A(cpu_addr), .DI(cpu_din), .DO(cpu_dout)
    );

    // Ciclo de memoria del Z80 (el de refresco no cuenta)
    wire mem_cyc = ~mreq_n & rfsh_n;
    wire mem_rd  = mem_cyc & ~rd_n;
    wire mem_wrq = mem_cyc & ~wr_n;

    //------------------------------------------------------------------
    // Sincronizacion de las entradas asincronas
    //
    // La entrada de cinta viene de un pin analogico comparado fuera del FPGA,
    // y las lineas del V24 tampoco tienen nada que ver con clk_sys. Meterlas
    // directas en logica sincrona es pedir metaestabilidad, y en una entrada
    // de cinta eso se traduce en bits mal leidos de vez en cuando.
    //------------------------------------------------------------------
    reg [1:0] tape_sr, rxd_sr, ctsd_sr, ctsp_sr;
    always @(posedge clk_sys) begin
        tape_sr <= {tape_sr[0], tape_in};
        rxd_sr  <= {rxd_sr[0],  v24_rxd};
        ctsd_sr <= {ctsd_sr[0], v24_cts_n};
        ctsp_sr <= {ctsp_sr[0], prn_cts_n};
    end

    wire tape_s = tape_sr[1];
    assign dbg_tape = tape_s;

    //------------------------------------------------------------------
    // E/S
    //------------------------------------------------------------------
    wire [7:0] io_dout;
    wire       io_dout_oe;
    wire       cop_cs, cop_rd, cop_wr;
    wire [7:0] enrg1;
    wire       copint_n;
    wire [7:0] cop_dout;
    wire [15:0] tv_addr;
    wire [7:0]  tvtl;
    wire        tv_load, tv_enable;

    newbrain_io io (
        .clk(clk_sys), .reset(reset),
        .addr(cpu_addr[7:0]), .din(cpu_dout), .dout(io_dout),
        .dout_oe(io_dout_oe),
        .iorq_n(iorq_n), .m1_n(m1_n), .rd_n(rd_n), .wr_n(wr_n),
        .int_n(int_n),
        .eim(eim), .cfg_rev_video(cfg_rev_video),
        .cfg_40col(cfg_40col), .cfg_tv(cfg_tv),
        .pwrup(pwrup), .extest(1'b1), .mains_ok(1'b1), .tape_in(tape_s),
        .cass_leyendo(cass_reproduce),
        .v24_rxd(rxd_sr[1]), .v24_cts_n(ctsd_sr[1]), .prn_cts_n(ctsp_sr[1]),
        .clkint_tick(clkint_tick),
        .cop_cs(cop_cs), .cop_rd(cop_rd), .cop_wr(cop_wr),
        .cop_dout(cop_dout), .copint_n(copint_n),
        .enrg1(enrg1), .enrg2(), .prn_latch(), .tv_enable(tv_enable), .tvtl(tvtl),
        .tv_addr(tv_addr), .tv_load(tv_load)
    );

    wire [7:0] key_byte;
    wire       key_avail, key_taken, kbd_brk;
    wire [3:0] cop_scan_row, cop_scan_col;

    newbrain_kbd kbd (
        .clk(clk_sys), .reset(reset), .ps2_key(ps2_key),
        .key_byte(key_byte), .key_avail(key_avail), .key_taken(1'b0),
        .brk(kbd_brk),
        .scan_row(cop_scan_row), .scan_col(cop_scan_col)
    );

    wire        cass_pide, cass_reproduce, cass_limpia, cass_salta, cass_cola;
    wire [15:0] cass_salta_n;
    wire        cass_graba_act, cass_graba_wr, cass_graba_listo;
    wire [7:0]  cass_dato, cass_graba;
    wire        cass_hay;
    wire [23:0] tape_sd_addr;
    wire        tape_sd_rd;

    assign cass_grabando = cass_graba_act;
    assign cass_leyendo  = cass_reproduce;

    newbrain_tape #(.CLK_HZ(CLK_HZ)) cinta (
        .clk(clk_sys), .reset(reset),
        .fuente(cass_fuente), .rebobina(cass_rebobina),
        .img_base(TAPE_BASE), .img_tam(cass_tam),
        .sd_addr(tape_sd_addr), .sd_rd(tape_sd_rd),
        .sd_dout(b_dout), .sd_ack(b_ack & (b_own == OWN_CINTA)),
        .audio(tape_s), .umbral(cass_umbral),
        .pide(cass_pide), .limpia(cass_limpia),
        .salta(cass_salta), .salta_n(cass_salta_n), .cola_ini(cass_cola),
        .dato(cass_dato), .hay(cass_hay), .err_audio(),
        .graba(cass_graba_act), .graba_dato(cass_graba),
        .graba_wr(cass_graba_wr), .graba_listo(cass_graba_listo),
        .tape_out(cass_out)
    );

    assign v24_txd   = enrg1[5];
    assign v24_rts_n = enrg1[4];
    assign prn_txd   = enrg1[7];

    // El texto del display fluorescente se escucha en el puerto del COP
    newbrain_vfd_espia espia_vfd (
        .clk(clk_sys), .reset(reset),
        .cs(cop_cs), .rd(cop_rd), .wr(cop_wr), .din(cpu_dout),
        .texto(vfd_texto), .nuevo()
    );

    //------------------------------------------------------------------
    // El COP
    //
    // El de verdad, ejecutando su ROM, lleva siempre el teclado, la
    // pantalla y el reloj. La cinta, de momento, la sigue llevando el modulo
    // emulado de siempre (newbrain_cop_hle en modo solo cinta), que es el que
    // carga los .bas y el audio: cuando el Z80 manda un CASSCOM (8x) en el
    // reconocimiento, el modulo se queda el comando y el puerto del COP hasta
    // que acaba la operacion de cinta, y al COP de verdad le llega un
    // NULLCOM (D0) para que siga a lo suyo sin enterarse.
    //------------------------------------------------------------------
    wire [7:0] cop_dout_hle, cop_dout_real;
    wire       copint_n_hle, copint_n_real;
    wire       cinta_lleva;                  // el modulo de cinta tiene el puerto
    wire       real_cs;
    wire [7:0] real_din;

    newbrain_cop_mux reparto (
        .cs(cop_cs), .din(cpu_dout), .dout(cop_dout), .copint_n(copint_n),
        .real_cs(real_cs), .real_din(real_din),
        .real_dout(cop_dout_real), .real_copint_n(copint_n_real),
        .cinta_ocupada(cinta_lleva), .cinta_dout(cop_dout_hle),
        .cinta_copint_n(copint_n_hle)
    );

    newbrain_cop_real #(.CLK_HZ(CLK_HZ)) cop_chip (
        .clk(clk_sys), .reset(reset),
        .rom_wr_addr(coprom_wr_addr), .rom_wr_data(coprom_wr_data),
        .rom_wr_en(coprom_wr_en),
        .cs(real_cs), .rd(cop_rd), .wr(cop_wr), .din(real_din),
        .dout(cop_dout_real), .copint_n(copint_n_real),
        .kbd_row(cop_scan_row), .kbd_col(cop_scan_col),
        .vfd_sr(), .vfd_latch(),
        .tape_in(tape_s), .tape_out(), .motor()
    );

    newbrain_cop_hle #(.CLK_HZ(CLK_HZ)) cop (
        .clk(clk_sys), .reset(reset),
        .solo_cinta(1'b1), .ocupado(cinta_lleva), .cass_motor(cass_motor),
        .cs(cop_cs), .rd(cop_rd), .wr(cop_wr), .din(cpu_dout),
        .dout(cop_dout_hle), .copint_n(copint_n_hle),
        .key_byte(8'h00), .key_avail(1'b0), .key_taken(),
        .brk(kbd_brk),
        .cass_reproduce(cass_reproduce), .cass_limpia(cass_limpia),
        .cass_pide(cass_pide),
        .cass_salta(cass_salta), .cass_salta_n(cass_salta_n), .cass_cola(cass_cola),
        .cass_dato(cass_dato), .cass_hay(cass_hay),
        .cass_graba_act(cass_graba_act), .cass_graba(cass_graba),
        .cass_graba_wr(cass_graba_wr), .cass_graba_listo(cass_graba_listo),
        .vfd_addr(vfd_addr), .vfd_data(vfd_data),
        .vfd_wr(vfd_wr), .vfd_valid(vfd_valid)
    );

    //------------------------------------------------------------------
    // Paginacion del modulo de expansion
    //------------------------------------------------------------------
    wire        paging_on;
    wire        page_ok;
    wire [7:0]  page;
    wire        io_wr_cyc = ~iorq_n & m1_n & ~wr_n;

    newbrain_pager pager (
        .clk(clk_sys), .reset(reset), .present(eim),
        .io_addr(cpu_addr), .io_data(cpu_dout), .io_wr(io_wr_cyc),
        .cpu_addr(cpu_addr),
        .paging_on(paging_on), .page(page), .page_ok(page_ok), .phys_addr(),
        .fdc_addr(win_addr), .fdc_a16(win_a16), .fdc_page(fdc_page), .fdc_page_ok(fdc_page_ok),
        .a16(), .multiproc(), .isolated()
    );

    // La disquetera solo existe en el sistema SIN paginar. Aqui se decide
    // una vez, y de aqui sale tambien el mapeo de su ROM en 8000: si la ROM
    // apareciera sin la controladora, la RAM compartida de 9C00-9FFF seria
    // ROM de solo lectura, la d413 escribiria su vector al aire y la maquina
    // se quedaria colgada antes de encender el video. Que es exactamente lo
    // que pasaba al activar la ROM de disco con mas de 32K.
    // Con el modulo de expansion la controladora tambien funciona: su ROM
    // va en la pagina 119 y accede a la memoria paginada por su ventana.
    // La RAM compartida de 9C00 solo existe sin expansion (con ella, en
    // 8000-9FFF esta el sistema paginado).
    wire       disc_en = disc_rom;

    //------------------------------------------------------------------
    // Controladora de disco de verdad: segundo Z80 con la ROM d417 y un
    // uPD765 con imagenes EDSK. Ver rtl/newbrain_fdc.v y doc/13-disquetera.md
    //
    // Solo en el sistema sin paginar: con el modulo de expansion la d417
    // busca su bloque de parametros en la RAM del NewBrain, fuera de la
    // RAM compartida.
    //------------------------------------------------------------------
    wire [7:0] disc_ram_dout;
    // 1K de RAM compartida en 9C00-9FFF, encima de la ROM de disco
    wire       disc_ram_sel = disc_en & ~eim & pwrup & ~paging_on & mem_cyc
                            & (cpu_addr[15:10] == 6'b100111);

    // Ventana paginada de la controladora
    wire        win_req, win_a16, win_wr, win_done;
    wire [15:0] win_addr;
    wire [7:0]  win_din, win_dout;
    wire [7:0]  fdc_page;
    wire        fdc_page_ok;

    newbrain_fdc disco (
        .clk(clk_sys), .reset(reset), .enable(disc_en),
        .io_addr(cpu_addr), .io_data(cpu_dout), .io_wr(io_wr_cyc),
        .ram_addr(cpu_addr[9:0]), .ram_din(cpu_dout),
        .ram_we(disc_ram_sel & mem_wrq), .ram_dout(disc_ram_dout),
        .rom_wr(fdcrom_wr_en), .rom_addr(fdcrom_wr_addr), .rom_data(fdcrom_wr_data),
        .sd_lba(sd_lba), .sd_rd(sd_rd), .sd_wr(sd_wr), .sd_ack(sd_ack),
        .sd_buff_addr(sd_buff_addr), .sd_buff_dout(sd_buff_dout),
        .sd_buff_wr(sd_buff_wr), .sd_buff_din(sd_buff_din),
        .img_mounted(img_mounted), .img_size(img_size),
        .activa(dbg_disc),
        .win_req(win_req), .win_addr(win_addr), .win_a16(win_a16),
        .win_wr(win_wr), .win_din(win_din), .win_dout(win_dout), .win_done(win_done)
    );

    //------------------------------------------------------------------
    // Decodificado de memoria
    //------------------------------------------------------------------
    wire        ram_cs, rom_cs, ram_oor;
    wire [14:0] ram_addr_base;
    wire [15:0] rom_off;
    wire [20:0] ram_phys;

    newbrain_mem mem_decode (
        .addr(cpu_addr), .pwrup(pwrup),
        .romov(1'b1), .exrm(3'd0), .raminh(1'b0), .disc_rom(disc_en), .eim(eim),
        .paging_on(paging_on), .page(page), .page_ok(page_ok), .ram_size(ram_size),
        .ram_cs(ram_cs), .ram_addr(ram_addr_base),
        .rom_cs(rom_cs), .rom_addr(rom_off),
        .ram_phys(ram_phys), .ram_oor(ram_oor)
    );

    // El mismo decodificador para la direccion que trae la controladora
    // por su ventana paginada: la misma paginacion que ve la CPU, con el
    // juego de ranuras que pida ella (MA16)
    wire        fdc_ram_cs, fdc_rom_cs, fdc_ram_oor;
    wire [15:0] fdc_rom_off;
    wire [20:0] fdc_ram_phys;
    newbrain_mem mem_decode_fdc (
        .addr(win_addr), .pwrup(pwrup),
        .romov(1'b1), .exrm(3'd0), .raminh(1'b0), .disc_rom(disc_en), .eim(eim),
        .paging_on(paging_on), .page(fdc_page), .page_ok(fdc_page_ok), .ram_size(ram_size),
        .ram_cs(fdc_ram_cs), .ram_addr(),
        .rom_cs(fdc_rom_cs), .rom_addr(fdc_rom_off),
        .ram_phys(fdc_ram_phys), .ram_oor(fdc_ram_oor)
    );
    // Lo que no es RAM ni ROM lee FF y no escribe; se contesta al momento
    wire        fdc_usa_sdram = (fdc_rom_cs & ~win_wr) | (fdc_ram_cs & ~fdc_ram_oor);
    wire [23:0] fdc_sd_addr   = fdc_rom_cs ? {8'd0, fdc_rom_off}
                                           : RAM_BASE + {3'd0, fdc_ram_phys};

    //------------------------------------------------------------------
    // SDRAM: puerto A el video, puerto B la CPU, la controladora y la carga
    //------------------------------------------------------------------
    wire [23:0] vid_sd_addr;
    wire        vid_sd_rd;
    wire [15:0] vid_sd_dout;
    wire        vid_sd_ack;

    reg  [23:0] b_addr;
    reg  [7:0]  b_din;
    reg         b_rd, b_wr;
    wire [7:0]  b_dout;
    wire        b_ack, b_free;

    //------------------------------------------------------------------
    // Arbitro del puerto B: CPU, cinta y carga desde SD
    //
    // Un unico dueño a la vez, que se suelta con b_ack. Antes cada cliente
    // llevaba su propio indicador de ocupado y podian pisarse: una escritura
    // de data_io seguida en el ciclo siguiente de una peticion de la CPU
    // hacia que el controlador descartara la segunda (b_hold ya estaba a
    // uno) y la CPU se quedaba parada para siempre. Con la maquina en reset
    // no pasaba nada; al cargar una cinta en marcha, si.
    //
    // La carga desde SD tiene prioridad y se retiene en un registro propio,
    // y data_io no suelta otro byte hasta que este se ha escrito.
    //------------------------------------------------------------------
    localparam [2:0] OWN_NADIE = 3'd0, OWN_CPU = 3'd1,
                     OWN_CINTA = 3'd2, OWN_CARGA = 3'd3, OWN_FDC = 3'd4;
    reg  [2:0]  b_own;

    // La controladora: su ciclo se da por hecho cuando llega el ack, o al
    // momento si no toca la SDRAM (bus abierto: lee FF).
    //
    // Su direccion pasa por el paginador, el decodificador y la suma de la
    // base de RAM: demasiado para el mismo ciclo que el arbitro (no cumplia
    // tiempos a 32 MHz, y alargaba tambien la ruta de la CPU, que va detras
    // en la prioridad). Se registra la traduccion y el arbitro solo ve
    // señales ya registradas. La controladora esta parada esperando, asi que
    // el ciclo de mas no se nota. fdc_hecho evita pedir dos veces el mismo
    // acceso mientras win_req baja.
    reg         fdc_vacio;
    reg         fdc_pide, fdc_sd, fdc_hecho, fdc_wr_r;
    reg  [23:0] fdc_addr_r;
    reg  [7:0]  fdc_din_r;
    assign win_done = (b_ack & (b_own == OWN_FDC)) | fdc_vacio;
    assign win_dout = fdc_vacio ? 8'hFF : b_dout;
    always @(posedge clk_sys) begin
        fdc_pide   <= win_req;
        fdc_sd     <= fdc_usa_sdram;
        fdc_addr_r <= fdc_sd_addr;
        fdc_wr_r   <= win_wr;
        fdc_din_r  <= win_din;
        if (!win_req)      fdc_hecho <= 1'b0;
        else if (win_done) fdc_hecho <= 1'b1;
    end
    wire fdc_listo = fdc_pide & ~fdc_hecho & ~win_done;
    reg         dl_pend;
    reg  [23:0] dl_a;
    reg  [7:0]  dl_d;

    wire b_puede = b_free && (b_own == OWN_NADIE);

    // data_io solo escribe cuando esto esta a uno, y lo hace UN ciclo
    // despues de verlo. Por eso tambien se baja mientras dl_wr esta activo:
    // si no, un segundo byte podria llegar antes de que el primero pase a
    // dl_pend, y si la CPU se ha quedado el puerto entretanto lo pisaria.
    assign sdram_free = b_puede && !dl_pend && !dl_wr;

    newbrain_sdram #(.CLK_HZ(CLK_HZ)) sdram (
        .clk(clk_sys), .reset(mem_reset),
        .SDRAM_A(SDRAM_A), .SDRAM_DQ(SDRAM_DQ),
        .SDRAM_DQML(SDRAM_DQML), .SDRAM_DQMH(SDRAM_DQMH),
        .SDRAM_nWE(SDRAM_nWE), .SDRAM_nCAS(SDRAM_nCAS),
        .SDRAM_nRAS(SDRAM_nRAS), .SDRAM_nCS(SDRAM_nCS),
        .SDRAM_BA(SDRAM_BA), .SDRAM_CKE(SDRAM_CKE),
        .a_addr(vid_sd_addr), .a_rd(vid_sd_rd),
        .a_dout(vid_sd_dout), .a_ack(vid_sd_ack),
        .b_addr(b_addr), .b_din(b_din), .b_rd(b_rd), .b_wr(b_wr),
        .b_dout(b_dout), .b_ack(b_ack), .b_free(b_free)
    );

    //------------------------------------------------------------------
    // Acceso de la CPU a la memoria
    //------------------------------------------------------------------

    // Lo que sale por SDRAM: la ROM siempre, la RAM si esta instalada.
    // El hueco de 8000 sin ROM de disco es bus abierto y no toca la memoria.
    wire use_sdram = ((rom_cs & mem_rd)
                   | (ram_cs & ~ram_oor & (mem_rd | mem_wrq)))
                   & ~disc_ram_sel;

    wire [23:0] cpu_sd_addr = rom_cs ? {8'd0, rom_off}
                                     : RAM_BASE + {3'd0, ram_phys};

    reg [7:0] mem_data;
    reg       mem_done;

    assign cpu_stall = use_sdram & ~mem_done;

    always @(posedge clk_sys) begin
        b_rd <= 1'b0;
        b_wr <= 1'b0;

        // La carga desde SD ocurre precisamente mientras la maquina esta en
        // reset, asi que este camino vive fuera de el.
        if (dl_wr) begin
            dl_pend <= 1'b1;
            dl_a    <= dl_addr;
            dl_d    <= dl_data;
        end

        if (b_ack) begin
            if (b_own == OWN_CPU) begin
                mem_data <= b_dout;
                mem_done <= 1'b1;
            end
            b_own <= OWN_NADIE;
        end

        fdc_vacio <= fdc_listo & ~fdc_sd & ~fdc_vacio;

        if (b_puede) begin
            if (dl_pend) begin
                b_addr  <= dl_a;
                b_din   <= dl_d;
                b_wr    <= 1'b1;
                b_own   <= OWN_CARGA;
                dl_pend <= dl_wr;       // no deberia coincidir, pero por si acaso
                if (dl_wr) begin dl_a <= dl_addr; dl_d <= dl_data; end
            end else if (!reset && tape_sd_rd) begin
                // La cinta pide un byte cada milisegundo como mucho: va por
                // delante de la CPU sin riesgo de dejarla sin servicio.
                b_addr <= tape_sd_addr;
                b_rd   <= 1'b1;
                b_own  <= OWN_CINTA;
            end else if (!reset && fdc_listo && fdc_sd) begin
                // La controladora: pocos accesos y su Z80 espera parado
                b_addr <= fdc_addr_r;
                b_din  <= fdc_din_r;
                b_rd   <= ~fdc_wr_r;
                b_wr   <= fdc_wr_r;
                b_own  <= OWN_FDC;
            end else if (!reset && use_sdram && !mem_done) begin
                b_addr <= cpu_sd_addr;
                b_din  <= cpu_dout;
                b_rd   <= mem_rd;
                b_wr   <= mem_wrq;
                b_own  <= OWN_CPU;
            end
        end

        if (reset || !mem_cyc) mem_done <= 1'b0;

        // Si el controlador se reinicia no va a contestar
        if (mem_reset) begin
            b_own   <= OWN_NADIE;
            dl_pend <= 1'b0;
            fdc_vacio <= 1'b0;
        end
    end

    //------------------------------------------------------------------
    // Video
    //------------------------------------------------------------------
    wire [7:0] cg_char, cg_data;
    wire [3:0] cg_line;

    newbrain_chargen chargen (
        .clk(clk_pix), .wr_clk(clk_sys), .char(cg_char), .line(cg_line), .dout(cg_data),
        .wr_addr(cg_wr_addr), .wr_data(cg_wr_data), .wr_en(cg_wr_en)
    );

    newbrain_video video (
        .clk(clk_sys), .clk_pix(clk_pix), .ce_pix(ce_pix), .reset(reset),
        .tv_enable_in(tv_enable),
        .h_off(h_off), .v_off(v_off),
        .tv_addr_in(tv_addr), .tvtl_in(tvtl),
        .sd_addr(vid_sd_addr), .sd_rd(vid_sd_rd),
        .sd_dout(vid_sd_dout), .sd_ack(vid_sd_ack),
        .ram_base(RAM_BASE),
        .cg_char(cg_char), .cg_line(cg_line), .cg_data(cg_data),
        .R(vid_r), .G(vid_g), .B(vid_b),
        .hsync(vid_hs), .hsync_cs(vid_hs_cs), .vsync(vid_vs),
        .hblank(vid_hb), .vblank(vid_vb),
        .vsync_pulse()
    );

    //------------------------------------------------------------------
    // Multiplexor de lectura hacia la CPU
    //------------------------------------------------------------------
    always @* begin
        if (~iorq_n)         cpu_din = io_dout_oe ? io_dout : 8'hFF;
        else if (disc_ram_sel & mem_rd) cpu_din = disc_ram_dout;
        else if (use_sdram)  cpu_din = mem_data;
        else                 cpu_din = 8'hFF;   // hueco, o RAM no instalada
    end

endmodule

`default_nettype wire
