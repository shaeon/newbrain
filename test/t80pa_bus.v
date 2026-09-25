// Sustituto del T80 que genera ciclos de bus como un Z80 de verdad, para
// poder probar el enganche de parada de la CPU contra la SDRAM. No ejecuta
// nada: lee direcciones consecutivas desde START y deja a la vista el ultimo
// dato leido.
//
// Cada estado T avanza con un pulso de CEN_p, que es justo lo que el core
// retiene mientras espera a la memoria.
`default_nettype none
module T80pa #(parameter [15:0] START = 16'hE000) (
    input  wire RESET_n, CLK, CEN_p, CEN_n, WAIT_n, INT_n, NMI_n, BUSRQ_n,
    output reg  M1_n, MREQ_n, IORQ_n, RD_n, WR_n, RFSH_n,
    output wire HALT_n, BUSAK_n,
    output reg [15:0] A,
    input  wire [7:0] DI,
    output wire [7:0] DO
);
    // Pulso de un ciclo al capturar el dato, para que el banco de pruebas
    // pueda registrar cada lectura con su direccion.
    reg rd_done;
    assign HALT_n = 1'b1;
    assign BUSAK_n = 1'b1;
    assign DO = 8'h00;

    reg [1:0] t;
    reg [7:0] data;
    reg [15:0] count;

    initial begin
        t = 0; A = START; count = 0; rd_done = 0;
        M1_n = 1; MREQ_n = 1; IORQ_n = 1; RD_n = 1; WR_n = 1; RFSH_n = 1;
    end

    always @(posedge CLK) begin
        rd_done <= 1'b0;
        if (!RESET_n) begin
            t <= 0; A <= START; count <= 0;
            M1_n <= 1; MREQ_n <= 1; IORQ_n <= 1; RD_n <= 1; WR_n <= 1;
        end else if (CEN_p) begin
            case (t)
            0: begin                       // T1: direccion y peticion
                   MREQ_n <= 0; RD_n <= 0; M1_n <= 0;
                   t <= 1;
               end
            1: t <= 2;                     // T2
            2: begin                       // T3: se captura el dato
                   data    <= DI;
                   rd_done <= 1'b1;
                   MREQ_n  <= 1; RD_n <= 1; M1_n <= 1;
                   t       <= 3;
               end
            3: begin                       // ciclo siguiente, dando vueltas
                   A     <= {START[15:4], A[3:0] + 4'd1};
                   count <= count + 1'b1;
                   t     <= 0;
               end
            endcase
        end
    end
endmodule
`default_nettype wire
