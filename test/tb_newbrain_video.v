`timescale 1ns/1ps
//
// Comprueba el recorrido de pantalla del generador de imagen: direccion de
// inicio, paso entre filas, terminador de linea y video inverso.
//
// El modelo de generador de caracteres devuelve el propio codigo del
// caracter como patron de puntos, de modo que los 8 pixeles de cada celda
// deben reproducir los bits del byte leido de la RAM.
//
module tb_newbrain_video;
    // ANCHO=1: modo Wide, con el pixel a su propio reloj (27/32 del sistema)
    parameter ANCHO = 0;
    reg clk = 0, reset = 1, ce_pix = 0;
    reg [15:0] tv_addr = 16'h1000;
    reg [7:0]  tvtl = 8'h48;      // 80 columnas, 8 lineas por caracter
    reg        tv_enable = 1;

    wire [23:0] sd_addr;
    wire        sd_rd;
    reg  [15:0] sd_dout;
    reg         sd_ack;
    wire [7:0]  cg_char;
    wire [3:0]  cg_line;
    reg  [7:0]  cg_data;
    wire [7:0]  R, G, B;
    wire hsync, vsync, hblank, vblank, vsync_pulse;

    integer errors = 0;
    integer i;

    reg [7:0] mem [0:32767];

    always #5 clk = ~clk;
    reg clkp = 0;
    always #5.926 clkp = ~clkp;                     // 32/27 del periodo de clk
    wire clk_pix = ANCHO ? clkp : clk;
    always @(posedge clk_pix) ce_pix <= ~ce_pix;

    // Modelo de SDRAM: sirve la palabra pedida varios ciclos despues, para
    // comprobar que la rafaga de relleno aguanta la latencia real.
    always @(posedge clk_pix) cg_data <= cg_char;

    // periodo de linea, entre dos subidas de hsync
    realtime t_hs = 0, t_linea = 0;
    always @(posedge hsync) begin
        if (t_hs > 0) t_linea = $realtime - t_hs;
        t_hs = $realtime;
    end   // patron = codigo de caracter

    localparam LAT = 9;
    reg [23:0] pend_addr;
    integer    lat = 0;

    always @(posedge clk) begin
        sd_ack  <= 1'b0;
        if (sd_rd) begin
            pend_addr <= sd_addr;
            lat = LAT;
        end else if (lat > 0) begin
            lat = lat - 1;
            if (lat == 0) begin
                sd_dout <= {mem[pend_addr + 1], mem[pend_addr]};
                sd_ack  <= 1'b1;
            end
        end
    end

    newbrain_video dut (
        .clk(clk), .clk_pix(clk_pix), .ce_pix(ce_pix), .reset(reset), .ancho(ANCHO[0]),
        .tv_enable_in(tv_enable), .h_off(8'sd0), .v_off(8'sd0), .tv_addr_in(tv_addr), .tvtl_in(tvtl),
        .sd_addr(sd_addr), .sd_rd(sd_rd),
        .sd_dout(sd_dout), .sd_ack(sd_ack), .ram_base(24'd0),
        .cg_char(cg_char), .cg_line(cg_line), .cg_data(cg_data),
        .R(R), .G(G), .B(B),
        .hsync(hsync), .vsync(vsync), .hblank(hblank), .vblank(vblank),
        .vsync_pulse(vsync_pulse)
    );

    // Captura de los primeros pixeles de dos lineas visibles: la primera de
    // la fila 0 y la primera de la fila 1, para validar el paso entre filas.
    localparam CAPN = 640;
    reg     cap  [0:CAPN-1];
    reg     cap1 [0:CAPN-1];
    reg     capg  [0:CAPN-1];
    reg     capg1 [0:CAPN-1];
    integer capi = 0, capi1 = 0, capgi = 0, capgi1 = 0;
    reg     capturing = 0, capturing1 = 0, capturingg = 0, capturingg1 = 0;
    integer lin_g = 8;
    // Referencias tomadas del propio modulo, para que el ajuste de centrado
    // no rompa la captura.
    wire [10:0] hs = dut.hs_eff;
    wire [9:0]  vs = dut.vs_eff;

    always @(posedge clk_pix) if (ce_pix) begin
        // Se captura una linea del CUERPO del glifo, no la 0: las lineas 0 y
        // 1 llevan la regla del descendente, y este modelo de generador de
        // caracteres devuelve el propio codigo como patron, con lo que el
        // bit 0 activaria la marca sin querer.
        if (dut.vcnt == vs + 10'd2 && dut.hcnt == hs) begin
            capturing <= 1; capi = 0;
        end
        if (capturing && capi < CAPN) begin
            cap[capi] = R[7];
            capi = capi + 1;
        end
        if (dut.vcnt == vs + 10'd10 && dut.hcnt == hs) begin
            capturing1 <= 1; capi1 = 0;
        end
        if (capturing1 && capi1 < CAPN) begin
            cap1[capi1] = R[7];
            capi1 = capi1 + 1;
        end
        // dos lineas seguidas de la zona grafica
        if (dut.vcnt == vs + lin_g && dut.hcnt == hs) begin
            capturingg <= 1; capgi = 0;
        end
        if (capturingg && capgi < CAPN) begin
            capg[capgi] = R[7];
            capgi = capgi + 1;
        end
        if (dut.vcnt == vs + lin_g + 1 && dut.hcnt == hs) begin
            capturingg1 <= 1; capgi1 = 0;
        end
        if (capturingg1 && capgi1 < CAPN) begin
            capg1[capgi1] = R[7];
            capgi1 = capgi1 + 1;
        end
    end

    function [7:0] gval;     // byte n de la linea grafica capturada
        input integer n;
        integer k;
        begin
            gval = 8'h00;
            for (k = 0; k < 8; k = k + 1) gval = {gval[6:0], capg[n*8 + k]};
        end
    endfunction

    function [7:0] gval1;    // lo mismo en la linea siguiente
        input integer n;
        integer k;
        begin
            gval1 = 8'h00;
            for (k = 0; k < 8; k = k + 1) gval1 = {gval1[6:0], capg1[n*8 + k]};
        end
    endfunction

    task chk(input [255:0] name, input cond);
        begin
            if (!cond) begin
                $display("FAIL %0s", name);
                errors = errors + 1;
            end
        end
    endtask

    // Retardo del cauce entre hcnt y el pixel que sale por R
    localparam OFS = 0;

    function [7:0] cellval;
        input integer n;
        integer k;
        begin
            cellval = 8'h00;
            for (k = 0; k < 8; k = k + 1)
                cellval = {cellval[6:0], cap[n*8 + k + OFS]};
        end
    endfunction

    // En 40 columnas cada punto dura dos ciclos: se toma uno de cada dos
    function [7:0] cellval40;
        input integer n;
        integer k;
        begin
            cellval40 = 8'h00;
            for (k = 0; k < 8; k = k + 1)
                cellval40 = {cellval40[6:0], cap[n*16 + k*2 + OFS]};
        end
    endfunction

    function [7:0] cellval_row1;
        input integer n;
        integer k;
        begin
            cellval_row1 = 8'h00;
            for (k = 0; k < 8; k = k + 1)
                cellval_row1 = {cellval_row1[6:0], cap1[n*8 + k + OFS]};
        end
    endfunction

    initial begin
        for (i = 0; i < 32768; i = i + 1) mem[i] = 8'h00;
        // base = tv_addr + START_OFS_80 = 1004
        mem[16'h1004] = 8'h41;   // 'A'
        mem[16'h1005] = 8'h42;   // 'B'
        mem[16'h1006] = 8'hC3;   // bit 7 -> campo inverso, caracter 43
        mem[16'h1007] = 8'h00;   // fin de linea
        mem[16'h1008] = 8'h55;   // no debe verse
        // fila 1: base + EL = 1004 + 128 = 1084
        mem[16'h1084] = 8'h5A;   // 'Z'
        mem[16'h1085] = 8'h00;

        repeat (10) @(negedge clk);
        reset = 0;

        // una trama completa
        @(posedge vsync_pulse);
        @(posedge vsync_pulse);
        repeat (4000) @(negedge clk);

        $write("volcado:");
        for (i = 0; i < 32; i = i + 1) $write("%b", cap[i]);
        $display("");

        chk("celda 0 = 'A'", cellval(0) == 8'h41);
        chk("celda 1 = 'B'", cellval(1) == 8'h42);
        chk("celda 2 en campo inverso", cellval(2) == ~8'h43);
        chk("celda 3 en blanco tras el 0", cellval(3) == 8'h20);
        chk("fila 1 a un paso de EL=128", cellval_row1(0) == 8'h5A);
        chk("fila 1 tambien respeta el fin de linea", cellval_row1(1) == 8'h20);

        // ---------- 40 columnas ----------
        // EL = 64, desfase de inicio 2, celdas de 16 puntos
        tvtl = 8'h08;
        for (i = 0; i < 32768; i = i + 1) mem[i] = 8'h00;
        mem[16'h1002] = 8'h41;   // base = tv_addr + START_OFS_40
        mem[16'h1003] = 8'h42;
        mem[16'h1004] = 8'h00;
        capturing = 0;
        @(posedge vsync_pulse);
        @(posedge vsync_pulse);
        repeat (4000) @(negedge clk);
        chk("40 columnas, celda 0 = 'A'", cellval40(0) == 8'h41);
        chk("40 columnas, celda 1 = 'B'", cellval40(1) == 8'h42);
        chk("40 columnas, celda 2 en blanco", cellval40(2) == 8'h20);

        // ---------- zona grafica ----------
        // Fila 0 de texto y fila 1 con el terminador 00 00 00 00: los
        // graficos empiezan en esa misma fila, con paso de 80 bytes por
        // LINEA DE BARRIDO, y el bit 0 de cada byte es el punto de la
        // izquierda (al reves que en los caracteres).
        tvtl = 8'h48;
        for (i = 0; i < 32768; i = i + 1) mem[i] = 8'h00;
        mem[16'h1004] = 8'h41;
        mem[16'h1005] = 8'h00;
        mem[16'h1088] = 8'hF0;           // byte 4 de la linea grafica 0
        mem[16'h1089] = 8'h3C;
        mem[16'h1084 + 80] = 8'hAA;      // linea grafica 1, byte 0
        mem[16'h1084 + 81] = 8'h55;
        mem[16'h1084 + 128] = 8'hFF;     // donde caeria con el paso de EL
        capturing = 0; capturingg = 0; capturingg1 = 0;
        lin_g = 8;
        @(posedge vsync_pulse);
        @(posedge vsync_pulse);
        repeat (4000) @(negedge clk);
        // Los cuatro bytes del terminador valen cero: en modo texto salen
        // como espacios y en grafico como puntos apagados, lo mismo. (El
        // generador de este banco devuelve el codigo como patron, de ahi el
        // 20 en vez del 00.)
        chk("graficos: el terminador no se ve", gval(0) == 8'h20);
        chk("graficos: byte 4, bit 0 a la izquierda", gval(4) == 8'h0F);
        chk("graficos: byte 5 igual", gval(5) == 8'h3C);
        chk("graficos: la linea siguiente va 80 bytes mas alla", gval1(0) == 8'h55);
        chk("graficos: y no 128 (EL)", gval1(1) == 8'hAA);

        // ---------- pantalla estrecha ----------
        // 512 puntos centrados: 64 en blanco a cada lado, 8 bytes de hueco
        // antes del primer byte de la imagen y paso de 64.
        tvtl = 8'h4C;
        for (i = 0; i < 32768; i = i + 1) mem[i] = 8'h00;
        mem[16'h1004] = 8'h41;
        mem[16'h1005] = 8'h00;
        mem[16'h1084 + 8]  = 8'h0F;      // primer byte de la imagen
        mem[16'h1084 + 71] = 8'hC0;      // ultimo byte de la imagen
        mem[16'h1084 + 72] = 8'hAA;      // ya es la linea siguiente
        mem[16'h1084 + 73] = 8'h55;
        capturing = 0; capturingg = 0; capturingg1 = 0;
        @(posedge vsync_pulse);
        @(posedge vsync_pulse);
        repeat (4000) @(negedge clk);
        chk("estrecha: la segunda linea deja 64 puntos en blanco", gval1(0) == 8'h00 && gval1(7) == 8'h00);
        chk("estrecha: la imagen empieza en la celda 8", gval(8) == 8'hF0);
        chk("estrecha: y acaba en la 71", gval(71) == 8'h03);
        chk("estrecha: y a la derecha, blanco", gval(72) == 8'h00 && gval(79) == 8'h00);
        // En la primera linea las celdas 0 a 3 son el terminador, pintado
        // todavia como texto; de la 4 a la 7 ya son los ceros del hueco.
        chk("estrecha: a la izquierda de la primera linea, los ceros del hueco",
            gval(4) == 8'h00 && gval(7) == 8'h00);
        chk("estrecha: la linea siguiente va 64 bytes mas alla", gval1(8) == 8'h55);
        chk("estrecha: y el byte 1 tambien", gval1(9) == 8'hAA);

        // ---------- 00 00 20 20: fin de pantalla ----------
        // Es lo que el sistema deja detras del texto al arrancar. Lo de
        // debajo va en blanco, no es una zona grafica: tomarlo por graficos
        // pintaba una fila de basura abajo del todo.
        tvtl = 8'h48;
        for (i = 0; i < 32768; i = i + 1) mem[i] = 8'h00;
        mem[16'h1004] = 8'h41;
        mem[16'h1005] = 8'h00;
        mem[16'h1084] = 8'h00;   // fila 1: 00 00 20 20
        mem[16'h1085] = 8'h00;
        mem[16'h1086] = 8'h20;
        mem[16'h1087] = 8'h20;
        for (i = 16'h1088; i < 16'h1200; i = i + 1) mem[i] = 8'hFF;  // basura
        capturing = 0; capturingg = 0; capturingg1 = 0;
        @(posedge vsync_pulse);
        @(posedge vsync_pulse);
        repeat (4000) @(negedge clk);
        chk("fin de pantalla: nada debajo", gval(4) == 8'h00 && gval(40) == 8'h00
                                         && gval1(4) == 8'h00 && gval1(40) == 8'h00);

        // La linea dura lo mismo (64 us a escala) en los dos modos: 1024
        // puntos a clk/2 en Original, 864 a clk_pix/2 en Wide
        chk("periodo de linea", (t_linea > 20480*0.995) && (t_linea < 20480*1.005));
        if (ANCHO) chk("linea de 864 puntos", dut.h_total == 11'd864);

        if (errors == 0) $display("tb_newbrain_video%s: OK (linea de %0.0f ns)", ANCHO ? " (Wide)" : "", t_linea);
        else begin $display("tb_newbrain_video: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
