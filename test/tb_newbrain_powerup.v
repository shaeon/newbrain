`timescale 1ns/1ps
module tb_newbrain_powerup;
    reg clk = 0, reset = 1;
    wire cpu_reset_n, pwrup;
    integer errors = 0;
    integer cycles = 0;
    integer t_reset = -1, t_pwrup = -1;

    always #5 clk = ~clk;

    // CLK_HZ pequeno para que la simulacion sea corta:
    // T_RESET = 2200 ciclos, T_PWRUP = 5600 ciclos
    newbrain_powerup #(.CLK_HZ(1000)) dut (
        .clk(clk), .reset(reset), .fast(1'b0),
        .cpu_reset_n(cpu_reset_n), .pwrup(pwrup)
    );

    always @(posedge clk) if (!reset) begin
        cycles = cycles + 1;
        if (cpu_reset_n && t_reset < 0) t_reset = cycles;
        if (pwrup       && t_pwrup < 0) t_pwrup = cycles;
    end

    initial begin
        #23 reset = 0;
        #80000;
        if (t_reset < 2195 || t_reset > 2205) begin
            $display("FAIL RESET liberado en %0d ciclos (esperado ~2200)", t_reset);
            errors = errors + 1;
        end
        if (t_pwrup < 5595 || t_pwrup > 5605) begin
            $display("FAIL PWRUP liberado en %0d ciclos (esperado ~5600)", t_pwrup);
            errors = errors + 1;
        end
        if (t_reset >= t_pwrup) begin
            $display("FAIL RESET debe liberarse antes que PWRUP");
            errors = errors + 1;
        end
        if (errors == 0) $display("tb_newbrain_powerup: OK (reset=%0d pwrup=%0d)", t_reset, t_pwrup);
        else begin $display("tb_newbrain_powerup: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
