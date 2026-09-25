`timescale 1ns/1ps
// Espia del display: la secuencia real del Z80 (medida con las dos ROMs)
module tb_newbrain_vfd_espia;
    reg clk = 0, reset = 1; always #5 clk = ~clk;
    reg cs = 0, rd = 0, wr = 0; reg [7:0] din = 0;
    wire [127:0] texto; wire nuevo;
    newbrain_vfd_espia dut(.clk(clk), .reset(reset), .cs(cs), .rd(rd), .wr(wr), .din(din), .texto(texto), .nuevo(nuevo));
    task lee;  begin @(negedge clk); cs=1; rd=1; repeat(3) @(negedge clk); cs=0; rd=0; repeat(3) @(negedge clk); end endtask
    task esc(input [7:0] v); begin @(negedge clk); din=v; cs=1; wr=1; repeat(3) @(negedge clk); cs=0; wr=0; repeat(3) @(negedge clk); end endtask
    reg [7:0] nb [0:17];
    integer i, errors = 0;
    initial begin
        // "NEWBRAIN BASIC" tal como llega: 2 de control y el texto al reves
        {nb[0],nb[1],nb[2],nb[3],nb[4],nb[5],nb[6],nb[7],nb[8],nb[9],nb[10],nb[11],nb[12],nb[13],nb[14],nb[15],nb[16],nb[17]} =
          {8'h20,8'h00,8'h20,8'h20,8'h43,8'h49,8'h53,8'h41,8'h42,8'h20,8'h4E,8'h49,8'h41,8'h52,8'h42,8'h57,8'h45,8'h4E};
        repeat(3) @(negedge clk); reset = 0;
        lee; esc(8'hD0);                         // REGINT normal
        lee; esc(8'hB0);                         // TIMCOM: 6 bytes que no son texto
        for (i = 0; i < 6; i = i + 1) esc(8'h41);
        if (texto !== {16{8'h20}}) begin $display("FAIL TIMCOM se colo como texto"); errors = errors + 1; end
        lee; esc(8'hA0);                         // DISPCOM
        repeat (100) @(negedge clk);             // la interrupcion siguiente
        for (i = 0; i < 18; i = i + 1) esc(nb[i]);
        repeat (5) @(negedge clk);
        $display("  texto: \"%s\"", texto);
        if (texto !== "NEWBRAIN BASIC  ") begin $display("FAIL texto"); errors = errors + 1; end
        // DISPCOM y luego una lectura: no hubo datos, no cambia nada
        lee; esc(8'hA0); lee; esc(8'hD0);
        if (texto !== "NEWBRAIN BASIC  ") begin $display("FAIL cambio sin datos"); errors = errors + 1; end
        if (errors == 0) $display("tb_newbrain_vfd_espia: OK"); else $display("tb_newbrain_vfd_espia: %0d FALLOS", errors);
        $finish;
    end
endmodule
