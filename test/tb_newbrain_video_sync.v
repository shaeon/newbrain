`timescale 1ns/1ps
//
// Sincronismos y lineas de la salida de 15 kHz.
//
// Mide lo que sale del generador de imagen y lo que sale de mist_video con el
// scandoubler desactivado, que es lo que llega a una tele por euroconector:
//
//   generador  duracion de linea y de hsync en puntos, lineas por trama,
//              lineas de vsync, vsync alineada con hsync, blanqueo que tapa
//              los sincronismos, 640x250 visibles, donde empieza la imagen
//              (puntos desde hsync y lineas desde vsync) y que la primera
//              linea visible sea la linea 0 de la fila 0 con cualquier ajuste
//              de centrado
//   mist_video el sincronismo compuesto de VGA_HS: 312 flancos de bajada por
//              trama, uno al principio de cada linea y todos a una linea
//              exacta del anterior; 309 pulsos del ancho de hsync y 3 anchos
//              de vsync, nada mas, y VGA_VS fijo a uno
//
// Cada linea visible se identifica por su primera celda: el generador de
// caracteres de este banco devuelve {1, linea de celda, codigo[3:1], 0}, y la
// fila r lleva el codigo 40h + 2*(r mod 8). El bit 0 va a cero para no
// disparar la regla del descendente, y se usan celdas de 8 lineas.
//
// Se pasa en Original y en Wide (ANCHO=1), y en cada una con varios ajustes
// de H centre y V centre del OSD.
//
module tb_newbrain_video_sync;
    parameter ANCHO = 0;

    localparam H_TOT   = ANCHO ? 864 : 1024;
    localparam H_SYNC  = ANCHO ? 64  : 76;
    localparam H_START = ANCHO ? 144 : 230;
    localparam V_TOT   = 312;
    localparam V_SYNC  = 3;
    localparam V_START = 33;

    reg clk = 0, reset = 1, ce_pix = 0;
    reg [15:0] tv_addr = 16'h1000;
    reg [7:0]  tvtl = 8'h48;      // 80 columnas, 8 lineas por caracter
    reg        tv_enable = 1;
    reg signed [7:0] h_off = 0, v_off = 0;

    wire [23:0] sd_addr;
    wire        sd_rd;
    reg  [15:0] sd_dout;
    reg         sd_ack;
    wire [7:0]  cg_char;
    wire [3:0]  cg_line;
    reg  [7:0]  cg_data;
    wire [7:0]  R, G, B;
    wire hsync, hsync_cs, vsync, hblank, vblank, vsync_pulse;

    integer errors = 0, avisos = 0;
    integer i;

    reg [7:0] mem [0:32767];

    always #5 clk = ~clk;
    reg clkp = 0;
    always #5.926 clkp = ~clkp;                     // 32/27 del periodo de clk
    wire clk_pix = ANCHO ? clkp : clk;
    always @(posedge clk_pix) ce_pix <= ~ce_pix;

    // Generador de caracteres: una lectura de latencia, como newbrain_chargen
    always @(posedge clk_pix) cg_data <= {1'b1, cg_line[2:0], cg_char[3:1], 1'b0};

    // SDRAM con latencia
    localparam LAT = 9;
    reg [23:0] pend_addr;
    integer    lat = 0;
    always @(posedge clk) begin
        sd_ack <= 1'b0;
        if (sd_rd) begin
            pend_addr <= sd_addr;
            lat = LAT;
        end else if (lat > 0) begin
            lat = lat - 1;
            if (lat == 0) begin
                sd_dout <= {mem[pend_addr + 1], mem[pend_addr]};
                sd_ack  <= 1'b1;
            end
        end
    end

    newbrain_video dut (
        .clk(clk), .clk_pix(clk_pix), .ce_pix(ce_pix), .reset(reset), .ancho(ANCHO[0]),
        .tv_enable_in(tv_enable), .h_off(h_off), .v_off(v_off),
        .tv_addr_in(tv_addr), .tvtl_in(tvtl),
        .sd_addr(sd_addr), .sd_rd(sd_rd),
        .sd_dout(sd_dout), .sd_ack(sd_ack), .ram_base(24'd0),
        .cg_char(cg_char), .cg_line(cg_line), .cg_data(cg_data),
        .R(R), .G(G), .B(B),
        .hsync(hsync), .hsync_cs(hsync_cs), .vsync(vsync), .hblank(hblank), .vblank(vblank),
        .vsync_pulse(vsync_pulse)
    );

    // La misma cadena de salida que newbrain_top, con el scandoubler
    // desactivado y el sincronismo compuesto encendido: 15 kHz por SCART.
    // En ese modo el top le pasa hsync_cs en vez de hsync.
    wire [5:0] VGA_R, VGA_G, VGA_B;
    wire       VGA_HS, VGA_VS;
    mist_video #(
        .COLOR_DEPTH(8), .SD_HCNT_WIDTH(11), .USE_BLANKS(1'b1),
        .OSD_COLOR(3'b001), .OUT_COLOR_DEPTH(6), .BIG_OSD(1'b1))
    mv (
        .clk_sys(clk_pix),
        .SPI_SCK(1'b0), .SPI_SS3(1'b1), .SPI_DI(1'b0),
        .scanlines(2'b00), .ce_divider(3'd1),
        .scandoubler_disable(1'b1), .no_csync(1'b0), .ypbpr(1'b0),
        .rotate(2'b00), .blend(1'b0),
        .R(R), .G(G), .B(B),
        .HBlank(hblank), .VBlank(vblank), .HSync(hsync_cs), .VSync(vsync),
        .osd_enable(),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_VS(VGA_VS), .VGA_HS(VGA_HS),
        .VGA_HB(), .VGA_VB(), .VGA_DE()
    );

    //------------------------------------------------------------------
    // Medidas sobre la salida del generador, en puntos (ce_pix). Cada
    // trama va de una subida de vsync a la siguiente; al llegar la subida
    // se guardan en f_* y se ponen a cero.
    //------------------------------------------------------------------
    reg hs_d = 0, vs_d = 0, hb_d = 1, vb_d = 1;
    integer px = 0, px_ok = 0, hsw = 0, lin = 0, vis = 0;
    integer lmin, lmax, hswmin, hswmax, lineas, lin_vs, vis_lin, err_vis;
    integer h_ini, v_ini, err_sb, err_rb, err_alin, err_cont;
    integer f_lmin, f_lmax, f_hswmin, f_hswmax, f_lineas, f_lin_vs, f_vis_lin;
    integer f_err_vis, f_h_ini, f_v_ini, f_err_sb, f_err_rb, f_err_alin, f_err_cont;
    integer f_cs_corto, f_cs_largo, f_cs_otro, f_err_vgavs;
    reg [1023:0] f_primer_fallo, primer_fallo;
    integer tramas = 0;
    integer cs_bajo = 0, cs_corto = 0, cs_largo = 0, cs_otro = 0, err_vgavs = 0;
    integer cs_otro_ancho = 0;
    integer cs_flancos = 0, cs_desde = -1, err_cs_int = 0, cs_int_malo = 0;
    integer f_cs_flancos, f_err_cs_int;

    // Contenido: la primera celda de cada linea visible
    integer cap_n = 8;
    reg [7:0] cap_b;
    integer y_act;
    reg [7:0] esperado;

    task limpia_trama;
        begin
            lmin = 99999; lmax = 0; hswmin = 99999; hswmax = 0;
            lineas = 0; lin_vs = 0; vis_lin = 0; err_vis = 0;
            h_ini = -1; v_ini = -1; err_sb = 0; err_rb = 0; err_alin = 0;
            err_cont = 0; primer_fallo = "";
        end
    endtask
    initial limpia_trama;

    always @(posedge clk_pix) if (ce_pix && !reset) begin
        px = px + 1;

        // linea y ancho de hsync
        if (hsync && !hs_d) begin
            if (px_ok) begin
                if (px < lmin) lmin = px;
                if (px > lmax) lmax = px;
            end
            px_ok = 1;
            px = 0;
            lin = lin + 1;
            lineas = lineas + 1;
            if (vsync && vs_d) lin_vs = lin_vs + 1;
        end
        if (hsync) hsw = hsw + 1;
        if (!hsync && hs_d) begin
            if (hsw < hswmin) hswmin = hsw;
            if (hsw > hswmax) hswmax = hsw;
            hsw = 0;
        end

        // vsync debe cambiar a la vez que empieza una hsync
        if ((vsync != vs_d) && !(hsync && !hs_d)) err_alin = err_alin + 1;

        // el blanqueo tiene que tapar los sincronismos y la imagen no puede
        // salir por fuera de la zona visible
        if ((hsync && !hblank) || (vsync && !vblank)) err_sb = err_sb + 1;
        if ((hblank || vblank) && R != 8'h00) err_rb = err_rb + 1;

        // puntos visibles por linea
        if (!hblank && !vblank) vis = vis + 1;
        if (hblank && !hb_d) begin
            if (vis > 0) begin
                if (vis != 640) err_vis = err_vis + 1;
                vis_lin = vis_lin + 1;
            end
            vis = 0;
        end

        // donde empieza la imagen
        if (!vblank && vb_d && v_ini < 0) v_ini = lin;
        if (!hblank && hb_d && !vblank && h_ini < 0) h_ini = px;

        // primera celda de cada linea visible
        if (!hblank && hb_d && !vblank) begin
            cap_n = 0;
            y_act = vis_lin;
        end
        if (cap_n < 8) begin
            cap_b = {cap_b[6:0], R[7]};
            cap_n = cap_n + 1;
            if (cap_n == 8) begin
                esperado = {1'b1, y_act[2:0], y_act[5:3], 1'b0};
                if (cap_b != esperado) begin
                    if (err_cont == 0)
                        $sformat(primer_fallo, "linea visible %0d: fila %0d linea %0d, se esperaba fila %0d linea %0d",
                                 y_act, cap_b[3:1], cap_b[6:4], y_act[5:3], y_act[2:0]);
                    err_cont = err_cont + 1;
                end
            end
        end

        // cierre de trama
        if (vsync && !vs_d) begin
            f_lmin = lmin; f_lmax = lmax; f_hswmin = hswmin; f_hswmax = hswmax;
            f_lineas = lineas; f_lin_vs = lin_vs; f_vis_lin = vis_lin;
            f_err_vis = err_vis; f_h_ini = h_ini; f_v_ini = v_ini;
            f_err_sb = err_sb; f_err_rb = err_rb; f_err_alin = err_alin;
            f_err_cont = err_cont; f_primer_fallo = primer_fallo;
            f_cs_corto = cs_corto; f_cs_largo = cs_largo; f_cs_otro = cs_otro;
            f_err_vgavs = err_vgavs;
            f_cs_flancos = cs_flancos; f_err_cs_int = err_cs_int;
            cs_flancos = 0; err_cs_int = 0;
            limpia_trama;
            cs_corto = 0; cs_largo = 0; cs_otro = 0; err_vgavs = 0;
            lin = 0;
            lin_vs = 1;     // la linea donde sube vsync ya es de vsync
            lineas = 0;     // se cuenta en la subida de hsync, que ya paso
            tramas = tramas + 1;
        end

        hs_d = hsync; vs_d = vsync; hb_d = hblank; vb_d = vblank;
    end

    //------------------------------------------------------------------
    // Sincronismo compuesto en VGA_HS, en ciclos de clk_pix (dos por
    // punto). Se clasifican los pulsos a nivel bajo.
    //------------------------------------------------------------------
    reg cs_d = 1;
    always @(posedge clk_pix) if (!reset) begin
        if (!VGA_HS) cs_bajo = cs_bajo + 1;
        if (VGA_HS && !cs_d) begin
            if (cs_bajo >= 2*H_SYNC - 2 && cs_bajo <= 2*H_SYNC + 2) cs_corto = cs_corto + 1;
            else if (cs_bajo > H_TOT) cs_largo = cs_largo + 1;
            else begin cs_otro = cs_otro + 1; cs_otro_ancho = cs_bajo; end
            cs_bajo = 0;
        end
        if (VGA_VS !== 1'b1) err_vgavs = err_vgavs + 1;
        // Cada flanco de bajada marca el principio de una linea: tiene que
        // haber uno por linea y todos a una linea exacta del anterior
        if (cs_desde >= 0) cs_desde = cs_desde + 1;
        if (!VGA_HS && cs_d) begin
            if (cs_desde >= 0 && cs_desde != 2*H_TOT) begin
                err_cs_int = err_cs_int + 1; cs_int_malo = cs_desde;
            end
            cs_desde = 0;
            cs_flancos = cs_flancos + 1;
        end
        cs_d = VGA_HS;
    end

    //------------------------------------------------------------------
    task chk(input [255:0] name, input cond);
        begin
            if (!cond) begin
                $display("  FAIL %0s", name);
                errors = errors + 1;
            end
        end
    endtask

    task espera_tramas(input integer n);
        integer t0;
        begin
            t0 = tramas;
            wait (tramas >= t0 + n);
        end
    endtask

    task probar(input integer ho, input integer vo);
        integer e0;
        begin
            h_off = ho; v_off = vo;
            // una trama para asentar el cambio y otra limpia para medir
            espera_tramas(3);
            e0 = errors;
            $display("H %0d V %0d: linea %0d, hsync %0d, %0d lineas, vsync %0d lineas, %0d visibles, imagen en (%0d, %0d), csync %0d flancos, %0d cortos %0d largos %0d otros",
                     ho, vo, f_lmax, f_hswmax, f_lineas, f_lin_vs, f_vis_lin,
                     f_h_ini, f_v_ini, f_cs_flancos, f_cs_corto, f_cs_largo, f_cs_otro);
            chk("linea de H_TOT puntos",        f_lmin == H_TOT && f_lmax == H_TOT);
            chk("hsync de H_SYNC puntos",       f_hswmin == H_SYNC && f_hswmax == H_SYNC);
            chk("312 lineas por trama",         f_lineas == V_TOT);
            chk("vsync de 3 lineas",            f_lin_vs == V_SYNC);
            chk("vsync alineada con hsync",     f_err_alin == 0);
            chk("blanqueo sobre los sincronismos", f_err_sb == 0);
            chk("nada fuera de la zona visible", f_err_rb == 0);
            chk("250 lineas visibles",          f_vis_lin == 250);
            chk("640 puntos en cada linea",     f_err_vis == 0);
            chk("comienzo horizontal",          f_h_ini == H_START + ho);
            chk("comienzo vertical",            f_v_ini == V_START + vo);
            if (f_err_cont != 0)
                $display("  FAIL contenido: %0d lineas mal, la primera %0s", f_err_cont, f_primer_fallo);
            if (f_err_cont != 0) errors = errors + 1;
            chk("csync: 309 pulsos de hsync",   f_cs_corto == V_TOT - V_SYNC);
            chk("csync: 3 pulsos anchos de vsync", f_cs_largo == V_SYNC);
            chk("csync: 312 flancos de bajada por trama", f_cs_flancos == V_TOT);
            if (f_err_cs_int != 0)
                $display("  FAIL csync: %0d flancos fuera de sitio (uno a %0d ciclos del anterior)", f_err_cs_int, cs_int_malo);
            if (f_err_cs_int != 0) errors = errors + 1;
            if (f_cs_otro != 0)
                $display("  FAIL csync: %0d pulsos de ancho raro (el ultimo, %0d ciclos)", f_cs_otro, cs_otro_ancho);
            if (f_cs_otro != 0) errors = errors + 1;
            chk("VGA_VS fijo a uno",            f_err_vgavs == 0);
        end
    endtask

    //------------------------------------------------------------------
    initial begin
        // Filas de 128 bytes (80 columnas) desde tv_addr + START_OFS_80. Dos
        // caracteres y el fin de linea.
        for (i = 0; i < 32768; i = i + 1) mem[i] = 8'h00;
        for (i = 0; i < 32; i = i + 1) begin
            mem[16'h1004 + i*128]     = 8'h40 + 2*(i % 8);
            mem[16'h1004 + i*128 + 1] = 8'h40 + 2*(i % 8);
        end

        repeat (10) @(negedge clk);
        reset = 0;
        espera_tramas(2);

        probar(0, 0);
        probar(0, -8);
        probar(0, -2);
        probar(0, 2);
        probar(0, 6);
        probar(-32, 0);
        probar(24, 0);
        h_off = 0; v_off = 0;
        espera_tramas(2);

        // Durante el reset (el boton, o cada vez que se carga una ROM) la
        // tele no deberia quedarse sin sincronismo. No es un fallo de
        // imagen, solo un aviso.
        begin : durante_reset
            integer flancos;
            reg h_ant;
            flancos = 0;
            h_ant = VGA_HS;
            reset = 1;
            repeat (H_TOT * 20) begin
                @(posedge clk_pix);
                if (VGA_HS != h_ant) flancos = flancos + 1;
                h_ant = VGA_HS;
            end
            reset = 0;
            if (flancos < 10) begin     // con sincronismo serian unos 20
                $display("AVISO: con reset no sale sincronismo (%0d flancos en 10 lineas)", flancos);
                avisos = avisos + 1;
            end
        end

        if (errors == 0) begin
            if (ANCHO) $display("tb_newbrain_video_sync (Wide): OK%0s", avisos ? ", con avisos" : "");
            else       $display("tb_newbrain_video_sync: OK%0s", avisos ? ", con avisos" : "");
        end else begin
            $display("tb_newbrain_video_sync%0s: %0d FALLOS", ANCHO ? " (Wide)" : "", errors);
            $fatal;
        end
        $finish;
    end
endmodule
