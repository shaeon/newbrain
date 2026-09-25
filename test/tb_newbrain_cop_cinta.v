`timescale 1ns/1ps
//
// Carga de cinta con el COP420 REAL: la ROM del COP en el t400, la senal
// de cinta de un .bas (formato de beepgenerator) entrando por tape_in solo
// mientras el COP tiene un motor en marcha, y un Z80 de mentira que pide la
// carga como la ROM del sistema (CASSCOM 8C como reconocimiento) y lee un
// byte por cada vector CASSIN. Tienen que salir los bytes del fichero.
//
module tb_newbrain_cop_cinta;
    parameter integer COP_HZ = 4_000_000;
    parameter integer INVIERTE = 0;
    reg clk = 0, reset = 1;
    always #62.5 clk = ~clk;                  // 8 MHz

    reg  [9:0] rom_wr_addr = 0; reg [7:0] rom_wr_data = 0; reg rom_wr_en = 0;
    reg        cs = 0, rd = 0, wr = 0;
    reg  [7:0] din = 8'hFF;
    wire [7:0] dout;
    wire       copint_n;
    wire [3:0] kbd_row;
    wire [15:0] vfd_sr; wire vfd_latch, tape_out;
    wire [1:0] motor;
    reg        cinta = 0;
    wire       tape_in = cinta ^ INVIERTE[0];

    newbrain_cop_real #(.CLK_HZ(8_000_000), .COP_HZ(COP_HZ)) dut (
        .clk(clk), .reset(reset),
        .rom_wr_addr(rom_wr_addr), .rom_wr_data(rom_wr_data), .rom_wr_en(rom_wr_en),
        .cs(cs), .rd(rd), .wr(wr), .din(din), .dout(dout), .copint_n(copint_n),
        .kbd_row(kbd_row), .kbd_col(4'b0000),
        .vfd_sr(vfd_sr), .vfd_latch(vfd_latch),
        .tape_in(tape_in), .tape_out(tape_out), .motor(motor)
    );

    // ---- magnetofono: avanza solo con un motor en marcha (activos a 0) ----
    reg [23:0] semis [0:16383];
    integer nsemi = 0, isemi = 0;
    real    resto_ns = 0;
    wire    en_marcha = (motor != 2'b11);
    always @(posedge clk) if (en_marcha && isemi < nsemi) begin
        resto_ns = resto_ns - 125.0;
        if (resto_ns <= 0) begin
            cinta <= ~cinta;
            isemi = isemi + 1;
            resto_ns = resto_ns + semis[isemi] * 1000.0;
        end
    end

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

    // ---- el NewBrain ----
    reg        cargando = 0, activo = 0, datos_disp = 0;
    reg [7:0]  vec, v;
    reg [7:0]  recibido [0:255];
    integer    nrec = 0, n_disp = 0, k, n_err = 0;
    always begin
        wait (activo && copint_n == 1'b0);
        repeat (200) @(negedge clk);
        if (datos_disp) begin
            for (k = 0; k < 18; k = k + 1) begin escribe(8'h20); repeat (192) @(negedge clk); end
            datos_disp = 0; n_disp = n_disp + 1;
        end else begin
            lee(vec);
            if (!cargando) begin
                if (n_disp < 2) begin escribe(8'hA0); datos_disp = 1; end
                else escribe(8'hD0);
            end else begin
                escribe(8'h8C);                      // CASSCOM + reproducir + motor
                if (vec[7:4] == 4'h2 && !vec[0]) begin
                    repeat (240) @(negedge clk);     // ~30 us, como la rutina CASSIN
                    lee(v);
                    if (nrec < 256) recibido[nrec] = v;
                    nrec = nrec + 1;
                end else if (vec[7:4] == 4'h1) n_err = n_err + 1;
            end
        end
        wait (copint_n == 1'b1 || !activo);
    end

    reg [7:0] rom [0:1023];
    reg [7:0] esperado [0:127];
    integer i, bien;
    initial begin
        $readmemh("cop420.hex", rom);
        $readmemh("cinta_semis.hex", semis);
        nsemi = 0; while (nsemi < 16384 && semis[nsemi] !== 24'hxxxxxx) nsemi = nsemi + 1;
        resto_ns = semis[0] * 1000.0;
        $readmemh("prueba_bas.hex", esperado);
        @(negedge clk);
        for (i = 0; i < 1024; i = i + 1) begin
            rom_wr_addr = i; rom_wr_data = rom[i]; rom_wr_en = 1; @(negedge clk);
        end
        rom_wr_en = 0; repeat (4) @(negedge clk); reset = 0; activo = 1;
        #80_000_000;
        cargando = 1;                                // LOAD
        #9_000_000_000;
        $display("  COP a %0d Hz: cinta %0d de %0d semiperiodos, %0d bytes recibidos, %0d errores de cinta",
                 COP_HZ, isemi, nsemi, nrec, n_err);
        $write("  recibido:");
        for (i = 0; i < nrec && i < 24; i = i + 1) $write(" %02h", recibido[i]);
        $display("");
        bien = 0;
        for (i = 0; i < 20 && i < nrec; i = i + 1) if (recibido[i] === esperado[i]) bien = bien + 1;
        if (nrec >= 20 && bien == 20) $display("tb_newbrain_cop_cinta: OK");
        else                         $display("tb_newbrain_cop_cinta: FALLO (%0d de 20 bytes bien)", bien);
        $finish;
    end
endmodule
