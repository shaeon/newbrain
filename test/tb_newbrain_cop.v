`timescale 1ns/1ps
//
// Reproduce las secuencias que ejecuta la rutina COPIS de la ROM (E225) y
// comprueba que el HLE responde como el COP real.
//
module tb_newbrain_cop;
    reg clk = 0, reset = 1;
    reg cs = 0, rd = 0, wr = 0;
    reg [7:0] din = 0;
    wire [7:0] dout;
    wire copint_n;
    reg [7:0] key_byte = 8'd46;   // 'a'
    reg key_avail = 0;
    wire key_taken;
    reg brk = 0;
    wire        cass_reproduce, cass_limpia, cass_pide, cass_salta, cass_cola;
    wire [15:0] cass_salta_n;
    wire        cass_graba_act, cass_graba_wr, cass_graba_listo;
    wire [7:0]  cass_dato, cass_graba;
    wire        cass_hay;
    wire [4:0] vfd_addr;
    wire [7:0] vfd_data;
    wire vfd_wr, vfd_valid;
    integer errors = 0;
    integer i;

    reg [7:0] vfd_shadow [0:17];
    integer   vfd_done = 0;

    always #5 clk = ~clk;

    // El REGINT salta cada 400 ciclos: deja hueco de sobra para que una
    // transaccion completa de 18 bytes quepa entre dos ticks.
    newbrain_cop_hle #(.CLK_HZ(20000), .REGINT_HZ(50)) dut (
        .clk(clk), .reset(reset),
        .solo_cinta(1'b0), .ocupado(),
        .cs(cs), .rd(rd), .wr(wr), .din(din), .dout(dout), .copint_n(copint_n),
        .key_byte(key_byte), .key_avail(key_avail), .key_taken(key_taken),
        .brk(brk),
        .cass_reproduce(cass_reproduce), .cass_limpia(cass_limpia),
        .cass_pide(cass_pide), .cass_salta(cass_salta),
        .cass_salta_n(cass_salta_n), .cass_cola(cass_cola),
        .cass_dato(cass_dato), .cass_hay(cass_hay),
        .cass_graba_act(cass_graba_act), .cass_graba(cass_graba),
        .cass_graba_wr(cass_graba_wr), .cass_graba_listo(cass_graba_listo),
        .vfd_addr(vfd_addr), .vfd_data(vfd_data),
        .vfd_wr(vfd_wr), .vfd_valid(vfd_valid)
    );

    //------------------------------------------------------------------
    // Cinta: modulo real con una imagen en un array que hace de SDRAM
    //------------------------------------------------------------------
    reg  [7:0]  img [0:255];
    reg  [23:0] img_tam = 24'd0;
    reg         rebobina = 1'b0;
    wire [23:0] sd_addr;
    wire        sd_rd;
    reg  [7:0]  sd_dout;
    reg         sd_ack = 1'b0, sd_busy = 1'b0;
    reg  [1:0]  sd_cnt;

    newbrain_tape #(.CLK_HZ(20000)) cinta (
        .clk(clk), .reset(reset), .fuente(1'b0), .rebobina(rebobina),
        .img_base(24'h600000), .img_tam(img_tam),
        .sd_addr(sd_addr), .sd_rd(sd_rd), .sd_dout(sd_dout), .sd_ack(sd_ack),
        .audio(1'b0), .umbral(8'd76),
        .pide(cass_pide), .limpia(cass_limpia),
        .salta(cass_salta), .salta_n(cass_salta_n), .cola_ini(cass_cola),
        .dato(cass_dato), .hay(cass_hay), .err_audio(),
        .graba(cass_graba_act), .graba_dato(cass_graba),
        .graba_wr(cass_graba_wr), .graba_listo(cass_graba_listo),
        .tape_out()
    );

    // Como el arbitro de newbrain.v: un dueño, que se suelta con el ack
    always @(posedge clk) begin
        sd_ack <= 1'b0;
        if (sd_busy) begin
            sd_cnt <= sd_cnt - 1'b1;
            if (sd_cnt == 2'd0) begin
                sd_dout <= img[sd_addr[7:0]];
                sd_ack  <= 1'b1;
                sd_busy <= 1'b0;
            end
        end else if (sd_rd && !sd_ack) begin
            sd_busy <= 1'b1;
            sd_cnt  <= 2'd3;
        end
    end

    // Lo que se graba
    reg [7:0] grab [0:63];
    integer   ngrab = 0;
    always @(posedge clk) if (cass_graba_wr) begin
        grab[ngrab] <= cass_graba;
        ngrab <= ngrab + 1;
    end

    reg key_taken_seen = 0;

    always @(posedge clk) begin
        if (vfd_wr)    vfd_shadow[vfd_addr] <= vfd_data;
        if (vfd_valid) vfd_done = vfd_done + 1;
        if (key_taken) key_taken_seen <= 1'b1;
    end

    task io_rd(output [7:0] v);
        begin
            @(negedge clk); cs = 1; rd = 1;
            @(negedge clk); @(negedge clk); v = dout;
            cs = 0; rd = 0;
            @(negedge clk);
        end
    endtask

    task io_wr(input [7:0] v);
        begin
            @(negedge clk); cs = 1; wr = 1; din = v;
            @(negedge clk); @(negedge clk);
            cs = 0; wr = 0;
            @(negedge clk);
        end
    endtask

    integer espera_max = 2000;
    task wait_int;
        integer n;
        begin
            n = 0;
            while (copint_n === 1'b1 && n < espera_max) begin
                @(negedge clk); n = n + 1;
            end
            if (copint_n !== 1'b0) begin
                $display("FAIL el COP nunca pidio interrupcion");
                errors = errors + 1;
            end
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

    reg [7:0] v;

    initial begin
        repeat (4) @(negedge clk);
        reset = 0;

        // ---------- REGINT sencillo ----------
        wait_int;
        io_rd(v);
        chk("vector de REGINT = 00", v == 8'h00);
        chk("_COPINT se suelta tras leer el vector", copint_n == 1'b1);
        io_wr(8'hD0);                       // NULLCOM
        repeat (4) @(negedge clk);
        chk("sin datos pendientes tras NULLCOM", copint_n == 1'b1);

        // ---------- REGINT con DISPCOM: 18 bytes al display ----------
        wait_int;
        io_rd(v);
        chk("segundo vector de REGINT", v == 8'h00);
        io_wr(8'hA0);                       // DISPCOM
        repeat (2) @(negedge clk);
        chk("_COPINT vuelve a bajar para que SYNDLP salga", copint_n == 1'b0);

        for (i = 0; i < 18; i = i + 1) io_wr(8'h41 + i[7:0]);
        repeat (4) @(negedge clk);

        chk("18 bytes recibidos", vfd_done == 1);
        chk("_COPINT liberado al terminar", copint_n == 1'b1);
        for (i = 0; i < 18; i = i + 1) begin
            if (vfd_shadow[i] !== 8'h41 + i[7:0]) begin
                $display("FAIL byte %0d del display: %02h (esperado %02h)",
                         i, vfd_shadow[i], 8'h41 + i[7:0]);
                errors = errors + 1;
            end
        end

        // ---------- TIMCOM: 6 bytes, sin tocar el display ----------
        wait_int;
        io_rd(v);
        io_wr(8'hB0);                       // TIMCOM
        repeat (2) @(negedge clk);
        chk("_COPINT baja tambien para TIMCOM", copint_n == 1'b0);
        for (i = 0; i < 6; i = i + 1) io_wr(8'hF0 + i[7:0]);
        repeat (4) @(negedge clk);
        chk("TIMCOM no repinta el display", vfd_done == 1);
        chk("_COPINT liberado tras TIMCOM", copint_n == 1'b1);

        // ---------- Teclado ----------
        key_avail = 1;
        wait_int;
        io_rd(v);
        chk("vector de teclado = 3X", v[7:4] == 4'h3);
        io_wr(8'h00);                       // reconocimiento
        io_rd(v);
        chk("primero el centinela, no la tecla", v == 8'h85);
        io_rd(v);
        chk("y en la segunda lectura la tecla", v == 8'd46);
        key_avail = 0;
        repeat (4) @(negedge clk);
        chk("la tecla se consume", key_taken_seen == 1'b1);
        io_rd(v);
        chk("sin tecla devuelve 80", v == 8'h80);

        // ---------- STOP se refleja en el vector ----------
        brk = 1;
        wait_int;
        io_rd(v);
        chk("bit de BRK en el vector", v[2] == 1'b1);
        io_wr(8'hD0);

        //==============================================================
        // CINTA
        //
        // Se imita el driver TPIO.S de la ROM: el comando va en el
        // reconocimiento (COPCTL) y cada TCHR consume una interrupcion.
        //==============================================================
        brk = 0;

        // Imagen: dos bloques en formato cdesp
        //   bloque 1: nombre vacio, tipo 81
        //   bloque 2: 3 bytes AA BB CC, tipo 41
        for (i = 0; i < 256; i = i + 1) img[i] = 8'h00;
        // 00 | 00 00 | 81 | BC 00 | 9x00           -> 15 bytes, 0..14
        img[3] = 8'h81; img[4] = 8'hBC; img[5] = 8'h00;
        // 00 | 03 00 | AA BB CC | 41 | chk | 9x00   -> 18 bytes, 15..32
        img[16] = 8'h03; img[18] = 8'hAA; img[19] = 8'hBB; img[20] = 8'hCC;
        img[21] = 8'h41;
        img[22] = 8'h03 + 8'hAA + 8'hBB + 8'hCC + 8'h41 + 8'h3B;
        img[23] = 8'h02;
        // bloque 3, igual que el 2 pero con DD EE FF, para los abortos
        img[34] = 8'h03; img[36] = 8'hDD; img[37] = 8'hEE; img[38] = 8'hFF;
        img[39] = 8'h42; img[40] = 8'h55; img[41] = 8'h66;
        // bloque 4
        img[52] = 8'h01; img[54] = 8'h77; img[55] = 8'h43; img[56] = 8'h11;
        img[57] = 8'h22;
        img_tam = 24'd67;
        rebobina = 1; repeat (3) @(negedge clk); rebobina = 0;

        chk("la cinta arranca parada", cass_reproduce == 1'b0);

        // ---- bloque 1 ----
        casson(8'h8C);
        tchr(8'h8C, v); chk("primero el sincronismo", v == 8'h00);
        tchr(8'h8C, v); chk("bloque 1: longitud baja", v == 8'h00);
        tchr(8'h8C, v); chk("bloque 1: longitud alta", v == 8'h00);
        tchr(8'h8C, v); chk("bloque 1: tipo 81", v == 8'h81);
        tchr(8'h8C, v); chk("bloque 1: suma baja", v == 8'hBC);
        tchr(8'h8C, v); chk("bloque 1: suma alta", v == 8'h00);
        repeat (4) @(negedge clk);
        chk("tras la suma se para", cass_reproduce == 1'b0);
        noerex;

        // ---- bloque 2 ----
        casson(8'h8C);
        tchr(8'h8C, v); chk("bloque 2: sincronismo (la cola se tiro)", v == 8'h00);
        tchr(8'h8C, v); chk("bloque 2: longitud 3", v == 8'h03);
        tchr(8'h8C, v);
        tchr(8'h8C, v); chk("bloque 2: AA", v == 8'hAA);
        tchr(8'h8C, v); chk("bloque 2: BB", v == 8'hBB);
        tchr(8'h8C, v); chk("bloque 2: CC", v == 8'hCC);
        tchr(8'h8C, v); chk("bloque 2: tipo 41", v == 8'h41);
        tchr(8'h8C, v);
        tchr(8'h8C, v);
        noerex;

        // ---- bloque 3, abandonado tras la longitud (ERROR 131) ----
        casson(8'h8C);
        tchr(8'h8C, v);
        tchr(8'h8C, v); chk("bloque 3: longitud 3", v == 8'h03);
        tchr(8'h8C, v);
        // ERREX2 -> NOEREX: el primer reconocimiento D0 llega con un CASSIN
        // que trae DD, y los dos siguientes tienen que ser REGINT
        noerex;

        // ---- bloque 4 tiene que llegar entero ----
        casson(8'h8C);
        tchr(8'h8C, v); chk("bloque 4: sincronismo tras el aborto", v == 8'h00);
        tchr(8'h8C, v); chk("bloque 4: longitud 1", v == 8'h01);
        tchr(8'h8C, v);
        tchr(8'h8C, v); chk("bloque 4: dato 77", v == 8'h77);
        tchr(8'h8C, v); chk("bloque 4: tipo 43", v == 8'h43);
        tchr(8'h8C, v); chk("bloque 4: suma baja", v == 8'h11);
        // error de suma: se abandona sin leer la alta, que ya viene en
        // la interrupcion del D0
        noerex;

        // ---- sin cinta: LOAD espera; STOP lo saca ----
        casson(8'h8C);
        repeat (1500) @(negedge clk);
        chk("sin cinta no hay interrupciones", copint_n == 1'b1);
        brk = 1;
        wait_int; io_rd(v); io_wr(8'h8C);
        chk("STOP en cinta da vector 2X de estado", v[7:4] == 4'h2 && v[1:0] == 2'b11);
        brk = 0;
        repeat (4) @(negedge clk);
        chk("y termina la reproduccion", cass_reproduce == 1'b0);
        noerex;

        // ---- rebobinar y leer otra vez el bloque 1 ----
        rebobina = 1; repeat (3) @(negedge clk); rebobina = 0;
        casson(8'h8C);
        tchr(8'h8C, v);
        tchr(8'h8C, v);
        tchr(8'h8C, v);
        tchr(8'h8C, v); chk("rebobinado: tipo 81", v == 8'h81);
        tchr(8'h8C, v);
        tchr(8'h8C, v);
        noerex;

        // ---- grabacion ----
        ngrab = 0;
        espera_max = 4_000_000;     // el modulador va a su ritmo real
        casson(8'h88);
        tchr_w(8'h88, 8'h02);
        tchr_w(8'h88, 8'h00);
        tchr_w(8'h88, 8'h5A);
        tchr_w(8'h88, 8'hA5);
        // NOEREX: el primer D0 viaja en un CASSOUT; su dato no se graba
        noerex_w;
        repeat (4) @(negedge clk);
        chk("grabacion: sincronismo + 4 bytes", ngrab == 5);
        chk("grabacion: primero el 00", grab[0] == 8'h00);
        chk("grabacion: luego los datos", grab[1] == 8'h02 && grab[2] == 8'h00
                                         && grab[3] == 8'h5A && grab[4] == 8'hA5);
        chk("grabacion terminada", cass_graba_act == 1'b0);

        if (errors == 0) $display("tb_newbrain_cop: OK");
        else begin $display("tb_newbrain_cop: %0d FALLOS", errors); $fatal; end
        $finish;
    end

    //------------------------------------------------------------------
    // Modelo del lado Z80 del driver de cinta
    //------------------------------------------------------------------
    reg [7:0] cop_vec;

    // Una interrupcion completa, como COPIS: vector, reconocimiento y la
    // rama que toque. dato_w es lo que hay en COPBUF por si es CASSOUT.
    task copis(input [7:0] ack, input [7:0] dato_w, output [7:0] vec, output [7:0] dato);
        begin
            wait_int;
            io_rd(vec);
            io_wr(ack);
            dato = 8'hXX;
            if (vec[7:4] == 4'h2 && !vec[0]) io_rd(dato);
            else if (vec[7:4] == 4'h4)       io_wr(dato_w);
        end
    endtask

    // CASSON: WTRDY (READY ya puesto), COPCTL = cmd, WTRDY -> una
    // interrupcion que lleva cmd en el reconocimiento y que tiene que ser
    // un REGINT. Queda COPCTL = cmd.
    task casson(input [7:0] cmd);
        reg [7:0] vv, dd;
        begin
            copis(cmd, 8'h00, vv, dd);
            if (vv[7:4] != 4'h0) begin
                $display("FAIL CASSON: la interrupcion del comando es %02h, no REGINT", vv);
                errors = errors + 1;
            end
        end
    endtask

    // TCHR de lectura: una interrupcion, que tiene que ser CASSIN con dato
    task tchr(input [7:0] ack, output [7:0] dato);
        reg [7:0] vv;
        begin
            copis(ack, 8'h00, vv, dato);
            if (vv[7:4] != 4'h2 || vv[0]) begin
                $display("FAIL TCHR: vector %02h en vez de CASSIN", vv);
                errors = errors + 1;
            end
        end
    endtask

    task tchr_w(input [7:0] ack, input [7:0] dato);
        reg [7:0] vv, dd;
        begin
            copis(ack, dato, vv, dd);
            if (vv[7:4] != 4'h4) begin
                $display("FAIL TCHR de grabacion: vector %02h en vez de CASSOUT", vv);
                errors = errors + 1;
            end
        end
    endtask

    // NOEREX: COPCTL = NULLCOM y tres WTRDY. La primera puede ser todavia
    // un CASSIN (el D0 aun no ha llegado), las otras dos tienen que ser
    // REGINT: si no, la ROM se quedaria sin salir.
    task noerex;
        reg [7:0] vv, dd;
        begin
            copis(8'hD0, 8'h00, vv, dd);
            copis(8'hD0, 8'h00, vv, dd);
            if (vv[7:4] != 4'h0) begin
                $display("FAIL NOEREX: segunda interrupcion %02h, no REGINT", vv);
                errors = errors + 1;
            end
            copis(8'hD0, 8'h00, vv, dd);
            if (vv[7:4] != 4'h0) begin
                $display("FAIL NOEREX: tercera interrupcion %02h, no REGINT", vv);
                errors = errors + 1;
            end
        end
    endtask

    task noerex_w;
        reg [7:0] vv, dd;
        begin
            copis(8'hD0, 8'hEE, vv, dd);
            copis(8'hD0, 8'hEE, vv, dd);
            if (vv[7:4] != 4'h0) begin
                $display("FAIL NOEREX de grabacion: %02h, no REGINT", vv);
                errors = errors + 1;
            end
            copis(8'hD0, 8'hEE, vv, dd);
        end
    endtask
endmodule
