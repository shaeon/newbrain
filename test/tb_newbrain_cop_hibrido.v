`timescale 1ns/1ps
//
// El COP de verdad y el modulo de cinta emulado compartiendo el puerto, con
// el mismo reparto que la maquina (newbrain_cop_mux):
//
//   1. arranque: el COP de verdad interrumpe y el Z80 le contesta como la
//      ROM (DISPCOM con sus 18 bytes, luego NULLCOM);
//   2. LOAD: el Z80 contesta 8C (CASSCOM) a una interrupcion del COP de
//      verdad; el modulo de cinta se queda el puerto y entrega los bytes de
//      un .bas de verdad; al COP de verdad le llega D0;
//   3. el Z80 cierra con D0 y el puerto vuelve al COP de verdad, que sigue
//      interrumpiendo cada 20 ms.
//
module tb_newbrain_cop_hibrido;
    reg clk = 0, reset = 1;
    always #62.5 clk = ~clk;                          // 8 MHz

    // ---- COP de verdad ----
    reg  [9:0] rw_a = 0; reg [7:0] rw_d = 0; reg rw_en = 0;
    reg        cs = 0, rd = 0, wr = 0;
    reg  [7:0] din = 8'hFF;
    wire [7:0] dout, real_dout, real_din, hle_dout;
    wire       copint_n, real_int, hle_int, real_cs, ocupado;

    newbrain_cop_real #(.CLK_HZ(8_000_000)) cop (
        .clk(clk), .reset(reset),
        .rom_wr_addr(rw_a), .rom_wr_data(rw_d), .rom_wr_en(rw_en),
        .cs(real_cs), .rd(rd), .wr(wr), .din(real_din),
        .dout(real_dout), .copint_n(real_int),
        .kbd_row(), .kbd_col(4'b0000), .vfd_sr(), .vfd_latch(),
        .tape_in(1'b0), .tape_out(), .motor());

    // ---- modulo de cinta emulado + fichero ----
    wire [7:0]  c_dato; wire c_hay, c_repr, c_limpia, c_pide, c_salta, c_cola;
    wire [15:0] c_salta_n; wire c_graba_act, c_graba_wr, c_graba_listo;
    wire [7:0]  c_graba;
    newbrain_cop_hle #(.CLK_HZ(8_000_000)) hle (
        .clk(clk), .reset(reset), .solo_cinta(1'b1), .ocupado(ocupado),
        .cs(cs), .rd(rd), .wr(wr), .din(din),
        .dout(hle_dout), .copint_n(hle_int),
        .cass_reproduce(c_repr), .cass_limpia(c_limpia), .cass_pide(c_pide),
        .cass_salta(c_salta), .cass_salta_n(c_salta_n), .cass_cola(c_cola),
        .cass_dato(c_dato), .cass_hay(c_hay),
        .cass_graba_act(c_graba_act), .cass_graba(c_graba),
        .cass_graba_wr(c_graba_wr), .cass_graba_listo(c_graba_listo),
        .key_byte(8'h00), .key_avail(1'b0), .key_taken(), .brk(1'b0),
        .vfd_addr(), .vfd_data(), .vfd_wr(), .vfd_valid());

    reg  [7:0]  fichero [0:4095];
    integer     tam = 0;
    wire [23:0] sd_addr; wire sd_rd;
    reg  [7:0]  sd_dout = 0; reg sd_ack = 0;
    always @(posedge clk) begin
        sd_ack <= 1'b0;
        if (sd_rd && !sd_ack) begin
            sd_dout <= fichero[sd_addr - 24'h600000];
            sd_ack  <= 1'b1;
        end
    end
    newbrain_tape #(.CLK_HZ(8_000_000)) cinta (
        .clk(clk), .reset(reset), .fuente(1'b0), .rebobina(reset),
        .img_base(24'h600000), .img_tam(tam[23:0]),
        .sd_addr(sd_addr), .sd_rd(sd_rd), .sd_dout(sd_dout), .sd_ack(sd_ack),
        .audio(1'b0), .umbral(8'd82),
        .pide(c_pide), .limpia(c_limpia), .salta(c_salta), .salta_n(c_salta_n),
        .cola_ini(c_cola), .dato(c_dato), .hay(c_hay), .err_audio(),
        .graba(c_graba_act), .graba_dato(c_graba), .graba_wr(c_graba_wr),
        .graba_listo(c_graba_listo), .tape_out());

    newbrain_cop_mux reparto (
        .cs(cs), .din(din), .dout(dout), .copint_n(copint_n),
        .real_cs(real_cs), .real_din(real_din),
        .real_dout(real_dout), .real_copint_n(real_int),
        .cinta_ocupada(ocupado), .cinta_dout(hle_dout), .cinta_copint_n(hle_int));

    integer errors = 0;
    task chk(input [255:0] n, input c);
        begin if (!c) begin $display("FALLO: %0s", n); errors = errors + 1; end end
    endtask
    task lee(output [7:0] v);
        begin
            @(negedge clk); cs = 1; rd = 1; repeat (4) @(negedge clk);
            v = dout; cs = 0; rd = 0; repeat (4) @(negedge clk);
        end
    endtask
    task escribe(input [7:0] v);
        begin
            @(negedge clk); din = v; cs = 1; wr = 1; repeat (4) @(negedge clk);
            cs = 0; wr = 0; din = 8'hFF; repeat (4) @(negedge clk);
        end
    endtask

    // ---- el Z80 ----
    // fase 0: arranque   fase 1: cargando   fase 2: cierre   fase 3: despues
    integer    fase = 0, n_disp = 0, nrec = 0, k, n_desp = 0;
    reg        datos_disp = 0, activo = 0;
    reg [7:0]  vec, v;
    reg [7:0]  recibido [0:4095];
    time       t_ant = 0, periodo = 0;
    always begin
        wait (activo && copint_n == 1'b0);
        repeat (200) @(negedge clk);
        if (datos_disp) begin
            for (k = 0; k < 18; k = k + 1) begin escribe(8'h20); repeat (192) @(negedge clk); end
            datos_disp = 0; n_disp = n_disp + 1;
        end else begin
            lee(vec);
            case (fase)
            0: if (n_disp < 2) begin escribe(8'hA0); datos_disp = 1; end
               else escribe(8'hD0);
            1: begin
                   escribe(8'h8C);
                   if (vec[7:4] == 4'h2 && !vec[0]) begin
                       repeat (240) @(negedge clk);
                       lee(v);
                       recibido[nrec] = v;
                       nrec = nrec + 1;
                   end
               end
            2: begin escribe(8'hD0); fase = 3; end
            default: begin
                escribe(8'hD0);
                if (vec[7:4] == 4'h0) begin
                    if (t_ant != 0) periodo = $time - t_ant;
                    t_ant = $time;
                    n_desp = n_desp + 1;
                end
            end
            endcase
        end
        wait (copint_n == 1'b1 || !activo);
    end

    // seguimiento
    always #20_000_000 if (fase == 1) $display("    %0d ms: %0d bytes, ocupado=%b vec=%02h copint=%b", $time/1_000_000, nrec, ocupado, vec, copint_n);

    reg [7:0] rom [0:1023];
    integer i, bien, desde;
    initial begin
        $readmemh("cop420.hex", rom);
        $readmemh("prueba_bas.hex", fichero);
        tam = 0; while (tam < 4096 && fichero[tam] !== 8'hxx) tam = tam + 1;
        @(negedge clk);
        for (i = 0; i < 1024; i = i + 1) begin
            rw_a = i; rw_d = rom[i]; rw_en = 1; @(negedge clk);
        end
        rw_en = 0; repeat (4) @(negedge clk); reset = 0; activo = 1;

        #100_000_000;                                  // arranque
        chk("antes de la cinta, el puerto es del COP de verdad", !ocupado);
        fase = 1;                                      // LOAD
        wait (ocupado);
        $display("  el modulo de cinta se queda el puerto a los %0d ms", $time/1_000_000);
        wait (nrec >= 45 || $time > 400_000_000);
        fase = 2;                                      // el Z80 cierra
        wait (fase == 3);
        #1_000_000;
        chk("tras cerrar, el puerto vuelve al COP de verdad", !ocupado);
        #100_000_000;
        $display("  recibidos %0d bytes de %0d; despues, %0d REGINT del COP de verdad, cada %0d us",
                 nrec, tam, n_desp, periodo / 1000);
        // los bytes llegan en orden y enteros (el primero del fichero es el
        // sincronismo, que la ROM tira)
        desde = (recibido[0] == fichero[0]) ? 0 : 1;
        bien = 0;
        for (i = 0; i < 40 && i < nrec; i = i + 1) if (recibido[i] === fichero[i + desde]) bien = bien + 1;
        $write("  primeros:"); for (i = 0; i < 12; i = i + 1) $write(" %02h", recibido[i]); $display("");
        chk("los bytes del fichero, en orden", nrec >= 40 && bien == 40);
        chk("el COP de verdad sigue interrumpiendo", n_desp >= 3);
        chk("y cada 20 ms", periodo > 19_000_000 && periodo < 21_000_000);
        if (errors == 0) $display("tb_newbrain_cop_hibrido: OK");
        else             $display("tb_newbrain_cop_hibrido: %0d FALLOS", errors);
        $finish;
    end
endmodule
