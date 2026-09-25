// Sustituto del T80 que ejecuta un GUION de ciclos de bus en vez de un
// programa: lectura o escritura de memoria o de E/S, uno detras de otro,
// con la forma de onda de un Z80 (tres estados T con CEN_p). Sirve para
// probar cableados sin necesitar el Z80 de verdad, que es VHDL.
//
// El banco de pruebas rellena op[], dir[] y dat[] y mira leido[].
//   op: 0 fin, 1 lee memoria, 2 escribe memoria, 3 lee E/S, 4 escribe E/S
`default_nettype none
module T80pa (
    input  wire RESET_n, CLK, CEN_p, CEN_n, WAIT_n, INT_n, NMI_n, BUSRQ_n,
    output reg  M1_n, MREQ_n, IORQ_n, RD_n, WR_n,
    output wire RFSH_n, HALT_n, BUSAK_n,
    output reg [15:0] A,
    input  wire [7:0] DI,
    output reg [7:0] DO
);
    assign RFSH_n = 1'b1;
    assign HALT_n = 1'b1;
    assign BUSAK_n = 1'b1;

    reg [2:0]  op     [0:63];
    reg [15:0] dir    [0:63];
    reg [7:0]  dat    [0:63];
    reg [7:0]  leido  [0:63];
    integer    pc;
    reg [1:0]  t;
    reg        fin;
    integer    k;

    initial begin
        for (k = 0; k < 64; k = k + 1) begin op[k] = 0; leido[k] = 8'hxx; end
        pc = 0; t = 0; fin = 0;
        M1_n = 1; MREQ_n = 1; IORQ_n = 1; RD_n = 1; WR_n = 1; A = 0; DO = 0;
    end

    always @(posedge CLK) begin
        if (!RESET_n) begin
            t <= 0;
            M1_n <= 1; MREQ_n <= 1; IORQ_n <= 1; RD_n <= 1; WR_n <= 1;
        end else if (CEN_p && !fin) begin
            case (t)
            0: begin
                if (op[pc] == 0) fin <= 1;
                else begin
                    A  <= dir[pc];
                    DO <= dat[pc];
                    if (op[pc] <= 2) MREQ_n <= 0; else IORQ_n <= 0;
                    if (op[pc] == 1 || op[pc] == 3) RD_n <= 0; else WR_n <= 0;
                    t <= 1;
                end
            end
            1: t <= 2;
            2: t <= 3;
            3: begin
                leido[pc] <= DI;
                MREQ_n <= 1; IORQ_n <= 1; RD_n <= 1; WR_n <= 1;
                pc <= pc + 1;
                t <= 0;
            end
            endcase
        end
    end
endmodule
`default_nettype wire
