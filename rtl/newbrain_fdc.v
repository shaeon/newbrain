//============================================================================
// NewBrain - controladora de disco de VERDAD
//
// Es otro ordenador colgado del bus de expansion, y aqui se hace igual: un
// segundo Z80 ejecuta la ROM original de la controladora (d417, issue 1 o
// 2) y habla con un uPD765 que lee y escribe imagenes EDSK de la SD
// (u765.sv, el de los cores de Amstrad y Spectrum de MiST).
//
// Sustituye al HLE anterior (newbrain_disc.v), que hacia el trabajo de la
// d417 a mano. Ahora el codigo de Grundy hace el suyo.
//
// Cableado, sacado de la propia d417 y de fdc.cpp de MAME, y comprobado en
// tools/nbfdc.py con las ROMs originales: CP/M arranca, DIR, STAT y SAVE.
//
//   Z80 de la controladora (4 MHz)
//     0000-1FFF  ROM d417. Solo usa hasta 0420h: se guardan 2K y lo demas
//                lee FF, como en MAME.
//     8000-FFFF  ventana al bus del NewBrain: direccion = {PA15, A14..A0}.
//                La controladora no tiene RAM propia: su bloque de
//                parametros y el buffer de sector estan en la RAM
//                compartida 9C00-9FFF, que es lo unico que responde aqui
//                sin paginacion. (Con paginacion la d417 lee el puntero del
//                bloque en 8079h, en RAM del NewBrain: no soportado aun.)
//     E/S (mascara 71h, las demas lineas no se decodifican)
//       00/01  uPD765: estado / datos
//       20     escritura: b0 motor, b1 reset del 765, b2 TC, b5 PA15
//       40     lectura:   b7 FDC ATT, b6 PAGING, b5 INT del 765
//
//   NewBrain
//     9C00-9FFF  RAM compartida, 1K, encima de los ultimos 1K de la d413
//     puerto FF con A9 = 1 (OUT (C),A con B = 02): registro de control
//       b0 PAGING, b2 MA16, b3 MPM, b5 _FDC RESET, b7 FDC ATT
//
// Apreton de manos, tal como lo hacen las dos ROMs: el NewBrain pone
// CRESULT a 0 y levanta ATT; la d417 lee el puntero al bloque de 9C00, deja
// CRESULT = FF y espera a que ATT baje; el NewBrain la baja y la d417
// ejecuta el comando y deja el resultado.
//============================================================================
`default_nettype none

module newbrain_fdc (
    input  wire        clk,             // 32 MHz
    input  wire        reset,           // reset de la maquina
    input  wire        enable,          // hay controladora

    // E/S del NewBrain
    input  wire [15:0] io_addr,
    input  wire [7:0]  io_data,
    input  wire        io_wr,           // nivel durante el ciclo de escritura

    // RAM compartida, lado del NewBrain
    input  wire [9:0]  ram_addr,
    input  wire [7:0]  ram_din,
    input  wire        ram_we,
    output reg  [7:0]  ram_dout,

    // Carga de la ROM d417 (primeros 2K del bloque de 8K)
    input  wire        rom_wr,
    input  wire [10:0] rom_addr,
    input  wire [7:0]  rom_data,

    // Imagenes EDSK en la SD, protocolo de user_io
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

    output wire        activa,          // motor en marcha, para un LED

    // Ventana paginada: con el modulo de expansion la d417 no usa la RAM
    // compartida sino que sale al bus del NewBrain con {PA15, A14..A0} y
    // pasa por la paginacion, como la CPU. Un ciclo se pide con win_req y
    // se completa con win_done; entretanto el Z80 de la controladora espera.
    output wire        win_req,
    output wire [15:0] win_addr,        // direccion del NewBrain
    output wire        win_a16,         // MA16: juego de ranuras a usar
    output wire        win_wr,
    output wire [7:0]  win_din,
    input  wire [7:0]  win_dout,
    input  wire        win_done
);

    //------------------------------------------------------------------
    // Registro de control del NewBrain (puerto FF con A9)
    //
    // Arranca con _FDC RESET a uno: la controladora corre desde el
    // principio, como en MAME, y esta esperando ATT cuando el NewBrain
    // llama por primera vez.
    //------------------------------------------------------------------
    reg  [7:0] ctl = 8'h20;
    reg        io_wr_d = 1'b0;
    always @(posedge clk) begin
        io_wr_d <= io_wr;
        if (reset)
            ctl <= 8'h20;
        else if (enable & io_wr & ~io_wr_d
                 & (io_addr[7:0] == 8'hFF) & io_addr[9])
            ctl <= io_data;
    end

    wire paging = ctl[0];
    wire att    = ctl[7];

    //------------------------------------------------------------------
    // Registro auxiliar de la controladora (su puerto 20)
    //------------------------------------------------------------------
    reg aux_motor, aux_rst765, aux_pa15;

    wire fdc_reset = reset | ~enable | ~ctl[5];

    //------------------------------------------------------------------
    // Z80 de la controladora, a 4 MHz como el original
    //------------------------------------------------------------------
    reg [2:0] div = 3'd0;
    always @(posedge clk) div <= div + 1'b1;
    // Mientras hay un acceso por la ventana paginada en curso, el Z80 se
    // queda parado (como la CPU principal con la SDRAM)
    // La espera va registrada: sale de la direccion del Z80 y para al Z80
    // entero, demasiado para un solo ciclo a 32 MHz. Es seguro porque el Z80
    // solo cambia sus salidas en cen_p o cen_n, que estan a 4 ciclos, y la
    // espera registrada llega al siguiente.
    reg       espera = 1'b0;
    wire cen_p = (div == 3'd0) & ~espera;
    wire cen_n = (div == 3'd4) & ~espera;

    wire [15:0] a;
    wire [7:0]  cpu_dout;
    reg  [7:0]  cpu_din;
    wire        m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n;

    T80pa fcpu (
        .RESET_n(~fdc_reset), .CLK(clk), .CEN_p(cen_p), .CEN_n(cen_n),
        .WAIT_n(1'b1), .INT_n(1'b1), .NMI_n(1'b1), .BUSRQ_n(1'b1),
        .M1_n(m1_n), .MREQ_n(mreq_n), .IORQ_n(iorq_n), .RD_n(rd_n),
        .WR_n(wr_n), .RFSH_n(rfsh_n), .HALT_n(), .BUSAK_n(),
        .A(a), .DI(cpu_din), .DO(cpu_dout)
    );

    wire mem_cyc = ~mreq_n & rfsh_n;
    wire mem_rd  = mem_cyc & ~rd_n;
    wire mem_wr  = mem_cyc & ~wr_n;
    wire io_cyc  = ~iorq_n & m1_n;
    wire io_rd   = io_cyc & ~rd_n;
    wire io_wrc  = io_cyc & ~wr_n;

    //------------------------------------------------------------------
    // ROM d417: 2K, cargada con el fichero de ROM
    //------------------------------------------------------------------
    reg [7:0] rom [0:2047];
    reg [7:0] rom_q;
    always @(posedge clk) begin
        if (rom_wr) rom[rom_addr] <= rom_data;
        rom_q <= rom[a[10:0]];
    end
    wire sel_rom = ~a[15] & (a[14:11] == 4'd0);

    //------------------------------------------------------------------
    // Ventana al bus del NewBrain: solo la RAM compartida
    //------------------------------------------------------------------
    wire [15:0] dir_anfitrion = {aux_pa15, a[14:0]};
    wire        sel_comp = a[15] & ~paging & (dir_anfitrion[15:10] == 6'b100111);

    //------------------------------------------------------------------
    // Ventana paginada (PAGING a uno): todo lo que caiga en 8000-FFFF sale
    // al NewBrain. Se pide una vez por ciclo de bus y se espera la
    // respuesta; el dato leido se guarda para el resto del ciclo.
    //------------------------------------------------------------------
    wire        sel_win = a[15] & paging & enable;
    wire        win_cyc = sel_win & (mem_rd | mem_wr);
    reg         win_hecho;
    reg  [7:0]  win_q;
    always @(posedge clk) begin
        if (!win_cyc)      win_hecho <= 1'b0;
        else if (win_done) begin win_hecho <= 1'b1; win_q <= win_dout; end
    end
    assign win_req  = win_cyc & ~win_hecho;
    assign win_addr = dir_anfitrion;
    assign win_a16  = ctl[2];
    assign win_wr   = mem_wr;
    assign win_din  = cpu_dout;
    always @(posedge clk)
        espera <= win_cyc & ~win_hecho & ~win_done;

    //------------------------------------------------------------------
    // RAM compartida, 1K. Un solo puerto de escritura que se turna ciclo a
    // ciclo entre los dos procesadores: los dos escriben durante muchos
    // ciclos seguidos (el ciclo de bus entero), asi que ninguno se queda sin
    // su turno. Dos puertos de lectura: Quartus duplica la memoria.
    //------------------------------------------------------------------
    reg  [7:0] ram [0:1023];
    reg  [7:0] ram_fdc_q;
    reg        turno = 1'b0;
    wire       fdc_we  = mem_wr & sel_comp;
    // si escriben los dos a la vez, en los ciclos impares gana la
    // controladora y en los pares el NewBrain
    wire       usa_fdc = fdc_we & (turno | ~ram_we);
    always @(posedge clk) begin
        turno <= ~turno;
        if (usa_fdc)
            ram[dir_anfitrion[9:0]] <= cpu_dout;
        else if (ram_we)
            ram[ram_addr] <= ram_din;
        ram_dout  <= ram[ram_addr];
        ram_fdc_q <= ram[dir_anfitrion[9:0]];
    end

    //------------------------------------------------------------------
    // uPD765 con imagenes EDSK
    //------------------------------------------------------------------
    // Reloj del 765: 8 MHz, que es para lo que esta calibrado CYCLES
    reg [1:0] div765 = 2'd0;
    always @(posedge clk) div765 <= div765 + 1'b1;
    wire ce765 = (div765 == 2'd0);

    // Con la mascara 71h solo cuentan A6 y A5 para elegir dispositivo: A4
    // es espejo (00 y 10 son el mismo 765) y A0 elige estado o datos.
    wire       sel_765 = io_cyc & (a[6:5] == 2'b00);
    wire [7:0] dout765;
    wire       int765;

    reg  [1:0] listo = 2'b00;
    always @(posedge clk) begin
        if (img_mounted[0]) listo[0] <= |img_size;
        if (img_mounted[1]) listo[1] <= |img_size;
    end

    u765 #(.CYCLES(20'd4000)) fdc765 (
        .clk_sys(clk),
        .ce(ce765),
        .reset(fdc_reset | aux_rst765),
        .ready(listo),
        .motor({aux_motor, aux_motor}),
        .available(2'b11),
        .fast(1'b0),
        .a0(a[0]),
        .nRD(~(sel_765 & ~rd_n)),
        .nWR(~(sel_765 & ~wr_n)),
        .din(cpu_dout),
        .dout(dout765),
        .int_o(int765),
        .img_mounted(img_mounted),
        .img_wp(1'b0),
        .img_size(img_size),
        .sd_lba(sd_lba),
        .sd_rd(sd_rd),
        .sd_wr(sd_wr),
        .sd_ack(sd_ack),
        .sd_buff_addr(sd_buff_addr),
        .sd_buff_dout(sd_buff_dout),
        .sd_buff_din(sd_buff_din),
        .sd_buff_wr(sd_buff_wr)
    );

    //------------------------------------------------------------------
    // Registro auxiliar: puerto 20 con la mascara 71h (A6..A4 = 010)
    //------------------------------------------------------------------
    reg io_wrc_d = 1'b0;
    always @(posedge clk) begin
        io_wrc_d <= io_wrc;
        if (fdc_reset) begin
            aux_motor  <= 1'b0;
            aux_rst765 <= 1'b0;
            aux_pa15   <= 1'b0;
        end else if (io_wrc & ~io_wrc_d & (a[6:4] == 3'b010)) begin
            aux_motor  <= cpu_dout[0];
            aux_rst765 <= cpu_dout[1];
            aux_pa15   <= cpu_dout[5];
        end
    end

    //------------------------------------------------------------------
    // Lo que lee el Z80 de la controladora
    //------------------------------------------------------------------
    always @* begin
        cpu_din = 8'hFF;
        if (io_cyc) begin
            if (a[6:5] == 2'b00)      cpu_din = dout765;
            else if (a[6:5] == 2'b10) cpu_din = {att, paging, int765, 5'b00000};
        end else if (mem_rd) begin
            if (sel_rom)               cpu_din = rom_q;
            else if (sel_comp)         cpu_din = ram_fdc_q;
            else if (sel_win)          cpu_din = win_q;
        end
    end

    assign activa = aux_motor & ~fdc_reset;

endmodule

`default_nettype wire
