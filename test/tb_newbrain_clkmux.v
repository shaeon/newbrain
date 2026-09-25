`timescale 1ns/1ps
module tb_newbrain_clkmux;
    reg c0=0, c1=0, sel=0; wire o;
    always #15.625 c0=~c0;        // 32 MHz
    always #18.518 c1=~c1;        // 27 MHz
    newbrain_clkmux dut(.clk0(c0), .clk1(c1), .sel(sel), .clk_out(o));
    realtime tsube=0, tbaja=0; integer cortos=0, n=0;
    always @(posedge o) tsube=$realtime;
    always @(negedge o) begin
        if ($realtime - tsube < 14.0 && tsube > 0) cortos=cortos+1;
        n=n+1;
    end
    always @(posedge o) if (tbaja > 0 && $realtime - tbaja < 14.0) cortos=cortos+1;
    always @(negedge o) tbaja=$realtime;
    integer i;
    initial begin
        for (i=0;i<20;i=i+1) begin #(1003+i*37) sel=~sel; end
        #2000;
        if (cortos==0 && n>100) $display("tb_newbrain_clkmux: OK (%0d ciclos, 20 cambios, ningun pulso corto)", n);
        else $display("tb_newbrain_clkmux: FALLO (%0d pulsos cortos)", cortos);
        $finish;
    end
endmodule
