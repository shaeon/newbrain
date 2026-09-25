`timescale 1ns/1ps
//
// COP420 real (t400 + la ROM cop420-guw.ic419) contra un NewBrain de
// mentira que atiende sus interrupciones como la rutina COPIS de la ROM del
// sistema (OS.S2):
//
//   al bajar _COPINT:  lee el vector, escribe el reconocimiento (NULLCOM)
//   si es de teclado:  escribe 80h, lee hasta que deja de ser 80h y lee la
//                      tecla
//
// Se comprueba lo que hace falta para que la maquina arranque y teclee:
//   * el COP interrumpe periodicamente (REGINT);
//   * el contador de filas del teclado recorre las 16 filas;
//   * con una tecla pulsada llega un vector de teclado con su codigo.
//
module tb_newbrain_cop_real;
    reg clk = 0, reset = 1;
    always #62.5 clk = ~clk;                  // 8 MHz: CK del COP a 4 MHz

    reg  [9:0] rom_wr_addr = 0;
    reg  [7:0] rom_wr_data = 0;
    reg        rom_wr_en = 0;
    reg        cs = 0, rd = 0, wr = 0;
    reg  [7:0] din = 8'hFF;
    wire [7:0] dout;
    wire       copint_n;
    wire [3:0] kbd_row;
    wire [3:0] kbd_col;
    wire [15:0] vfd_sr;
    wire       vfd_latch, tape_out;
    wire [1:0] motor;

    // teclado: una tecla en (fila_t, col_t) mientras `pulsada`
    reg        pulsada = 0;
    reg [3:0]  fila_t = 0;
    reg [1:0]  col_t = 0;
    assign kbd_col = (pulsada && kbd_row == fila_t) ? (4'b0001 << col_t) : 4'b0000;

    newbrain_cop_real #(.CLK_HZ(8_000_000)) dut (
        .clk(clk), .reset(reset),
        .rom_wr_addr(rom_wr_addr), .rom_wr_data(rom_wr_data), .rom_wr_en(rom_wr_en),
        .cs(cs), .rd(rd), .wr(wr), .din(din), .dout(dout), .copint_n(copint_n),
        .kbd_row(kbd_row), .kbd_col(kbd_col),
        .vfd_sr(vfd_sr), .vfd_latch(vfd_latch),
        .tape_in(1'b0), .tape_out(tape_out), .motor(motor)
    );

    integer errors = 0, i;
    task chk(input [255:0] n, input c);
        begin if (!c) begin $display("FALLO: %0s", n); errors = errors + 1; end end
    endtask

    // ---- ciclos de bus del Z80 al puerto 06 (unos 500 ns) ----
    task lee(output [7:0] v);
        begin
            @(negedge clk); cs = 1; rd = 1;
            repeat (4) @(negedge clk);
            v = dout;
            cs = 0; rd = 0;
            repeat (4) @(negedge clk);
        end
    endtask
    task escribe(input [7:0] v);
        begin
            @(negedge clk); din = v; cs = 1; wr = 1;
            repeat (4) @(negedge clk);
            cs = 0; wr = 0; din = 8'hFF;
            repeat (4) @(negedge clk);
        end
    endtask

    // ---- el NewBrain: atiende las interrupciones del COP ----
    //
    // Como la ROM de verdad (medido con tools/nbcopreal.py, las dos ROMs
    // originales frente a frente):
    //   * a la interrupcion: lee el vector ~25 us despues y escribe el
    //     reconocimiento;
    //   * durante el arranque el reconocimiento es DISPCOM (A0) y los 18
    //     bytes del display NO van detras: esperan a la SIGUIENTE
    //     interrupcion, y entonces se escriben seguidos, uno cada 25 us, sin
    //     leer vector (cada escritura baja G0).
    integer n_int = 0, n_regint = 0, n_kbd = 0, n_otros = 0, n_disp = 0;
    reg [7:0] vec, ultima_tecla, v;
    reg       activo = 0;
    reg       datos_disp = 0;
    time      t_ant = 0, periodo_min = 1_000_000_000, periodo_max = 0;
    integer   espera, k;
    always begin
        wait (activo && copint_n == 1'b0);
        repeat (200) @(negedge clk);          // ~25 us de latencia
        if (datos_disp) begin
            for (k = 0; k < 18; k = k + 1) begin
                escribe(k == 1 ? 8'h00 : 8'h20);
                repeat (192) @(negedge clk);  // un byte cada 25 us
            end
            datos_disp = 0;
            n_disp = n_disp + 1;
        end else begin
            lee(vec);
            n_int = n_int + 1;
            case (vec[7:4])
            4'h0: begin
                n_regint = n_regint + 1;

                if (n_disp < 3 && !datos_disp) begin
                    escribe(8'hA0);           // DISPCOM
                    datos_disp = 1;
                end else
                    escribe(8'hD0);           // NULLCOM
            end
            4'h3: begin
                escribe(8'hD0);
                escribe(8'h80);
                espera = 0;
                lee(v);
                while (v == 8'h80 && espera < 2000) begin
                    lee(v);
                    espera = espera + 1;
                end
                lee(ultima_tecla);
                n_kbd = n_kbd + 1;
                $display("  tecla: vector %02X codigo %02X", vec, ultima_tecla);
            end
            default: begin
                escribe(8'hD0);
                n_otros = n_otros + 1;
                $display("  interrupcion %0d: vector %02X", n_int, vec);
            end
            endcase
        end
        wait (copint_n == 1'b1 || !activo);
    end

    // periodo entre interrupciones, cualesquiera, a partir de los 30 ms
    always @(negedge copint_n) if ($time > 30_000_000) begin
        if (t_ant != 0 && !pulsada) begin
            periodo_min = ($time - t_ant < periodo_min) ? $time - t_ant : periodo_min;
            periodo_max = ($time - t_ant > periodo_max) ? $time - t_ant : periodo_max;
        end
        t_ant = $time;
    end

    reg [15:0] filas_vistas = 0;
    always @(posedge clk) if (!reset) filas_vistas[kbd_row] <= 1'b1;

    reg [7:0] rom [0:1023];
    initial begin
        $readmemh("cop420.hex", rom);
        @(negedge clk);
        for (i = 0; i < 1024; i = i + 1) begin
            rom_wr_addr = i[9:0]; rom_wr_data = rom[i]; rom_wr_en = 1'b1;
            @(negedge clk);
        end
        rom_wr_en = 0;
        repeat (4) @(negedge clk);
        reset = 0;
        activo = 1;

        // 120 ms sin tocar nada
        #120_000_000;
        $display("  sin teclas: %0d interrupciones (%0d REGINT, %0d otras), filas %04X",
                 n_int, n_regint, n_otros, filas_vistas);
        chk("el COP interrumpe", n_int > 0);
        chk("interrupciones periodicas (REGINT)", n_regint >= 3);
        $display("  periodo entre REGINT: %0d a %0d us", periodo_min/1000, periodo_max/1000);
        // 50 por segundo, como dice The NewBrain Dissected (el COP va a 2,565 MHz)
        chk("una interrupcion cada 20 ms", periodo_min > 19_000_000 && periodo_max < 21_000_000);
        chk("el contador de filas recorre las 16", filas_vistas == 16'hFFFF);
        chk("sin teclas no hay vectores de teclado", n_kbd == 0);

        // 'A': fila 13, columna 0 de la matriz
        fila_t = 4'd13; col_t = 2'd0; pulsada = 1;
        #60_000_000;
        pulsada = 0;
        #60_000_000;
        chk("con 'A' pulsada llega un vector de teclado", n_kbd >= 1);
        chk("y es la 'a' de KTABLE (2E)", ultima_tecla == 8'h2E);

        if (errors == 0) $display("tb_newbrain_cop_real: OK (%0d interrupciones, tecla %02X)", n_int, ultima_tecla);
        else             $display("tb_newbrain_cop_real: %0d FALLOS", errors);
        $finish;
    end
endmodule
