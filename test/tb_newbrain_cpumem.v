`timescale 1ns/1ps
//
// Camino de memoria de la CPU contra la SDRAM, con ciclos de bus reales.
//
// Es la pieza que nunca se habia probado: el stub del T80 que usan lint e
// integracion no genera ciclos, asi que el enganche de parada -- pedir a la
// SDRAM, retener los clock enables y soltar al llegar el dato -- nunca se
// habia ejercitado. Aqui se lee la ROM byte a byte y se comprueba que la CPU
// recibe exactamente lo que hay en memoria.
//
module tb_newbrain_cpumem;
    reg clk = 0, ce_pix = 0;
    reg reset = 1, mem_reset = 1;
    reg [23:0] dl_addr = 0;
    reg [7:0]  dl_data = 0;
    reg        dl_wr = 0;
    wire       sdram_free;

    wire [12:0] A;
    wire [15:0] DQ;
    wire DQML, DQMH, nWE, nCAS, nRAS, nCS, CKE;
    wire [1:0] BA;

    integer errors = 0, i;
    reg [7:0] leido [0:15];
    reg       visto [0:15];
    integer   k;
    initial for (k = 0; k < 16; k = k + 1) visto[k] = 1'b0;

    // Registra cada lectura con la direccion que la origino
    always @(posedge clk) if (dut.cpu.rd_done) begin
        // Se toma el registro interno, no el bus: en el ciclo de rd_done la
        // CPU ya ha soltado MREQ y el bus vuelve a bus abierto.
        leido[dut.cpu.A[3:0]] <= dut.cpu.data;
        visto[dut.cpu.A[3:0]] <= 1'b1;
    end

    always #5 clk = ~clk;
    always @(posedge clk) ce_pix <= ~ce_pix;

    newbrain #(.CLK_HZ(1_280_000)) dut (
        .clk_sys(clk), .reset(reset), .mem_reset(mem_reset),
        .fast_boot(1'b1), .disc_rom(1'b0),
        .coprom_wr_addr(10'd0), .coprom_wr_data(8'd0), .coprom_wr_en(1'b0), .cass_fuente(1'b0), .cass_rebobina(1'b0),
        .cass_umbral(8'd32), .cass_tam(24'd0),
        .h_off(8'sd0), .v_off(8'sd0), .eim(1'b0), .ram_size(2'd0),
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
        .tape_in(1'b0), .v24_rxd(1'b0), .v24_cts_n(1'b0), .prn_cts_n(1'b0),
        .dbg_pc(), .dbg_pwrup(), .dbg_m1_n(),
        .dbg_tv_enable(), .dbg_tv_load(), .dbg_sdram_ready(), .dbg_int_req(), .dbg_int_ack(), .dbg_tape()
    );

    sdram_model model (
        .clk(clk), .A(A), .DQ(DQ), .DQML(DQML), .DQMH(DQMH),
        .nWE(nWE), .nCAS(nCAS), .nRAS(nRAS), .nCS(nCS), .BA(BA), .CKE(CKE)
    );

    reg [7:0] v;
    task ventana(input wr, input [15:0] a, input [7:0] d, output [7:0] r);
        integer t;
        begin
            @(negedge clk);
            force dut.win_req  = 1'b1;
            force dut.win_addr = a;
            force dut.win_a16  = 1'b0;
            force dut.win_wr   = wr;
            force dut.win_din  = d;
            t = 0;
            while (dut.win_done !== 1'b1 && t < 2000) begin @(negedge clk); t = t + 1; end
            r = dut.win_dout;
            if (t >= 2000) begin $display("FAIL ventana: sin respuesta para %04h", a); errors = errors + 1; end
            release dut.win_req; release dut.win_addr; release dut.win_a16;
            release dut.win_wr;  release dut.win_din;
            repeat (4) @(negedge clk);
        end
    endtask

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

    // La CPU de prueba lee desde E000, o sea el banco 2 de la ROM, que vive
    // en 004000 de la SDRAM. Patron reconocible.
    initial begin
        repeat (4) @(negedge clk);
        mem_reset = 0;
        repeat (400) @(negedge clk);

        for (i = 0; i < 16; i = i + 1)
            load_byte(24'h004000 + i[23:0], 8'hA0 + i[7:0]);

        repeat (20) @(negedge clk);
        reset = 0;                       // arranca la CPU de prueba

        // Espera a que PWRUP suba y se hagan unas cuantas lecturas
        while (dut.powerup.pwrup !== 1'b1) @(negedge clk);
        repeat (2000) @(negedge clk);

        for (i = 0; i < 16; i = i + 1) begin
            if (visto[i] !== 1'b1) begin
                $display("FAIL nunca se leyo la direccion E00%0h", i[3:0]);
                errors = errors + 1;
            end else if (leido[i] !== 8'hA0 + i[7:0]) begin
                $display("FAIL E00%0h devolvio %02h, esperado %02h",
                         i[3:0], leido[i], 8'hA0 + i[7:0]);
                errors = errors + 1;
            end
        end

        if (dut.cpu.count < 16'd16) begin
            $display("FAIL la CPU apenas avanza: %0d ciclos completados",
                     dut.cpu.count);
            errors = errors + 1;
        end

        // ---- la ventana de la controladora, por el arbitro y la SDRAM ----
        // (se fuerzan sus señales; la controladora esta apagada en este banco)
        ventana(1'b0, 16'hE005, 8'h00, v);
        if (v !== 8'hA5) begin $display("FAIL ventana: ROM E005 dio %02h", v); errors = errors + 1; end
        ventana(1'b1, 16'h1234, 8'h77, v);
        ventana(1'b0, 16'h1234, 8'h00, v);
        if (v !== 8'h77) begin $display("FAIL ventana: RAM 1234 dio %02h tras escribir 77", v); errors = errors + 1; end
        ventana(1'b0, 16'h8123, 8'h00, v);
        if (v !== 8'hFF) begin $display("FAIL ventana: 8000 sin nada debe leer FF (%02h)", v); errors = errors + 1; end

        if (errors == 0)
            $display("tb_newbrain_cpumem: OK (%0d ciclos, ultimo dato %02h)",
                     dut.cpu.count, dut.cpu.data);
        else begin
            $display("tb_newbrain_cpumem: %0d FALLOS", errors);
            $fatal;
        end
        $finish;
    end
endmodule
