`timescale 1ns/1ps
//
// Pantalla LCD por I2C: se decodifica el bus como lo haria el PCF8574 y un
// HD44780 de mentira interpreta lo que le llega (8 bits hasta el paso a 4
// bits, despues por parejas de nibbles, y el dato se coge en la bajada de
// E). Al final su memoria tiene que tener las dos lineas.
//
module tb_newbrain_lcd_i2c;
    reg clk = 0, reset = 1;
    always #125 clk = ~clk;                   // 4 MHz para que vaya rapido
    wire scl, sda;
    reg [127:0] l1 = "NEWBRAIN BASIC  ";
    reg [127:0] l2 = "Cinta     Disco ";
    newbrain_lcd_i2c #(.CLK_HZ(4_000_000)) dut (
        .clk(clk), .reset(reset), .direccion(7'h27),
        .linea1(l1), .linea2(l2), .scl(scl), .sda(sda));

    // ---- el PCF8574: recoge bytes entre START y STOP ----
    integer nbit = 0, nbyte = 0, errores_dir = 0, trans = 0;
    reg [7:0] sr;
    reg       dentro = 0;
    reg [7:0] pcf = 8'h00;                    // sus salidas P7..P0
    always @(negedge sda) if (scl) begin dentro = 1; nbit = 0; nbyte = 0; trans = trans + 1; end
    always @(posedge sda) if (scl) dentro = 0;
    always @(posedge scl) if (dentro) begin
        if (nbit < 8) sr = {sr[6:0], sda};
        nbit = nbit + 1;
        if (nbit == 9) begin                  // tras el ACK
            if (nbyte == 0) begin
                if (sr != {7'h27, 1'b0}) errores_dir = errores_dir + 1;
            end else
                pcf = sr;
            nbyte = nbyte + 1;
            nbit = 0;
        end
    end

    // ---- el HD44780 ----
    reg        cuatro = 0, alto = 1;
    reg [3:0]  nib_alto;
    reg [6:0]  ddaddr = 0;
    reg [7:0]  ddram [0:127];
    integer    n_ordenes = 0, i;
    reg        en_ant = 0;
    task orden(input rs, input [7:0] b);
        begin
            if (rs) begin ddram[ddaddr] = b; ddaddr = ddaddr + 1; end
            else if (b[7]) ddaddr = b[6:0];
            else if (b == 8'h01) begin for (i = 0; i < 128; i = i + 1) ddram[i] = 8'h20; ddaddr = 0; end
            n_ordenes = n_ordenes + 1;
        end
    endtask
    always @(pcf) begin
        if (en_ant && !pcf[2]) begin          // bajada de E
            if (!cuatro) begin
                if (pcf[7:4] == 4'h2) cuatro = 1;   // paso a 4 bits
            end else if (alto) begin
                nib_alto = pcf[7:4]; alto = 0;
            end else begin
                orden(pcf[0], {nib_alto, pcf[7:4]}); alto = 1;
            end
        end
        en_ant = pcf[2];
    end

    function [127:0] linea(input integer base);
        integer k;
        begin for (k = 0; k < 16; k = k + 1) linea[127 - 8*k -: 8] = ddram[base + k]; end
    endfunction

    integer errors = 0;
    initial begin
        for (i = 0; i < 128; i = i + 1) ddram[i] = 8'h00;
        repeat (4) @(posedge clk); reset = 0;
        #120_000_000;                         // 120 ms: arranque y un par de vueltas
        $display("  linea 1: \"%s\"   linea 2: \"%s\"", linea(0), linea(8'h40));
        if (errores_dir != 0) begin $display("FAIL direccion I2C"); errors = errors + 1; end
        if (linea(0) !== l1) begin $display("FAIL linea 1"); errors = errors + 1; end
        if (linea(8'h40) !== l2) begin $display("FAIL linea 2"); errors = errors + 1; end
        if (!pcf[3]) begin $display("FAIL retroiluminacion apagada"); errors = errors + 1; end
        // cambia el texto y se tiene que ver en la siguiente vuelta
        l1 = "READY           ";
        #40_000_000;
        if (linea(0) !== l1) begin $display("FAIL la linea 1 no se refresca: \"%s\"", linea(0)); errors = errors + 1; end
        if (errors == 0) $display("tb_newbrain_lcd_i2c: OK (%0d transacciones, %0d ordenes)", trans, n_ordenes);
        else             $display("tb_newbrain_lcd_i2c: %0d FALLOS", errors);
        $finish;
    end
endmodule
