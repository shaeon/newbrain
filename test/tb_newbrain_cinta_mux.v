`timescale 1ns/1ps
//
// El reparto del puerto del COP (newbrain_cop_mux) entre el COP de verdad y
// el modulo de cinta emulado (newbrain_cop_hle en modo solo cinta).
//
// El COP de verdad es aqui uno de mentira que pide REGINT cada tanto y
// apunta lo que le escriben. El Z80 hace lo que la ROM para cargar: contesta
// a un REGINT del COP de verdad con CASSCOM (8C) y luego lee un byte por
// cada vector CASSIN. Tiene que pasar esto:
//   * el CASSCOM se lo queda el modulo de cinta, y al COP de verdad le llega
//     un NULLCOM (D0) en su lugar;
//   * los bytes del fichero llegan al Z80;
//   * al acabar, el puerto vuelve al COP de verdad.
//
module tb_newbrain_cinta_mux;
    reg clk = 0, reset = 1;
    always #5 clk = ~clk;
    reg cs = 0, rd = 0, wr = 0;
    reg [7:0] din = 0;
    wire [7:0] dout;
    wire copint_n;
    integer errors = 0, i;
    integer espera_max = 200000;

    task chk(input [255:0] nombre, input cond);
        begin if (!cond) begin $display("FAIL %0s", nombre); errors = errors + 1; end end
    endtask

    // ---- cinta: modulo real y una imagen que hace de SDRAM ----
    wire        cass_reproduce, cass_limpia, cass_pide, cass_salta, cass_cola;
    wire [15:0] cass_salta_n;
    wire        cass_graba_act, cass_graba_wr, cass_graba_listo;
    wire [7:0]  cass_dato, cass_graba;
    wire        cass_hay;
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
    always @(posedge clk) begin
        sd_ack <= 1'b0;
        if (sd_busy) begin
            sd_cnt <= sd_cnt - 1'b1;
            if (sd_cnt == 2'd0) begin sd_dout <= img[sd_addr[7:0]]; sd_ack <= 1'b1; sd_busy <= 1'b0; end
        end else if (sd_rd && !sd_ack) begin sd_busy <= 1'b1; sd_cnt <= 2'd3; end
    end

    // ---- el modulo de cinta, en modo solo cinta como en newbrain.v ----
    wire [7:0] cinta_dout;
    wire       cinta_copint_n, cinta_ocupada;
    newbrain_cop_hle #(.CLK_HZ(20000), .REGINT_HZ(50)) modulo (
        .clk(clk), .reset(reset),
        .solo_cinta(1'b1), .ocupado(cinta_ocupada),
        .cs(cs), .rd(rd), .wr(wr), .din(din),
        .dout(cinta_dout), .copint_n(cinta_copint_n),
        .key_byte(8'h00), .key_avail(1'b0), .key_taken(), .brk(1'b0),
        .cass_reproduce(cass_reproduce), .cass_limpia(cass_limpia),
        .cass_pide(cass_pide), .cass_salta(cass_salta), .cass_salta_n(cass_salta_n),
        .cass_cola(cass_cola), .cass_dato(cass_dato), .cass_hay(cass_hay),
        .cass_graba_act(cass_graba_act), .cass_graba(cass_graba),
        .cass_graba_wr(cass_graba_wr), .cass_graba_listo(cass_graba_listo),
        .vfd_addr(), .vfd_data(), .vfd_wr(), .vfd_valid()
    );

    // ---- el COP de verdad, de mentira: REGINT periodico ----
    wire       real_cs;
    wire [7:0] real_din;
    reg        real_copint_n = 1'b1;
    reg [7:0]  real_log [0:63];
    integer    real_n = 0, real_leidas = 0, tic = 0;
    reg        rw_d = 0, rr_d = 0;
    always @(posedge clk) begin
        tic <= tic + 1;
        if (tic % 3000 == 0 && real_copint_n) real_copint_n <= 1'b0;
        rw_d <= real_cs & wr;
        rr_d <= real_cs & rd;
        if ((real_cs & wr) && !rw_d) begin          // escritura: baja la peticion
            real_copint_n <= 1'b1;
            if (real_n < 64) real_log[real_n] <= real_din;
            real_n <= real_n + 1;
        end
        if ((real_cs & rd) && !rr_d) real_leidas <= real_leidas + 1;
    end

    newbrain_cop_mux reparto (
        .cs(cs), .din(din), .dout(dout), .copint_n(copint_n),
        .real_cs(real_cs), .real_din(real_din),
        .real_dout(8'h00), .real_copint_n(real_copint_n),
        .cinta_ocupada(cinta_ocupada), .cinta_dout(cinta_dout),
        .cinta_copint_n(cinta_copint_n)
    );

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

    reg [7:0] v, vv, dd;
    integer antes;
    initial begin
        for (i = 0; i < 256; i = i + 1) img[i] = 8'h00;
        img[3] = 8'h81; img[4] = 8'hBC; img[5] = 8'h00;     // bloque 1: nombre vacio
        img_tam = 24'd15;
        repeat (4) @(negedge clk); reset = 0;
        rebobina = 1; repeat (3) @(negedge clk); rebobina = 0;

        // Un REGINT normal: lo atiende el COP de verdad
        copis(8'hD0, 8'h00, vv, dd);
        chk("REGINT del COP de verdad", vv == 8'h00 && !cinta_ocupada);
        chk("el NULLCOM le llega al COP de verdad", real_n == 1 && real_log[0] == 8'hD0);

        // LOAD: el reconocimiento lleva CASSCOM
        antes = real_n;
        casson(8'h8C);
        chk("el modulo de cinta se queda el puerto", cinta_ocupada);
        chk("al COP de verdad le llega D0 y no el CASSCOM",
            real_n == antes + 1 && real_log[antes] == 8'hD0);

        tchr(8'h8C, v); chk("sincronismo 00", v == 8'h00);
        tchr(8'h8C, v); chk("longitud baja 00", v == 8'h00);
        tchr(8'h8C, v); chk("longitud alta 00", v == 8'h00);
        tchr(8'h8C, v); chk("tipo 81", v == 8'h81);
        tchr(8'h8C, v); chk("suma baja BC", v == 8'hBC);
        tchr(8'h8C, v); chk("suma alta 00", v == 8'h00);

        // Fin: la ROM para el motor con un reconocimiento sin CASSCOM
        copis(8'hD0, 8'h00, vv, dd);
        repeat (2000) @(negedge clk);
        chk("al acabar, el puerto vuelve al COP de verdad", !cinta_ocupada);
        antes = real_n;
        copis(8'hD0, 8'h00, vv, dd);
        chk("y el siguiente REGINT es suyo", real_n == antes + 1 && vv == 8'h00);

        if (errors == 0) $display("tb_newbrain_cinta_mux: OK");
        else             $display("tb_newbrain_cinta_mux: %0d FALLOS", errors);
        $finish;
    end
endmodule
