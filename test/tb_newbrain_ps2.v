`timescale 1ns/1ps
//
// Receptor PS/2: secuencias de pulsar y soltar, teclas extendidas, y el
// caso que rompia el teclado en la SiDi (el firmware trocea los bytes).
// Aqui da igual: por la linea serie los bytes llegan siempre en orden.
//
module tb_newbrain_ps2;
    reg clk = 0, reset = 1;
    always #15.625 clk = ~clk;               // 32 MHz
    reg ps2c = 1, ps2d = 1;
    wire [10:0] k;
    newbrain_ps2 dut(.clk(clk), .reset(reset), .ps2_clk(ps2c), .ps2_data(ps2d), .ps2_key(k));

    integer errors = 0;
    task chk(input [255:0] n, input c);
        begin if (!c) begin $display("FALLO: %0s", n); errors = errors + 1; end end
    endtask

    // un byte PS/2, como lo serializa user_io
    task byte_ps2(input [7:0] b);
        integer i; reg [10:0] f;
        begin
            f = {1'b1, ~^b, b, 1'b0};
            for (i = 0; i < 11; i = i + 1) begin
                ps2d = f[i];
                #3000 ps2c = 0;
                #3000 ps2c = 1;
            end
            ps2d = 1;
            #20000;
        end
    endtask

    reg t;
    task espera_evento(input [255:0] n, input pulsada, input ext, input [7:0] cod);
        begin
            #1000;
            chk(n, k[10] != t && k[9] == pulsada && k[8] == ext && k[7:0] == cod);
            t = k[10];
        end
    endtask

    initial begin
        #200 reset = 0;
        #1000 t = k[10];

        byte_ps2(8'h1C);                     espera_evento("A pulsada", 1, 0, 8'h1C);
        byte_ps2(8'hF0); byte_ps2(8'h1C);    espera_evento("A soltada", 0, 0, 8'h1C);
        byte_ps2(8'h12);                     espera_evento("Shift pulsada", 1, 0, 8'h12);
        byte_ps2(8'hF0); #500000; byte_ps2(8'h12);   // bytes separados
        espera_evento("Shift soltada aunque llegue troceada", 0, 0, 8'h12);
        byte_ps2(8'hE0); byte_ps2(8'h75);    espera_evento("arriba", 1, 1, 8'h75);
        byte_ps2(8'hE0); byte_ps2(8'hF0); byte_ps2(8'h75);
        espera_evento("arriba soltada", 0, 1, 8'h75);
        byte_ps2(8'h1C);                     espera_evento("tras la extendida, normal", 1, 0, 8'h1C);

        // un bit perdido no deja el receptor desalineado para siempre
        ps2d = 0; #3000 ps2c = 0; #3000 ps2c = 1; ps2d = 1;
        #3000000;
        byte_ps2(8'h29);                     espera_evento("resincroniza tras un pulso suelto", 1, 0, 8'h29);

        if (errors == 0) $display("tb_newbrain_ps2: OK");
        else             $display("tb_newbrain_ps2: %0d FALLOS", errors);
        $finish;
    end
endmodule
