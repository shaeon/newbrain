`timescale 1ns/1ps
//
// Verifica la codificacion de teclas contra KTABLE, la tabla de 64 bytes
// que la ROM AB tiene en A1A7. Cada caso comprueba que la tecla PS/2 produce
// el indice cuyo caracter en esa tabla es el esperado.
//
module tb_newbrain_kbd;
    reg clk = 0, reset = 1;
    reg [10:0] ps2_key = 0;
    wire [7:0] key_byte;
    wire       key_avail, brk;
    reg        key_taken = 0;
    integer    errors = 0;
    reg        strobe = 0;
    reg  [3:0] scan_row = 4'd0;
    wire [3:0] scan_col;

    always #5 clk = ~clk;

    // Reloj de mentira de 100 kHz para que los 60 ms de pulsacion minima
    // sean 6000 ciclos y la prueba no tarde
    newbrain_kbd #(.CLK_HZ(100_000)) dut (
        .clk(clk), .reset(reset), .ps2_key(ps2_key),
        .key_byte(key_byte), .key_avail(key_avail), .key_taken(key_taken),
        .brk(brk), .scan_row(scan_row), .scan_col(scan_col)
    );

    task press(input ext, input [7:0] code);
        begin
            strobe = ~strobe;
            @(negedge clk); ps2_key = {strobe, 1'b1, ext, code};
            @(negedge clk); @(negedge clk);
        end
    endtask

    task release_key(input ext, input [7:0] code);
        begin
            strobe = ~strobe;
            @(negedge clk); ps2_key = {strobe, 1'b0, ext, code};
            @(negedge clk); @(negedge clk);
        end
    endtask

    task take;
        begin
            @(negedge clk); key_taken = 1;
            @(negedge clk); key_taken = 0;
            @(negedge clk);
        end
    endtask

    task chk_key(input [255:0] name, input ext, input [7:0] code,
                 input [7:0] expected);
        begin
            press(ext, code);
            if (key_byte !== expected || key_avail !== 1'b1) begin
                $display("FAIL %0s: byte=%02h avail=%b (esperado %02h)",
                         name, key_byte, key_avail, expected);
                errors = errors + 1;
            end
            take;
            release_key(ext, code);
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        reset = 0;
        @(negedge clk);

        // KTABLE[46] = 'a'
        chk_key("A -> 46", 1'b0, 8'h1C, 8'd46);
        // KTABLE[14] = 'q'
        chk_key("Q -> 14", 1'b0, 8'h15, 8'd14);
        // KTABLE[15] = ' '
        chk_key("espacio -> 15", 1'b0, 8'h29, 8'd15);
        // KTABLE[30] = 0D, NEW LINE
        chk_key("Intro -> 30", 1'b0, 8'h5A, 8'd30);
        // KTABLE[24] = '*', la tecla que la ROM comprueba con CP 18H
        chk_key("comilla -> 24 (*)", 1'b0, 8'h52, 8'd24);
        // KTABLE[3] = '7'
        chk_key("7 -> 3", 1'b0, 8'h3D, 8'd3);
        // KTABLE[2] = 08, flecha izquierda
        chk_key("izquierda -> 2", 1'b1, 8'h6B, 8'd2);
        // KTABLE[17] = 00, STOP
        chk_key("Esc -> 17 (STOP)", 1'b0, 8'h76, 8'd17);

        // --- modificadores ---
        press(1'b0, 8'h12);              // Shift
        if (key_avail !== 1'b0) begin
            $display("FAIL un modificador no debe generar pulsacion");
            errors = errors + 1;
        end
        press(1'b0, 8'h1C);              // Shift + A
        if (key_byte !== {2'b01, 6'd46}) begin
            $display("FAIL Shift+A: byte=%02h (esperado %02h)",
                     key_byte, {2'b01, 6'd46});
            errors = errors + 1;
        end
        take;
        release_key(1'b0, 8'h1C);
        release_key(1'b0, 8'h12);

        press(1'b0, 8'h14);              // Ctrl
        press(1'b0, 8'h1C);
        if (key_byte !== {2'b10, 6'd46}) begin
            $display("FAIL Ctrl+A: byte=%02h (esperado %02h)",
                     key_byte, {2'b10, 6'd46});
            errors = errors + 1;
        end
        take;
        release_key(1'b0, 8'h1C);
        release_key(1'b0, 8'h14);

        press(1'b0, 8'h11);              // Alt = GRAPHICS
        press(1'b0, 8'h1C);
        if (key_byte !== {2'b11, 6'd46}) begin
            $display("FAIL Graphics+A: byte=%02h (esperado %02h)",
                     key_byte, {2'b11, 6'd46});
            errors = errors + 1;
        end
        take;
        release_key(1'b0, 8'h1C);
        release_key(1'b0, 8'h11);

        // --- STOP ---
        press(1'b0, 8'h76);
        if (brk !== 1'b1) begin
            $display("FAIL Esc deberia activar brk");
            errors = errors + 1;
        end
        take;
        release_key(1'b0, 8'h76);
        // la suelta de una pulsacion corta se aplaza hasta los 60 ms
        if (brk !== 1'b1) begin
            $display("FAIL una pulsacion corta deberia durar al menos 60 ms");
            errors = errors + 1;
        end
        repeat (6100) @(negedge clk);
        if (brk !== 1'b0) begin
            $display("FAIL brk deberia soltarse");
            errors = errors + 1;
        end

        // La matriz cruda, que es lo que recorre el COP420 real
        press(1'b0, 8'h1C);          // 'A' esta en fila 13 bit 0
        scan_row = 4'd13; #1;
        if (scan_col[0] !== 1'b1) begin
            $display("FAIL la matriz no expone la A en la fila 13");
            errors = errors + 1;
        end
        scan_row = 4'd12; #1;
        if (scan_col !== 4'b0000) begin
            $display("FAIL la fila 12 deberia estar vacia");
            errors = errors + 1;
        end
        take; release_key(1'b0, 8'h1C);
        repeat (6100) @(negedge clk);    // pasada la pulsacion minima
        scan_row = 4'd13; #1;
        if (scan_col[0] !== 1'b0) begin
            $display("FAIL la matriz no se suelta");
            errors = errors + 1;
        end

        // Escribiendo rapido: tres pulsaciones seguidas antes de que el COP
        // recoja ninguna. Tienen que salir las tres y en orden.
        press(1'b0, 8'h1C);  release_key(1'b0, 8'h1C);    // a
        press(1'b0, 8'h32);  release_key(1'b0, 8'h32);    // b
        press(1'b0, 8'h21);  release_key(1'b0, 8'h21);    // c
        begin : rapido
            reg [7:0] k1, k2, k3;
            k1 = key_byte; take;
            k2 = key_byte; take;
            k3 = key_byte; take;
            if (k1 == k2 || k2 == k3 || k1 == k3 || key_avail !== 1'b0) begin
                $display("FAIL escribiendo rapido: %02h %02h %02h avail=%b", k1, k2, k3, key_avail);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("tb_newbrain_kbd: OK");
        else begin $display("tb_newbrain_kbd: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
