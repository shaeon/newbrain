`timescale 1ns/1ps
//
// Carga desde SD, extremo a extremo: data_io escribe MIENTRAS la maquina esta
// en reset, y los bytes tienen que acabar en la SDRAM igualmente.
//
// Esta prueba existe porque no estaba: el reset de la maquina incluye
// ioctl_download, y al principio ese mismo reset llegaba al controlador de
// SDRAM y al camino de carga. Resultado: la ROM no llegaba nunca a memoria y
// la pantalla salia negra sin ninguna pista de por que.
//
module tb_newbrain_load;
    reg clk = 0, ce_pix = 0;
    reg reset = 1;          // la maquina, en reset durante toda la carga
    reg mem_reset = 1;      // la memoria, solo al arrancar
    reg [23:0] dl_addr = 0;
    reg [7:0]  dl_data = 0;
    reg        dl_wr = 0;
    wire       sdram_free;

    wire [12:0] A;
    wire [15:0] DQ;
    wire DQML, DQMH, nWE, nCAS, nRAS, nCS, CKE;
    wire [1:0] BA;

    integer errors = 0, i;
    reg  tape_in = 1'b0;
    wire dbg_tape;

    always #5 clk = ~clk;
    always @(posedge clk) ce_pix <= ~ce_pix;

    newbrain #(.CLK_HZ(1_280_000)) dut (
        .clk_sys(clk), .reset(reset), .mem_reset(mem_reset),
        .fast_boot(1'b1), .disc_rom(1'b0),
        .coprom_wr_addr(10'd0), .coprom_wr_data(8'd0), .coprom_wr_en(1'b0), .cass_fuente(1'b0), .cass_rebobina(1'b0),
        .cass_umbral(8'd32), .cass_tam(24'd0), .h_off(8'sd0), .v_off(8'sd0), .eim(1'b0), .ram_size(2'd0),
        .dl_addr(dl_addr), .dl_data(dl_data), .dl_wr(dl_wr),
        .sdram_free(sdram_free),
        .cg_wr_addr(12'd0), .cg_wr_data(8'd0), .cg_wr_en(1'b0),
        .SDRAM_A(A), .SDRAM_DQ(DQ), .SDRAM_DQML(DQML), .SDRAM_DQMH(DQMH),
        .SDRAM_nWE(nWE), .SDRAM_nCAS(nCAS), .SDRAM_nRAS(nRAS), .SDRAM_nCS(nCS),
        .SDRAM_BA(BA), .SDRAM_CKE(CKE),
        .clk_pix(clk), .ce_pix(ce_pix), .ancho(1'b0),
        .vid_r(), .vid_g(), .vid_b(),
        .vid_hs(), .vid_vs(), .vid_hb(), .vid_vb(),
        .ps2_key(11'd0),
        .vfd_addr(), .vfd_data(), .vfd_wr(), .vfd_valid(),
        .tape_in(tape_in), .v24_rxd(1'b0), .v24_cts_n(1'b0), .prn_cts_n(1'b0),
        .dbg_pc(), .dbg_pwrup(), .dbg_m1_n(),
        .dbg_tv_enable(), .dbg_tv_load(), .dbg_sdram_ready(), .dbg_int_req(), .dbg_int_ack(), .dbg_tape(dbg_tape)
    );

    sdram_model model (
        .clk(clk), .A(A), .DQ(DQ), .DQML(DQML), .DQMH(DQMH),
        .nWE(nWE), .nCAS(nCAS), .nRAS(nRAS), .nCS(nCS), .BA(BA), .CKE(CKE)
    );

    // data_io solo dispara ioctl_wr cuando el controlador esta libre
    task load_byte(input [23:0] a, input [7:0] d);
        integer n;
        begin
            n = 0;
            while (!sdram_free && n < 2000) begin @(negedge clk); n = n + 1; end
            @(negedge clk); dl_addr = a; dl_data = d; dl_wr = 1;
            @(negedge clk); dl_wr = 0;
            repeat (12) @(negedge clk);
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        mem_reset = 0;                  // la memoria arranca
        repeat (400) @(negedge clk);    // secuencia de inicializacion

        // La maquina sigue en reset, como durante una carga real
        for (i = 0; i < 8; i = i + 1)
            load_byte(i[23:0], 8'hC0 + i[7:0]);

        repeat (50) @(negedge clk);

        for (i = 0; i < 8; i = i + 1) begin
            if (model.mem[i/2][(i%2)*8 +: 8] !== 8'hC0 + i[7:0]) begin
                $display("FAIL byte %0d no llego a la SDRAM: %02h (esperado %02h)",
                         i, model.mem[i/2][(i%2)*8 +: 8], 8'hC0 + i[7:0]);
                errors = errors + 1;
            end
        end

        // ---------- entrada de cinta ----------
        // Pasa por dos biestables de sincronizacion, asi que llega con un par
        // de ciclos de retraso pero tiene que llegar.
        tape_in = 1'b1;
        repeat (4) @(negedge clk);
        if (dbg_tape !== 1'b1) begin
            $display("FAIL la entrada de cinta no llega a la maquina");
            errors = errors + 1;
        end
        tape_in = 1'b0;
        repeat (4) @(negedge clk);
        if (dbg_tape !== 1'b0) begin
            $display("FAIL la entrada de cinta no vuelve a cero");
            errors = errors + 1;
        end

        if (errors == 0) $display("tb_newbrain_load: OK");
        else begin $display("tb_newbrain_load: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
