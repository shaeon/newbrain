`timescale 1ns/1ps
//
// El serializador PS/2 de verdad de user_io (user_io_ps2) contra el
// receptor del core, con los bytes llegando como los manda cada firmware:
// de golpe (Calypso) o uno a uno con huecos (SiDi).
//
module tb_newbrain_ps2_uio;
    reg clk = 0, reset = 1;
    always #15.625 clk = ~clk;               // 32 MHz

    // mismo generador de reloj PS/2 que user_io, PS2DIV = 100
    reg ps2_clk = 0;
    integer cnt = 0;
    always @(posedge clk) begin
        cnt <= cnt + 1;
        if (cnt == 100) begin ps2_clk <= ~ps2_clk; cnt <= 0; end
    end

    reg       tx_strobe = 0;
    reg [7:0] tx_byte = 0;
    wire      pclk, pdat, fifo_ok;
    user_io_ps2 #(.PS2_BIDIR(0), .PS2_FIFO_BITS(4)) ser (
        .clk_sys(clk), .ps2_clk(ps2_clk),
        .ps2_clk_i(1'b1), .ps2_clk_o(pclk), .ps2_data_i(1'b1), .ps2_data_o(pdat),
        .ps2_tx_strobe(tx_strobe), .ps2_tx_byte(tx_byte),
        .ps2_rx_strobe(), .ps2_rx_byte(), .ps2_fifo_ready(fifo_ok)
    );

    wire [10:0] k;
    newbrain_ps2 dut(.clk(clk), .reset(reset), .ps2_clk(pclk), .ps2_data(pdat), .ps2_key(k));

    // lo que recibe el core, en orden
    reg [10:0] ev [0:31];
    integer nev = 0;
    reg t_ant = 0;
    always @(posedge clk) if (k[10] != t_ant) begin
        t_ant <= k[10];
        ev[nev] <= k;
        nev <= nev + 1;
    end

    task mete(input [7:0] b);
        begin
            @(posedge clk); tx_byte <= b; tx_strobe <= 1;
            @(posedge clk); tx_strobe <= 0;
        end
    endtask

    integer errors = 0;
    integer i;
    task chk(input [255:0] n, input c);
        begin if (!c) begin $display("FALLO: %0s", n); errors = errors + 1; end end
    endtask

    // En la FPGA estos registros de user_io arrancan a cero; en Icarus son X
    // y el serializador no se moveria nunca.
    initial begin
        ser.ps2_wptr = 0; ser.ps2_rptr = 0; ser.ps2_tx_state = 0;
    end

    initial begin
        repeat (10) @(posedge clk);
        reset = 0;

        // Calypso: la secuencia entera de golpe.  'a' pulsada y soltada
        mete(8'h1C); mete(8'hF0); mete(8'h1C);
        // SiDi: un byte por transferencia, con huecos.  Shift + 'a'
        mete(8'h12);  #300000;
        mete(8'h1C);  #300000;
        mete(8'hF0);  #300000;
        mete(8'h1C);  #300000;
        mete(8'hF0);  #300000;
        mete(8'h12);  #300000;
        // extendida troceada: flecha arriba
        mete(8'hE0);  #300000;
        mete(8'h75);  #300000;
        mete(8'hE0);  #300000;
        mete(8'hF0);  #300000;
        mete(8'h75);
        #3000000;

        chk("ocho eventos, ni uno de mas", nev == 8);
        chk("1 a pulsada",       ev[0] [9:0] == {1'b1, 1'b0, 8'h1C});
        chk("2 a soltada",       ev[1] [9:0] == {1'b0, 1'b0, 8'h1C});
        chk("3 shift pulsada",   ev[2] [9:0] == {1'b1, 1'b0, 8'h12});
        chk("4 a pulsada",       ev[3] [9:0] == {1'b1, 1'b0, 8'h1C});
        chk("5 a SOLTADA, aunque el F0 llegue suelto", ev[4][9:0] == {1'b0, 1'b0, 8'h1C});
        chk("6 shift SOLTADA: no se queda pegada",     ev[5][9:0] == {1'b0, 1'b0, 8'h12});
        chk("7 arriba pulsada",  ev[6] [9:0] == {1'b1, 1'b1, 8'h75});
        chk("8 arriba soltada",  ev[7] [9:0] == {1'b0, 1'b1, 8'h75});

        if (errors == 0) $display("tb_newbrain_ps2_uio: OK (%0d eventos)", nev);
        else             $display("tb_newbrain_ps2_uio: %0d FALLOS", errors);
        $finish;
    end
endmodule
