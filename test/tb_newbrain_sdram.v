`timescale 1ns/1ps
//
// Controlador de SDRAM: secuencia de arranque, escritura y lectura de bytes
// sueltos (incluida la seleccion de byte alto y bajo) y cadencia de refresco.
//
module tb_newbrain_sdram;
    reg clk = 0, reset = 1;
    reg [23:0] addr = 0;      // puerto B, la CPU
    reg [7:0]  din = 0;
    reg rd = 0, wr = 0;
    wire [7:0] dout;
    wire ack, idle;

    // puerto A, el del video: se lleva palabras de 16 bits
    reg [23:0]  a_addr = 0;
    reg         a_rd = 0;
    wire [15:0] a_dout;
    wire        a_ack;

    wire [12:0] A;
    wire [15:0] DQ;
    wire DQML, DQMH, nWE, nCAS, nRAS, nCS, CKE;
    wire [1:0] BA;

    integer errors = 0;
    integer i;

    always #5 clk = ~clk;   // 100 MHz de simulacion, escala irrelevante

    // CLK_HZ pequeno para que el arranque de 100 us y el refresco sean cortos
    newbrain_sdram #(.CLK_HZ(1_280_000)) dut (
        .clk(clk), .reset(reset),
        .SDRAM_A(A), .SDRAM_DQ(DQ), .SDRAM_DQML(DQML), .SDRAM_DQMH(DQMH),
        .SDRAM_nWE(nWE), .SDRAM_nCAS(nCAS), .SDRAM_nRAS(nRAS), .SDRAM_nCS(nCS),
        .SDRAM_BA(BA), .SDRAM_CKE(CKE),
        .a_addr(a_addr), .a_rd(a_rd), .a_dout(a_dout), .a_ack(a_ack),
        .b_addr(addr), .b_din(din), .b_rd(rd), .b_wr(wr),
        .b_dout(dout), .b_ack(ack), .b_free(idle)
    );

    sdram_model model (
        .clk(clk), .A(A), .DQ(DQ), .DQML(DQML), .DQMH(DQMH),
        .nWE(nWE), .nCAS(nCAS), .nRAS(nRAS), .nCS(nCS), .BA(BA), .CKE(CKE)
    );

    task wait_idle;
        integer n;
        begin
            n = 0;
            while (!idle && n < 500) begin @(negedge clk); n = n + 1; end
            if (!idle) begin
                $display("FAIL el controlador no vuelve a reposo");
                errors = errors + 1;
            end
        end
    endtask

    task do_write(input [23:0] a, input [7:0] d);
        begin
            wait_idle;
            @(negedge clk); addr = a; din = d; wr = 1;
            @(negedge clk); wr = 0;
            wait_idle;
        end
    endtask

    task do_read(input [23:0] a, output [7:0] d);
        integer n;
        begin
            wait_idle;
            @(negedge clk); addr = a; rd = 1;
            @(negedge clk); rd = 0;
            n = 0;
            while (!ack && n < 500) begin @(negedge clk); n = n + 1; end
            d = dout;
            wait_idle;
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

    reg [7:0] v, v_val, c_val;
    integer v_seen, c_seen, v_at, c_at;

    initial begin
        repeat (4) @(negedge clk);
        reset = 0;

        wait_idle;
        if (model.pre_count < 1 || model.ref_count < 2 || model.lmr_count < 1) begin
            $display("FAIL secuencia de arranque incompleta: PRE=%0d REF=%0d LMR=%0d",
                     model.pre_count, model.ref_count, model.lmr_count);
            errors = errors + 1;
        end

        // byte bajo y byte alto de la misma palabra
        do_write(24'h000000, 8'h41);
        do_write(24'h000001, 8'h42);
        do_read(24'h000000, v);
        if (v !== 8'h41) begin
            $display("FAIL byte bajo: %02h", v); errors = errors + 1;
        end
        do_read(24'h000001, v);
        if (v !== 8'h42) begin
            $display("FAIL byte alto: %02h", v); errors = errors + 1;
        end

        // una escritura no debe pisar el byte contiguo
        do_write(24'h000002, 8'hAA);
        do_read(24'h000003, v);
        if (v !== 8'h00) begin
            $display("FAIL la escritura piso el byte contiguo: %02h", v);
            errors = errors + 1;
        end

        // rafaga de 64 bytes por direcciones consecutivas
        for (i = 0; i < 64; i = i + 1) do_write(24'h000100 + i[23:0], i[7:0] ^ 8'h5A);
        for (i = 0; i < 64; i = i + 1) begin
            do_read(24'h000100 + i[23:0], v);
            if (v !== (i[7:0] ^ 8'h5A)) begin
                $display("FAIL byte %0d: %02h (esperado %02h)", i, v, i[7:0] ^ 8'h5A);
                errors = errors + 1;
            end
        end

        // el refresco debe seguir ocurriendo durante el trafico
        i = model.ref_count;
        repeat (400) @(negedge clk);
        if (model.ref_count <= i) begin
            $display("FAIL no hay refresco periodico");
            errors = errors + 1;
        end

        // ---------- dos puertos a la vez ----------
        // El video pide en el mismo ciclo que la CPU: debe servirse primero
        // y ninguna de las dos peticiones puede perderse.
        do_write(24'h000200, 8'h11);
        do_write(24'h000201, 8'h22);
        wait_idle;
        @(negedge clk);
        a_addr = 24'h000200; a_rd = 1;
        addr = 24'h000201; rd = 1;
        @(negedge clk); a_rd = 0; rd = 0;

        v_seen = 0; c_seen = 0;
        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            if (a_ack) begin v_seen = 1; v_val = a_dout; v_at = i; end
            if (ack)  begin c_seen = 1; c_val = dout;  c_at = i; end
        end
        chk("el video recibe su dato", v_seen && v_val == 8'h11);
        chk("la CPU recibe el suyo", c_seen && c_val == 8'h22);
        chk("el video se sirve primero", v_at < c_at);

        // ---------- el puerto del video lee palabras enteras ----------
        do_write(24'h001000, 8'h11);
        do_write(24'h001001, 8'h22);
        wait_idle;
        @(negedge clk); a_addr = 24'h001000; a_rd = 1;
        @(negedge clk); a_rd = 0;
        i = 0;
        while (!a_ack && i < 500) begin @(negedge clk); i = i + 1; end
        if (a_dout !== 16'h2211) begin
            $display("FAIL palabra para el video: %04h (esperado 2211)", a_dout);
            errors = errors + 1;
        end

        // ---------- con los dos puertos pidiendo, el video a_addr primero ----------
        do_write(24'h001010, 8'hAB);
        do_write(24'h001011, 8'hCD);
        wait_idle;
        @(negedge clk);
        a_addr = 24'h001010; a_rd = 1;          // video
        addr = 24'h000000;   din = 8'h00; rd = 1;   // CPU a la vez
        @(negedge clk); a_rd = 0; rd = 0;
        i = 0;
        while (!a_ack && !ack && i < 500) begin @(negedge clk); i = i + 1; end
        if (!a_ack) begin
            $display("FAIL el video deberia servirse antes que la CPU");
            errors = errors + 1;
        end
        i = 0;
        while (!ack && i < 500) begin @(negedge clk); i = i + 1; end
        if (dout !== 8'h41) begin
            $display("FAIL la CPU tambien debe acabar servida: %02h", dout);
            errors = errors + 1;
        end
        if (a_dout !== 16'hCDAB) begin
            $display("FAIL palabra del video tras el arbitraje: %04h", a_dout);
            errors = errors + 1;
        end

        // ---------- filas y bancos distintos no deben solaparse ----------
        // Es la prueba que faltaba. Con la geometria mal puesta, la RAM
        // (banco 1) se plegaba sobre la fila 0 del banco 0 y machacaba la ROM,
        // que es exactamente lo que dejaba la maquina colgada.
        do_write(24'h000000, 8'h11);          // banco 0, fila 0: ROM
        do_write(24'h000200, 8'h22);          // banco 0, fila 1
        do_write(24'h07FE00, 8'h33);          // banco 0, ultima fila
        do_write(24'h200000, 8'h77);          // banco 1, fila 0
        do_write(24'h400000, 8'h44);          // banco 2, fila 0: RAM
        do_write(24'h400200, 8'h55);          // banco 2, fila 1
        do_write(24'h7FFE00, 8'h66);          // banco 3, ultima fila

        do_read(24'h000000, v);
        if (v !== 8'h11) begin
            $display("FAIL la ROM en 000000 quedo en %02h: algo la piso", v);
            errors = errors + 1;
        end
        do_read(24'h000200, v);
        if (v !== 8'h22) begin $display("FAIL fila 1 banco 0: %02h", v); errors = errors + 1; end
        do_read(24'h07FE00, v);
        if (v !== 8'h33) begin $display("FAIL ultima fila banco 0: %02h", v); errors = errors + 1; end
        do_read(24'h200000, v);
        if (v !== 8'h77) begin $display("FAIL fila 0 banco 1: %02h", v); errors = errors + 1; end
        do_read(24'h400000, v);
        if (v !== 8'h44) begin $display("FAIL fila 0 banco 2: %02h", v); errors = errors + 1; end
        do_read(24'h400200, v);
        if (v !== 8'h55) begin $display("FAIL fila 1 banco 2: %02h", v); errors = errors + 1; end
        do_read(24'h7FFE00, v);
        if (v !== 8'h66) begin $display("FAIL ultima fila banco 3: %02h", v); errors = errors + 1; end

        if (model.errores != 0) begin
            $display("FAIL el modelo detecto %0d violaciones de protocolo", model.errores);
            errors = errors + 1;
        end

        if (errors == 0) $display("tb_newbrain_sdram: OK (%0d refrescos, %0d precargas)",
                                  model.ref_count, model.pre_count);
        else begin $display("tb_newbrain_sdram: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
