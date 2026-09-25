`timescale 1ns/1ps
//
// Desmodulador y modulador de audio de newbrain_tape.v.
//
//  1. Se le da al desmodulador la forma de onda EXACTA que genera
//     beepgenerator.py (gylles38), muestra a muestra a 44100 Hz, que es un
//     formato que carga en maquinas reales. Las muestras las produce
//     tools/nbwav.py --bits a partir de cinta_prueba.bas.
//  2. Bucle cerrado: lo que sale del modulador entra en otro desmodulador.
//
// En los dos casos cada bloque tiene que salir byte a byte desde el
// sincronismo hasta la suma; despues vienen ceros de cola, cuantos da igual.
//
module tb_newbrain_tape;
    localparam CLK_HZ = 2_000_000;
    reg clk = 0, reset = 1;
    always #5 clk = ~clk;

    integer errors = 0;

    // Fichero de referencia (mismo contenido que cinta_prueba.bas)
    reg [7:0] ref_b [0:38];
    initial $readmemh("cinta_prueba.hex", ref_b);

    //------------------------------------------------------------------
    // 1. Forma de onda de beepgenerator.py
    //------------------------------------------------------------------
    reg muestras [0:115739];
    integer nmuestras = 115740;
    initial $readmemb("cinta_prueba.txt", muestras);

    reg audio_a = 1'b0;
    wire [7:0] dato_a;
    wire hay_a;
    reg  pide_a = 1'b0;

    newbrain_tape #(.CLK_HZ(CLK_HZ)) des_a (
        .clk(clk), .reset(reset), .fuente(1'b1), .rebobina(1'b0),
        .img_base(24'd0), .img_tam(24'd0),
        .sd_addr(), .sd_rd(), .sd_dout(8'd0), .sd_ack(1'b0),
        .audio(audio_a), .umbral(8'd76),
        .pide(pide_a), .limpia(1'b0), .salta(1'b0), .salta_n(16'd0), .cola_ini(1'b0),
        .dato(dato_a), .hay(hay_a), .err_audio(),
        .graba(1'b0), .graba_dato(8'd0), .graba_wr(1'b0), .graba_listo(), .tape_out()
    );

    reg [7:0] rx_a [0:255];
    integer   nrx_a = 0;
    always @(posedge clk) begin
        pide_a <= 1'b0;
        if (hay_a && !pide_a) begin
            rx_a[nrx_a] <= dato_a;
            nrx_a <= nrx_a + 1;
            pide_a <= 1'b1;
        end
    end

    // 44100 Hz a partir de CLK_HZ con acumulador fraccionario
    integer acc = 0, idx = 0;
    always @(posedge clk) if (!reset && idx < nmuestras) begin
        acc = acc + 44100;
        if (acc >= CLK_HZ) begin
            acc = acc - CLK_HZ;
            audio_a <= muestras[idx];
            idx = idx + 1;
        end
    end

    //------------------------------------------------------------------
    // 2. Bucle cerrado modulador -> desmodulador
    //------------------------------------------------------------------
    reg        graba = 1'b0;
    reg  [7:0] g_dato;
    reg        g_wr = 1'b0;
    wire       g_listo, t_out;

    newbrain_tape #(.CLK_HZ(CLK_HZ)) mod_b (
        .clk(clk), .reset(reset), .fuente(1'b0), .rebobina(1'b0),
        .img_base(24'd0), .img_tam(24'd0),
        .sd_addr(), .sd_rd(), .sd_dout(8'd0), .sd_ack(1'b0),
        .audio(1'b0), .umbral(8'd76),
        .pide(1'b0), .limpia(1'b0), .salta(1'b0), .salta_n(16'd0), .cola_ini(1'b0),
        .dato(), .hay(), .err_audio(),
        .graba(graba), .graba_dato(g_dato), .graba_wr(g_wr),
        .graba_listo(g_listo), .tape_out(t_out)
    );

    wire [7:0] dato_c;
    wire hay_c;
    reg  pide_c = 1'b0;
    // Un comparador real invierte o no: se prueba invertido
    newbrain_tape #(.CLK_HZ(CLK_HZ)) des_c (
        .clk(clk), .reset(reset), .fuente(1'b1), .rebobina(1'b0),
        .img_base(24'd0), .img_tam(24'd0),
        .sd_addr(), .sd_rd(), .sd_dout(8'd0), .sd_ack(1'b0),
        .audio(~t_out), .umbral(8'd76),
        .pide(pide_c), .limpia(1'b0), .salta(1'b0), .salta_n(16'd0), .cola_ini(1'b0),
        .dato(dato_c), .hay(hay_c), .err_audio(),
        .graba(1'b0), .graba_dato(8'd0), .graba_wr(1'b0), .graba_listo(), .tape_out()
    );

    reg [7:0] rx_c [0:255];
    integer   nrx_c = 0;
    always @(posedge clk) begin
        pide_c <= 1'b0;
        if (hay_c && !pide_c) begin
            rx_c[nrx_c] <= dato_c;
            nrx_c <= nrx_c + 1;
            pide_c <= 1'b1;
        end
    end

    task graba_byte(input [7:0] b);
        begin
            while (!g_listo) @(negedge clk);
            g_dato = b; g_wr = 1;
            @(negedge clk); g_wr = 0;
            @(negedge clk);
        end
    endtask

    // Comprueba que un bloque de ref (desde off, n bytes) aparece en rx a
    // partir de pos; devuelve la posicion siguiente saltando ceros de cola.
    function integer busca(input integer cual, input integer pos,
                           input integer off, input integer n);
        integer k, p, ok;
        reg [7:0] v;
        begin
            ok = 1;
            for (k = 0; k < n; k = k + 1) begin
                v = (cual == 0) ? rx_a[pos + k] : rx_c[pos + k];
                if (v !== ref_b[off + k]) begin
                    $display("FAIL %s: byte %0d = %02h, esperado %02h",
                             cual == 0 ? "beepgenerator" : "bucle",
                             pos + k, v, ref_b[off + k]);
                    ok = 0;
                end
            end
            if (!ok) errors = errors + 1;
            p = pos + n;
            v = (cual == 0) ? rx_a[p] : rx_c[p];
            while (v === 8'h00) begin
                p = p + 1;
                v = (cual == 0) ? rx_a[p] : rx_c[p];
            end
            // el sincronismo del bloque siguiente es un cero: devolver uno menos
            busca = p - 1;
        end
    endfunction

    integer i, p;
    initial begin
        repeat (10) @(negedge clk);
        reset = 0;

        // Bucle cerrado: dos grabaciones, una por bloque, como la ROM
        fork
            begin
                graba = 1;
                for (i = 0; i < 19; i = i + 1) graba_byte(ref_b[i]);
                while (!g_listo) @(negedge clk);
                graba = 0;
                repeat (100000) @(negedge clk);
                graba = 1;
                for (i = 19; i < 39; i = i + 1) graba_byte(ref_b[i]);
                while (!g_listo) @(negedge clk);
                repeat (40000) @(negedge clk);
                graba = 0;
            end
            begin
                wait (idx >= nmuestras);
            end
        join
        repeat (200000) @(negedge clk);

        $display("beepgenerator: %0d bytes, bucle: %0d bytes", nrx_a, nrx_c);
        // bloque 1: 10 bytes sin cola; bloque 2: 11
        p = busca(0, 0, 0, 10);
        p = busca(0, p, 19, 11);
        p = busca(1, 0, 0, 10);
        p = busca(1, p, 19, 11);

        if (errors == 0) $display("tb_newbrain_tape: OK");
        else begin $display("tb_newbrain_tape: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
