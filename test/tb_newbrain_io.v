`timescale 1ns/1ps
//
// Comprueba el decodificado de puertos, los registros de video, la palabra
// de estado UST y la logica de interrupcion.
//
module tb_newbrain_io;
    reg clk = 0, reset = 1;
    reg [7:0] addr = 0, din = 0;
    wire [7:0] dout;
    wire dout_oe;
    reg iorq_n = 1, m1_n = 1, rd_n = 1, wr_n = 1;
    wire int_n;
    reg pwrup = 1, tape_in = 0, v24_rxd = 0, v24_cts_n = 0, prn_cts_n = 0;
    reg eim = 0, cfg_rev_video = 0, cfg_40col = 1, cfg_tv = 1;
    wire [7:0] enrg2, prn_latch;
    reg clkint_tick = 0;
    wire cop_cs, cop_rd, cop_wr;
    wire [7:0] enrg1;
    reg        cass_leyendo = 0;
    wire tv_enable, tv_load;
    wire [7:0] tvtl;
    wire [15:0] tv_addr;
    integer errors = 0;
    reg [7:0] v14;

    always #5 clk = ~clk;

    newbrain_io dut (
        .clk(clk), .reset(reset),
        .addr(addr), .din(din), .dout(dout), .dout_oe(dout_oe),
        .iorq_n(iorq_n), .m1_n(m1_n), .rd_n(rd_n), .wr_n(wr_n), .int_n(int_n),
        .eim(eim), .cfg_rev_video(cfg_rev_video),
        .cfg_40col(cfg_40col), .cfg_tv(cfg_tv),
        .pwrup(pwrup), .extest(1'b1), .mains_ok(1'b1), .tape_in(tape_in), .cass_leyendo(cass_leyendo),
        .v24_rxd(v24_rxd), .v24_cts_n(v24_cts_n), .prn_cts_n(prn_cts_n),
        .clkint_tick(clkint_tick),
        .cop_cs(cop_cs), .cop_rd(cop_rd), .cop_wr(cop_wr),
        .cop_dout(8'hA5), .copint_n(1'b1),
        .enrg1(enrg1), .enrg2(enrg2), .prn_latch(prn_latch),
        .tv_enable(tv_enable), .tvtl(tvtl),
        .tv_addr(tv_addr), .tv_load(tv_load)
    );

    task io_write(input [7:0] a, input [7:0] d);
        begin
            @(negedge clk); addr = a; din = d; iorq_n = 0; wr_n = 0;
            @(negedge clk); iorq_n = 1; wr_n = 1;
            @(negedge clk);
        end
    endtask

    task io_read(input [7:0] a);
        begin
            @(negedge clk); addr = a; iorq_n = 0; rd_n = 0;
            #1;
            @(negedge clk); iorq_n = 1; rd_n = 1;
        end
    endtask

    task chk(input [255:0] name, input cond);
        begin
            if (!cond) begin
                $display("FAIL %0s", name);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        reset = 0;
        @(negedge clk);

        // --- ENRG1 en 07 ---
        io_write(8'h07, 8'h04);
        chk("ENRG1 = 04", enrg1 == 8'h04);
        chk("TVP activo", tv_enable == 1'b1);

        // el decodificado ignora A5..A7, asi que 27 tambien es ENRG1
        io_write(8'h27, 8'h05);
        chk("alias de ENRG1 en 27", enrg1 == 8'h05);

        // --- registro de modo de video en 0C ---
        io_write(8'h0C, 8'h49);
        chk("TVTL = 49", tvtl == 8'h49);

        // --- direccion de video: 09 carga base, 08 suma 64 ---
        io_write(8'h09, 8'h40);
        chk("TVLL: 40 -> 2000", tv_addr == 16'h2000);
        io_write(8'h08, 8'h00);
        chk("TVLATCH: +64 -> 2040", tv_addr == 16'h2040);

        // --- UST_A en 14 ---
        // La ROM (bucle PWAIT en E009) hace BIT 1,A / JR NZ: espera a que
        // POWTEST valga 0. Por tanto vale 1 mientras el mapa esta forzado.
        pwrup = 0;
        io_read(8'h14);
        chk("POWTEST a 1 mientras arranca", dout[1] == 1'b1);
        chk("la ROM seguiria en PWAIT", dout[1] == 1'b1);
        chk("UST_A habilita salida", dout_oe == 1'b1);
        pwrup = 1;
        io_read(8'h14);
        chk("POWTEST a 0 con el mapa asentado", dout[1] == 1'b0);
        chk("UST_A asentado = FD", dout == 8'hFD);
        chk("MAINSP indica red presente", dout[2] == 1'b1);

        // --- bancos de UST_A, la regresion del arranque ---
        // La ROM escribe A2 en ENREG JUSTO ANTES del bucle PWAIT. A2 pone
        // los selectores a 10 y 10, o sea entrada de cinta y modelo, y el
        // bit de modelo vale siempre uno. Si la seleccion se quedara puesta,
        // PWAIT no saldria nunca: la maquina se queda sin imagen con la
        // interrupcion pedida y sin atender. La seleccion se consume al
        // leer, asi que la SEGUNDA lectura ya vuelve a dar POWTEST.
        io_write(8'h07, 8'hA2);
        io_read(8'h14);
        chk("primera lectura tras A2: banco de modelo", dout[1] == 1'b1);
        io_read(8'h14);
        chk("segunda lectura: otra vez POWTEST", dout[1] == 1'b0);
        chk("y la ROM sale de PWAIT", dout[1] == 1'b0);

        // Banco 10 en el bit 0: entrada de cinta, cero mientras se lee
        io_write(8'h07, 8'h82);
        cass_leyendo = 1;
        io_read(8'h14);
        chk("banco de cinta: 0 mientras lee", dout[0] == 1'b0);
        cass_leyendo = 0;
        io_write(8'h07, 8'h82);
        io_read(8'h14);
        chk("banco de cinta: 1 parada", dout[0] == 1'b1);
        io_read(8'h14);
        chk("y despues vuelve EXTEST", dout[0] == 1'b1);
        io_write(8'h07, 8'h00);

        // --- UST_B en 16 ---
        tape_in = 1; v24_rxd = 1; v24_cts_n = 0; prn_cts_n = 0;
        io_read(8'h16);
        chk("UST_B con TPIN y RDDK", dout == 8'h7D);
        tape_in = 0; v24_rxd = 0;

        // --- el COP se selecciona en 06 ---
        io_read(8'h06);
        chk("lectura del COP", dout == 8'hA5 && cop_rd == 1'b1);

        // --- interrupcion de reloj ---
        io_write(8'h07, 8'h00);           // bit 0 a 0 => reloj habilitado
        chk("sin INT antes del tick", int_n == 1'b1);
        @(negedge clk); clkint_tick = 1;
        @(negedge clk); clkint_tick = 0;
        #1;
        chk("INT tras el tick", int_n == 1'b0);
        io_read(8'h14);
        chk("_CLKINT a 0 en UST_A", dout[5] == 1'b0);
        io_write(8'h04, 8'h00);           // INTCON borra la interrupcion
        #1;
        chk("INT borrada por INTCON", int_n == 1'b1);

        // --- con el reloj deshabilitado no debe interrumpir ---
        io_write(8'h07, 8'h01);           // bit 0 a 1 => reloj deshabilitado
        @(negedge clk); clkint_tick = 1;
        @(negedge clk); clkint_tick = 0;
        #1;
        chk("sin INT con reloj deshabilitado", int_n == 1'b1);

        // ---------- puertos del modulo de expansion ----------
        // Sin expansion, el 15 es un alias del 14 y el 01 no existe
        eim = 0;
        io_read(8'h14);
        v14 = dout;
        io_read(8'h15);
        chk("sin expansion el 15 es alias del 14", dout == v14);
        io_write(8'h01, 8'h5A);
        chk("sin expansion el 01 no hace nada", enrg2 == 8'h00);

        eim = 1;
        io_write(8'h01, 8'h5A);
        chk("ENREG2 en el 01", enrg2 == 8'h5A);
        io_write(8'h03, 8'hC3);
        chk("salida paralela enclavada en el 03", prn_latch == 8'hC3);

        // Registro de estado 2: D2 video normal, D3 red, D4 40 columnas,
        // D6 se quiere pantalla
        cfg_rev_video = 0; cfg_40col = 1; cfg_tv = 1;
        io_read(8'h15);
        chk("estado 2: video normal", dout[2] == 1'b1);
        chk("estado 2: alimentacion de red", dout[3] == 1'b1);
        chk("estado 2: 40 columnas", dout[4] == 1'b1);
        chk("estado 2: se quiere pantalla", dout[6] == 1'b1);

        cfg_rev_video = 1; cfg_40col = 0; cfg_tv = 0;
        io_read(8'h15);
        chk("estado 2: video inverso", dout[2] == 1'b0);
        chk("estado 2: 80 columnas", dout[4] == 1'b0);
        chk("estado 2: sin pantalla", dout[6] == 1'b0);

        // el 14 sigue siendo UST_A aunque haya expansion
        io_read(8'h14);
        chk("el 14 sigue siendo UST_A", dout[1] == ~pwrup);
        eim = 0;

        if (errors == 0) $display("tb_newbrain_io: OK");
        else begin $display("tb_newbrain_io: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
