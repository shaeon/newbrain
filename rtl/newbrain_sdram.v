//============================================================================
// NewBrain - controlador de SDRAM para Calypso
//
// Aloja la ROM del sistema, la ROM de la controladora de disco y toda la RAM,
// que con la paginacion del modulo de expansion llega a 2 MB y no cabe de
// ninguna forma en block RAM. Ver doc/05-memoria.md y doc/08-sdram.md
//
// Dos puertos con arbitraje por prioridad fija:
//
//     refresco  >  video  >  CPU
//
// El video tiene plazo duro y la CPU no: si a la CPU le toca esperar se le
// quitan los clock enables y se acabo. El refresco va el primero porque
// cuesta un 3% del ancho de banda y no tenerlo pierde datos.
//
// Presupuesto en el peor caso, con el video pidiendo una palabra cada dos
// celdas de caracter, que en 80 columnas son 32 ciclos de sistema:
//
//     refresco 7 + CPU 7 + video 7 = 21 ciclos  <  32 disponibles
//
// Geometria del chip de la Calypso: 8 MB = 64 Mbit organizados como
//
//     4096 filas x 256 columnas x 4 bancos x 16 bits
//
// o sea filas de 12 bits, columnas de 8 y banco en las dos siguientes:
//
//     direccion de byte -> palabra = addr[23:1], byte = addr[0]
//     columna = palabra[7:0]   fila = palabra[19:8]   banco = palabra[21:20]
//
// Cada banco cubre 2 MB. Antes esto describia un chip de 128 Mbit, con filas
// de 13 bits, y la fila 4096 se plegaba sobre la 0: la RAM machacaba la ROM.
//============================================================================
`default_nettype none

module newbrain_sdram #(
    parameter CLK_HZ = 32_000_000
) (
    input  wire        clk,
    input  wire        reset,

    // pines
    output reg  [12:0] SDRAM_A,
    inout  wire [15:0] SDRAM_DQ,
    output reg         SDRAM_DQML,
    output reg         SDRAM_DQMH,
    output wire        SDRAM_nWE,
    output wire        SDRAM_nCAS,
    output wire        SDRAM_nRAS,
    output wire        SDRAM_nCS,
    output reg  [1:0]  SDRAM_BA,
    output wire        SDRAM_CKE,

    // puerto A: video. Se lleva la palabra de 16 bits entera, que son dos
    // caracteres consecutivos. Prioridad sobre la CPU.
    input  wire [23:0] a_addr,
    input  wire        a_rd,
    output reg  [15:0] a_dout,
    output reg         a_ack,

    // puerto B: CPU y carga desde SD. Acceso de byte.
    input  wire [23:0] b_addr,
    input  wire [7:0]  b_din,
    input  wire        b_rd,
    input  wire        b_wr,
    output reg  [7:0]  b_dout,
    output reg         b_ack,
    output wire        b_free
);
    // nCS, nRAS, nCAS, nWE
    localparam CMD_NOP   = 4'b0111;
    localparam CMD_ACT   = 4'b0011;
    localparam CMD_READ  = 4'b0101;
    localparam CMD_WRITE = 4'b0100;
    localparam CMD_PRE   = 4'b0010;
    localparam CMD_REF   = 4'b0001;
    localparam CMD_LMR   = 4'b0000;

    reg [3:0] cmd = CMD_NOP;
    assign {SDRAM_nCS, SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} = cmd;
    assign SDRAM_CKE = 1'b1;

    reg [15:0] dq_out;
    reg        dq_oe;
    assign SDRAM_DQ = dq_oe ? dq_out : 16'bZ;

    // Lo que llega de la SDRAM se registra en cada ciclo sin nada delante,
    // para que Quartus lo meta en el registro de entrada del propio pin
    // (FAST_INPUT_REGISTER en el .qsf). El reloj de la SDRAM va adelantado
    // 7,8 ns y el dato de CAS 2 se captura en el primer flanco del sistema
    // tras salir: en ese margen no cabian ademas los ~2,8 ns desde el pin
    // hasta un registro dentro de la logica, y el timing no cerraba.
    reg [15:0] dq_in;
    always @(posedge clk) dq_in <= SDRAM_DQ;

    localparam S_INIT = 3'd0, S_IDLE = 3'd1, S_ARB = 3'd2, S_ACT = 3'd3,
               S_RD   = 3'd4, S_WR   = 3'd5, S_REF = 3'd6;

    reg [2:0]  state = S_INIT;
    reg [14:0] wait_cnt;
    reg [4:0]  step;              // la secuencia de arranque llega a 20

    // Peticiones retenidas, una por puerto
    reg [23:0] a_hold_addr;
    reg        a_hold;
    reg [23:0] b_hold_addr;
    reg [7:0]  b_hold_data;
    reg        b_hold, b_hold_wr;

    // Peticion en curso
    reg [23:0] req_addr;
    reg [7:0]  req_data;
    reg        req_is_wr;
    reg        req_is_a;

    wire [22:0] word = req_addr[23:1];
    wire [7:0]  col  = word[7:0];
    wire [11:0] row  = word[19:8];
    wire [1:0]  bank = word[21:20];

    // B solo acepta cuando no tiene nada retenido: asi se acompasa data_io
    assign b_free = (state != S_INIT) && !b_hold;

    // Refresco: 8192 filas cada 64 ms -> una cada 7,8 us
    localparam [14:0] INIT_WAIT = CLK_HZ / 10000;   // 100 us
    localparam REF_DIV = CLK_HZ / 128_000;
    reg [9:0] ref_cnt;
    reg       ref_due;

    always @(posedge clk) begin
        a_ack <= 1'b0;
        b_ack <= 1'b0;
        cmd   <= CMD_NOP;
        dq_oe <= 1'b0;

        if (reset) begin
            state      <= S_INIT;
            wait_cnt   <= INIT_WAIT;
            step       <= 5'd0;
            a_hold     <= 1'b0;
            b_hold     <= 1'b0;
            ref_cnt    <= 10'd0;
            ref_due    <= 1'b0;
            SDRAM_DQML <= 1'b1;
            SDRAM_DQMH <= 1'b1;
        end else begin
            if (ref_cnt >= REF_DIV[9:0] - 1) begin
                ref_cnt <= 10'd0;
                ref_due <= 1'b1;
            end else begin
                ref_cnt <= ref_cnt + 1'b1;
            end

            // Captura de peticiones. Cada puerto retiene la suya hasta que
            // el arbitro le da paso.
            if (a_rd && !a_hold) begin
                a_hold_addr <= a_addr;
                a_hold      <= 1'b1;
            end
            if ((b_rd || b_wr) && !b_hold) begin
                b_hold_addr <= b_addr;
                b_hold_data <= b_din;
                b_hold_wr   <= b_wr;
                b_hold      <= 1'b1;
            end

            case (state)
            //--------------------------------------------------------------
            S_INIT: begin
                if (wait_cnt != 0) begin
                    wait_cnt <= wait_cnt - 1'b1;
                end else begin
                    step <= step + 1'b1;
                    case (step)
                    5'd0: begin                      // PRECHARGE ALL
                        cmd        <= CMD_PRE;
                        SDRAM_A    <= 13'h0400;      // A10 = 1
                        SDRAM_DQML <= 1'b0;
                        SDRAM_DQMH <= 1'b0;
                    end
                    5'd2:  cmd <= CMD_REF;
                    5'd10: cmd <= CMD_REF;
                    5'd18: begin                     // LOAD MODE REGISTER
                        cmd      <= CMD_LMR;
                        SDRAM_A  <= 13'b000_1_00_010_0_000;  // CAS 2, rafaga 1
                        SDRAM_BA <= 2'b00;
                    end
                    5'd20: begin
                        state <= S_IDLE;
                        step  <= 5'd0;
                    end
                    default: ;
                    endcase
                end
            end

            //--------------------------------------------------------------
            S_IDLE: begin
                step <= 5'd0;
                if (ref_due) begin
                    ref_due <= 1'b0;
                    cmd     <= CMD_REF;
                    state   <= S_REF;
                end else if (a_hold) begin
                    req_addr  <= a_hold_addr;
                    req_is_wr <= 1'b0;
                    req_is_a  <= 1'b1;
                    state     <= S_ARB;
                end else if (b_hold) begin
                    req_addr  <= b_hold_addr;
                    req_data  <= b_hold_data;
                    req_is_wr <= b_hold_wr;
                    req_is_a  <= 1'b0;
                    state     <= S_ARB;
                end
            end

            // Un ciclo para que req_addr tome valor antes de calcular la fila
            S_ARB: begin
                cmd      <= CMD_ACT;
                SDRAM_A  <= row;
                SDRAM_BA <= bank;
                state    <= S_ACT;
            end

            //--------------------------------------------------------------
            S_REF: begin
                step <= step + 1'b1;
                if (step == 5'd6) state <= S_IDLE;   // tRFC
            end

            //--------------------------------------------------------------
            S_ACT: begin
                state   <= req_is_wr ? S_WR : S_RD;
                step    <= 5'd0;
                // A10 es el bit de precarga automatica, y va en la posicion 10.
                // Estaba puesto como {4'b0000,1'b1,col}, que deja el uno en A8:
                // nunca se precargaba, la fila se quedaba abierta y el
                // siguiente ACTIVE a otra fila rompia el protocolo.
                SDRAM_A <= {2'b00, 1'b1, 2'b00, col};
                if (req_is_wr) begin
                    cmd        <= CMD_WRITE;
                    dq_out     <= {req_data, req_data};
                    dq_oe      <= 1'b1;
                    SDRAM_DQML <= req_addr[0];       // 0 = habilitado
                    SDRAM_DQMH <= ~req_addr[0];
                end else begin
                    cmd        <= CMD_READ;
                    SDRAM_DQML <= 1'b0;
                    SDRAM_DQMH <= 1'b0;
                end
            end

            //--------------------------------------------------------------
            S_RD: begin
                step <= step + 1'b1;
                // Latencia CAS 2: el dato entra en dq_in en el flanco de
                // step 2 y se reparte en el siguiente
                if (step == 5'd3) begin
                    if (req_is_a) begin
                        a_dout <= dq_in;
                        a_ack  <= 1'b1;
                        a_hold <= 1'b0;
                    end else begin
                        b_dout <= req_addr[0] ? dq_in[15:8] : dq_in[7:0];
                        b_ack  <= 1'b1;
                        b_hold <= 1'b0;
                    end
                end
                if (step == 5'd4) state <= S_IDLE;   // tRP tras la precarga
            end

            //--------------------------------------------------------------
            S_WR: begin
                step <= step + 1'b1;
                if (step == 5'd0) begin
                    b_ack  <= 1'b1;
                    b_hold <= 1'b0;
                end
                if (step == 5'd3) begin
                    SDRAM_DQML <= 1'b0;
                    SDRAM_DQMH <= 1'b0;
                    state      <= S_IDLE;
                end
            end

            default: state <= S_IDLE;
            endcase
        end
    end
endmodule

`default_nettype wire
