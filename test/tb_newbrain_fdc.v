`timescale 1ns/1ps
//
// Cableado de la controladora de disco de verdad (newbrain_fdc.v).
//
// El Z80 de la controladora es un guion de ciclos de bus (t80pa_guion.v) y
// el 765 un sustituto (u765_stub.v). Lo que se comprueba es exactamente lo
// que la cosimulacion en Python (tools/nbfdc.py) da por supuesto al correr
// la d417 de verdad: la ROM, la ventana al NewBrain con PA15, los puertos
// con la mascara 71h y el registro de control del lado del NewBrain.
//
module tb_newbrain_fdc;
    reg clk = 0, reset = 1;
    always #15.625 clk = ~clk;          // 32 MHz

    reg  [15:0] io_addr = 0;
    reg  [7:0]  io_data = 0;
    reg         io_wr = 0;
    reg  [9:0]  ram_addr = 0;
    reg  [7:0]  ram_din = 0;
    reg         ram_we = 0;
    wire [7:0]  ram_dout;
    reg         rom_wr = 0;
    reg  [10:0] rom_addr = 0;
    reg  [7:0]  rom_data = 0;
    wire        activa;

    newbrain_fdc dut (
        .clk(clk), .reset(reset), .enable(1'b1),
        .io_addr(io_addr), .io_data(io_data), .io_wr(io_wr),
        .ram_addr(ram_addr), .ram_din(ram_din), .ram_we(ram_we), .ram_dout(ram_dout),
        .rom_wr(rom_wr), .rom_addr(rom_addr), .rom_data(rom_data),
        .sd_lba(), .sd_rd(), .sd_wr(), .sd_ack(1'b0),
        .sd_buff_addr(9'd0), .sd_buff_dout(8'd0), .sd_buff_wr(1'b0), .sd_buff_din(),
        .img_mounted(2'b00), .img_size(32'd0),
        .activa(activa),
        .win_req(win_req), .win_addr(win_addr), .win_a16(win_a16), .win_wr(win_wr),
        .win_din(win_din), .win_dout(win_dout), .win_done(win_done)
    );

    // ---- la memoria paginada del NewBrain, de mentira: contesta a la
    // ventana con unos ciclos de retardo, como la SDRAM ----
    wire        win_req, win_a16, win_wr;
    wire [15:0] win_addr;
    wire [7:0]  win_din;
    reg  [7:0]  win_dout = 8'h00;
    reg         win_done = 1'b0;
    reg  [7:0]  host [0:65535];
    reg  [2:0]  wcnt = 0;
    integer     win_accesos = 0;
    reg         a16_visto = 1'bx;
    always @(posedge clk) begin
        win_done <= 1'b0;
        if (win_req && !win_done) begin
            if (wcnt == 3'd5) begin
                if (win_wr) host[win_addr] <= win_din;
                else        win_dout <= host[win_addr];
                win_done <= 1'b1; wcnt <= 0;
                win_accesos <= win_accesos + 1;
                a16_visto <= win_a16;
            end else wcnt <= wcnt + 1'b1;
        end else wcnt <= 0;
    end

    integer errors = 0;
    task chk(input [255:0] nombre, input cond);
        begin
            if (!cond) begin
                $display("FALLO: %0s", nombre);
                errors = errors + 1;
            end
        end
    endtask

    task carga_rom(input [10:0] a, input [7:0] d);
        begin
            @(posedge clk); rom_addr <= a; rom_data <= d; rom_wr <= 1;
            @(posedge clk); rom_wr <= 0;
        end
    endtask

    task poke(input [15:0] a, input [7:0] d);    // lado del NewBrain
        begin
            @(posedge clk); ram_addr <= a - 16'h9C00; ram_din <= d; ram_we <= 1;
            repeat (12) @(posedge clk);          // un ciclo de bus entero
            ram_we <= 0;
        end
    endtask

    task peek(input [15:0] a, output [7:0] d);
        begin
            @(posedge clk); ram_addr <= a - 16'h9C00;
            @(posedge clk); @(posedge clk);
            d = ram_dout;
        end
    endtask

    task control(input [7:0] b, input [7:0] v);  // OUT (C),A con C = FF
        begin
            @(posedge clk); io_addr <= {b, 8'hFF}; io_data <= v; io_wr <= 1;
            repeat (4) @(posedge clk); io_wr <= 0;
            @(posedge clk);
        end
    endtask

    // guion del Z80 de la controladora
    integer n = 0;
    task paso(input [2:0] op, input [15:0] a, input [7:0] d);
        begin
            dut.fcpu.op[n] = op; dut.fcpu.dir[n] = a; dut.fcpu.dat[n] = d;
            n = n + 1;
        end
    endtask
    function [7:0] res(input integer i); res = dut.fcpu.leido[i]; endfunction

    reg [7:0] v;
    integer i_rom0, i_rom7ff, i_rom800, i_rom1234, i_st1, i_comp, i_fuera,
            i_765a, i_765b, i_765c, i_st2, i_st3,
            i_pag0, i_pag1, i_pag2, i_pag3, i_pag4;

    initial begin
        // ---- guion de la controladora, escrito antes de soltarla ----
        paso(1, 16'h0000, 0); paso(1, 16'h0001, 0);   // margen para que el
        paso(1, 16'h0000, 0); paso(1, 16'h0001, 0);   // NewBrain ponga ATT
        i_rom0 = n;    paso(1, 16'h0000, 0);
        i_rom7ff = n;  paso(1, 16'h07FF, 0);
        i_rom800 = n;  paso(1, 16'h0800, 0);      // fuera de los 2K: FF
        i_rom1234 = n; paso(1, 16'h1234, 0);
        i_st1 = n;     paso(3, 16'h0040, 0);      // estado: ATT
        paso(4, 16'h0020, 8'h21);                 // motor + PA15
        paso(2, 16'h9FDC, 8'hFF);                 // CRESULT = FF por la ventana
        i_comp = n;    paso(1, 16'h9C00, 0);      // lee lo del NewBrain
        paso(4, 16'h0020, 8'h01);                 // PA15 = 0
        i_fuera = n;   paso(1, 16'h9C00, 0);      // ahora es 1C00 del NewBrain
        i_765a = n;    paso(3, 16'h0001, 0);      // 765, datos
        i_765b = n;    paso(3, 16'h0011, 0);      // espejo con A4
        i_765c = n;    paso(3, 16'h0000, 0);      // 765, estado
        i_st2 = n;     paso(3, 16'h0041, 0);      // espejo del 40
        paso(4, 16'h0001, 8'h07);                 // un byte al 765
        i_st3 = n;     paso(3, 16'h0040, 0);      // con INT
        // ---- con el modulo de expansion: PAGING a uno, la ventana sale
        //      a la memoria paginada del NewBrain ----
        i_pag0 = n;    paso(4, 16'h0020, 8'h01);  // PA15 = 0 (aqui llega A9)
        i_pag1 = n;    paso(1, 16'h8079, 0);      // puntero: 0079 del NewBrain
        paso(4, 16'h0020, 8'h21);                 // PA15 = 1
        paso(2, 16'hFFCD, 8'h5C);                 // bloque en FFCD del NewBrain
        i_pag2 = n;    paso(1, 16'hFFCD, 0);
        i_pag3 = n;    paso(3, 16'h0040, 0);      // estado: PAGING a uno
        i_pag4 = n;    paso(1, 16'h9C00, 0);      // ya no es la RAM compartida
        paso(0, 0, 0);

        // ---- lo que prepara el NewBrain, con la maquina en reset ----
        repeat (4) @(posedge clk);
        carga_rom(11'h000, 8'hAA);
        carga_rom(11'h001, 8'hBB);
        carga_rom(11'h7FF, 8'h77);
        poke(16'h9C00, 8'hCD);           // puntero al bloque, byte bajo
        reset <= 0;

        // otro dispositivo en el puerto FF (B = 01): no debe tocar nada
        control(8'h01, 8'hA0);
        chk("B=01 no es la controladora", dut.ctl == 8'h20);
        // ATT con A9
        control(8'h02, 8'hA0);
        chk("control: ATT y _RESET", dut.ctl == 8'hA0);

        host[16'h0079] = 8'hCD; host[16'h007A] = 8'hFF;   // puntero a FFCD
        host[16'h9C00] = 8'h33;                            // lo que hay en 9C00 paginado

        // la INT del 765 se levanta a mitad del guion, y A9 (PAGING) antes
        // de la parte paginada
        fork
            begin
                wait (dut.fcpu.pc == i_st3);
                dut.fdc765.int_o = 1'b1;
            end
            begin
                wait (dut.fcpu.pc == i_pag0);
                control(8'h02, 8'hA9);
            end
            wait (dut.fcpu.fin);
        join

        chk("ventana paginada: puntero por 8079 con PA15 = 0", res(i_pag1) == 8'hCD);
        chk("ventana paginada: escritura en FFCD llega al NewBrain", host[16'hFFCD] == 8'h5C);
        chk("ventana paginada: lectura de FFCD", res(i_pag2) == 8'h5C);
        chk("puerto 40: ATT, PAGING e INT", res(i_pag3) == 8'hE0);
        chk("con PAGING 9C00 va por la ventana", res(i_pag4) == 8'h33);
        chk("cuatro accesos por la ventana", win_accesos == 4);
        chk("MA16 a cero con A9", a16_visto == 1'b0);

        chk("ROM 0000", res(i_rom0) == 8'hAA);
        chk("ROM 07FF", res(i_rom7ff) == 8'h77);
        chk("ROM 0800 lee FF", res(i_rom800) == 8'hFF);
        chk("ROM 1234 lee FF", res(i_rom1234) == 8'hFF);
        chk("puerto 40: ATT", res(i_st1) == 8'h80);
        chk("PA15 = 1 lee la RAM compartida", res(i_comp) == 8'hCD);
        chk("PA15 = 0 no es la RAM compartida", res(i_fuera) == 8'hFF);
        chk("765 datos", res(i_765a) == 8'h5A);
        chk("765 datos en el espejo 11h", res(i_765b) == 8'h5A);
        chk("765 estado", res(i_765c) == 8'h80);
        chk("puerto 41 es el 40", res(i_st2) == 8'h80);
        chk("puerto 40: INT del 765", res(i_st3) == 8'hA0);
        chk("tres lecturas al 765", dut.fdc765.lecturas == 3);
        chk("una escritura al 765", dut.fdc765.escrituras == 1 && dut.fdc765.ultimo == 8'h07);
        chk("motor en marcha", activa == 1'b1);

        // lo que escribio la controladora lo ve el NewBrain
        peek(16'h9FDC, v);
        chk("CRESULT = FF visto por el NewBrain", v == 8'hFF);

        // _FDC RESET a cero para la controladora
        control(8'h02, 8'h00);
        repeat (4) @(posedge clk);
        chk("_FDC RESET = 0 la para", dut.fcpu.RESET_n == 1'b0 && activa == 1'b0);
        control(8'h02, 8'h20);
        repeat (4) @(posedge clk);
        chk("_FDC RESET = 1 la suelta", dut.fcpu.RESET_n == 1'b1);

        if (errors == 0) $display("tb_newbrain_fdc: OK");
        else             $display("tb_newbrain_fdc: %0d FALLOS", errors);
        $finish;
    end
endmodule
