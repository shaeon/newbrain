//============================================================================
// NewBrain - COP420 emulado a nivel de protocolo (HLE)
//
// Secuencia, tal cual la ejecuta la rutina COPIS de la ROM en E225:
//
//   E227  IN  A,(06)   lee el vector de interrupcion
//   E22D  OUT (06),D   devuelve el byte de reconocimiento (COPCTL)
//   E233  el nibble alto del vector decide la rama:
//           0X REGINT   1X CASSERR   2X CASSIN   3X KBD   4X CASSOUT
//
// Los comandos NO llegan por un canal aparte: la ROM los deja en COPCTL y
// viajan como byte de reconocimiento de la siguiente interrupcion,
// cualquiera que sea.
//
// En la rama REGINT, si el reconocimiento fue DISPCOM (A0) el Z80 espera en
// SYNDLP a que _COPINT y _CLKINT esten AMBOS pendientes y entonces envia 18
// bytes; con TIMCOM (B0) envia 6. Por eso se vuelve a bajar _COPINT.
//
// En la rama KBD el Z80 escribe 80 y lee hasta recibir algo distinto de 80;
// despues lee la tecla.
//
// CINTA. Todo sale del driver original, TPIO.S (EF1F-EFA4), ver
// doc/11-cinta.md:
//
//  * TCHR espera al bit READY de COPST y devuelve lo que haya en COPBUF.
//    READY lo pone CUALQUIER interrupcion salvo la de teclado. Un REGINT en
//    mitad de un bloque hace que TCHR devuelva basura, y si cae en la
//    longitud la ROM da ERROR 131 (LENGTHERR). Asi que mientras se reproduce
//    SOLO hay CASSIN, y mientras se graba SOLO hay CASSOUT.
//  * CASSCOM con PLAYBK (8C, 86) arranca la reproduccion. Llega dos veces
//    por bloque; la segunda se ignora.
//  * El primer byte de cada bloque es el 00 de sincronismo: PRETRD lo lee y
//    lo tira. Luego longitud, datos, tipo y suma. Tras la suma se para, y la
//    cola de nueve ceros no se entrega: se descarta.
//  * NULLCOM en el reconocimiento durante la reproduccion significa que la
//    ROM ha abandonado el bloque (error o BREAK). Se descarta lo que quede.
//  * Entre el CASSCOM y el primer byte hay que dejar un respiro: la ROM
//    habilita interrupciones en PUTCS unas instrucciones antes de que TCHR
//    las vuelva a quitar, y un CASSIN en esa ventana se pierde.
//  * Vector 2X con bit 0 a uno es de estado; con el bit 1 ademas, BREAK.
//
// Ver doc/02-cop420.md y doc/11-cinta.md
//============================================================================
`default_nettype none

module newbrain_cop_hle #(
    parameter CLK_HZ          = 32_000_000,
    parameter REGINT_HZ       = 50,
    parameter CASS_ARRANQUE_MS = 5,     // del CASSCOM al primer byte
    parameter CASS_ENTRE_MS    = 2      // entre bytes
) (
    input  wire       clk,
    input  wire       reset,
    // 1: solo cinta. El COP de verdad lleva teclado, pantalla y reloj; este
    // modulo solo entra cuando el Z80 manda un CASSCOM y sale al acabar.
    input  wire       solo_cinta,
    output wire       ocupado,          // lleva el puerto del COP ahora

    // puerto 06
    input  wire       cs,
    input  wire       rd,
    input  wire       wr,
    input  wire [7:0] din,
    output reg  [7:0] dout,
    output reg        copint_n,

    // cinta, lectura
    output wire [1:0] cass_motor,       // remote: {cinta 2, cinta 1}
    output reg        cass_reproduce,   // hay un bloque en reproduccion
    output reg        cass_limpia,      // pulso: empieza una reproduccion
    output reg        cass_pide,        // pulso: byte consumido
    output reg        cass_salta,       // pulso: descartar cass_salta_n
    output reg [15:0] cass_salta_n,
    output reg        cass_cola,        // pulso: tirar la cola de ceros
    input  wire [7:0] cass_dato,
    input  wire       cass_hay,

    // cinta, grabacion
    output reg        cass_graba_act,   // hay una grabacion en curso
    output reg  [7:0] cass_graba,       // byte que la ROM quiere grabar
    output reg        cass_graba_wr,
    input  wire       cass_graba_listo,

    // teclado
    input  wire [7:0] key_byte,
    input  wire       key_avail,
    output reg        key_taken,
    input  wire       brk,

    // display fluorescente: 18 bytes, entregados byte a byte
    output reg  [4:0] vfd_addr,
    output reg  [7:0] vfd_data,
    output reg        vfd_wr,
    output reg        vfd_valid     // pulso al completar los 18 bytes
);
    localparam CASSCOM = 4'h8;
    localparam DISPCOM = 4'hA;
    localparam TIMCOM  = 4'hB;
    localparam NULLCOM = 4'hD;

    localparam VEC_REGINT  = 8'h00;
    localparam VEC_CASSIN  = 8'h20;
    localparam VEC_KBD     = 8'h30;
    localparam VEC_CASSOUT = 8'h40;
    localparam NO_DATA     = 8'h80;
    localparam KEY_READY   = 8'h85;   // centinela que saca al Z80 del bucle

    reg       toma;
    reg [7:0] din_toma;
    wire [7:0] dcmd = toma ? din_toma : din;
    localparam S_IDLE     = 3'd0,
               S_WAIT_RD  = 3'd1,
               S_WAIT_ACK = 3'd2,
               S_KEY1     = 3'd3,
               S_KEY2     = 3'd4,
               S_DATA     = 3'd5,
               S_CASSIN   = 3'd6,
               S_CASSOUT  = 3'd7;

    // Fases del bloque de cinta
    localparam F_SYNC = 3'd0, F_LENL = 3'd1, F_LENH = 3'd2, F_DATOS = 3'd3,
               F_TIPO = 3'd4, F_CHKL = 3'd5, F_CHKH = 3'd6;

    reg [2:0] state;
    reg [7:0] vector;
    reg [4:0] data_cnt;
    reg [4:0] data_idx;
    reg       data_is_vfd;

    // Tick periodico que provoca el REGINT
    localparam TICK_DIV = CLK_HZ / REGINT_HZ;
    reg [23:0] tickcnt;
    reg        regint_due;

    // Base de milisegundos para los retardos de cinta
    localparam MS_DIV = (CLK_HZ >= 2000) ? CLK_HZ / 1000 : 2;
    reg [15:0] mscnt;
    reg        ms_tick;
    reg [7:0]  espera;

    reg [3:0]  cass_cmd;      // nibble bajo del CASSCOM en curso
    reg [2:0]  fase;
    reg [15:0] resto;
    reg [7:0]  dato_l;        // byte que se esta entregando
    reg        brk_d, brk_pend;
    reg        descarta_out;  // el dato que viene tras un NULLCOM no se graba
    reg        aborta_pend;   // abortar el bloque al terminar esta entrega

    // cs/rd/wr estan activos durante todo el ciclo de E/S.
    reg rd_d, wr_d;
    wire wr_edge = cs & wr & ~wr_d;
    wire rd_fall = ~(cs & rd) & rd_d;

    always @(posedge clk) begin
        rd_d <= cs & rd;
        wr_d <= cs & wr;
    end

    // Bytes que quedan del bloque en curso, sin la cola. Cero si la
    // longitud todavia no se conoce.
    reg [15:0] restante;
    always @* begin
        case (fase)
        F_DATOS: restante = resto + 16'd3;
        F_TIPO:  restante = 16'd3;
        F_CHKL:  restante = 16'd2;
        F_CHKH:  restante = 16'd1;
        default: restante = 16'd0;
        endcase
    end

    always @(posedge clk) begin
        key_taken     <= 1'b0;
        vfd_valid     <= 1'b0;
        vfd_wr        <= 1'b0;
        cass_pide     <= 1'b0;
        cass_limpia   <= 1'b0;
        cass_salta    <= 1'b0;
        cass_cola     <= 1'b0;
        cass_graba_wr <= 1'b0;
        ms_tick       <= 1'b0;

        if (reset) begin
            state          <= S_IDLE;
            toma           <= 1'b0;
            copint_n       <= 1'b1;
            vector         <= 8'h00;
            data_cnt       <= 5'd0;
            data_idx       <= 5'd0;
            tickcnt        <= 24'd0;
            regint_due     <= 1'b0;
            dout           <= NO_DATA;
            vfd_addr       <= 5'd0;
            vfd_data       <= 8'h20;
            cass_reproduce <= 1'b0;
            cass_graba_act <= 1'b0;
            cass_cmd       <= 4'd0;
            cass_salta_n   <= 16'd0;
            fase           <= F_SYNC;
            resto          <= 16'd0;
            espera         <= 8'd0;
            mscnt          <= 16'd0;
            brk_d          <= 1'b0;
            brk_pend       <= 1'b0;
            descarta_out   <= 1'b0;
            aborta_pend    <= 1'b0;
        end else begin
            if (mscnt >= MS_DIV[15:0] - 1) begin
                mscnt   <= 16'd0;
                ms_tick <= 1'b1;
            end else begin
                mscnt <= mscnt + 1'b1;
            end
            if (ms_tick && espera != 8'd0) espera <= espera - 1'b1;

            if (tickcnt >= TICK_DIV - 1) begin
                tickcnt    <= 24'd0;
                regint_due <= 1'b1;
            end else begin
                tickcnt <= tickcnt + 1'b1;
            end

            brk_d <= brk;
            if (!cass_reproduce)    brk_pend <= 1'b0;
            else if (brk && !brk_d) brk_pend <= 1'b1;

            case (state)
            S_IDLE: begin
                if (solo_cinta && wr_edge && din[7:4] == CASSCOM && (din[3] || din[1])) begin
                    // El CASSCOM iba como reconocimiento de una interrupcion
                    // del COP de verdad: se procesa como si fuera nuestra.
                    vector   <= 8'h00;
                    din_toma <= din;
                    toma     <= 1'b1;
                    state    <= S_WAIT_ACK;
                end else if (cass_reproduce) begin
                    // Solo CASSIN. Los REGINT que tocaran se pierden.
                    regint_due <= 1'b0;
                    if (brk_pend) begin
                        brk_pend <= 1'b0;
                        vector   <= VEC_CASSIN | {4'd0, cass_cmd[3:2], 2'b11};
                        copint_n <= 1'b0;
                        state    <= S_WAIT_RD;
                    end else if (espera == 8'd0 && cass_hay) begin
                        vector   <= VEC_CASSIN | {4'd0, cass_cmd[3:2], 2'b00};
                        dato_l   <= cass_dato;
                        copint_n <= 1'b0;
                        state    <= S_WAIT_RD;
                    end
                end else if (cass_graba_act) begin
                    // Solo CASSOUT, al ritmo que marque el modulador
                    regint_due <= 1'b0;
                    if (espera == 8'd0 && cass_graba_listo) begin
                        vector   <= VEC_CASSOUT | {4'd0, cass_cmd[3:2], 2'b00};
                        copint_n <= 1'b0;
                        state    <= S_WAIT_RD;
                    end
                end else if (key_avail && !solo_cinta) begin
                    vector   <= VEC_KBD | {5'd0, brk, 2'd0};
                    copint_n <= 1'b0;
                    state    <= S_WAIT_RD;
                end else if (regint_due && !solo_cinta) begin
                    regint_due <= 1'b0;
                    vector     <= VEC_REGINT | {5'd0, brk, 2'd0};
                    copint_n   <= 1'b0;
                    state      <= S_WAIT_RD;
                end
            end

            S_WAIT_RD: begin
                dout <= vector;
                if (rd_fall) begin
                    copint_n <= 1'b1;
                    state    <= S_WAIT_ACK;
                end
            end

            S_WAIT_ACK: begin
                if (wr_edge || toma) begin
                    toma <= 1'b0;
                    //--------------------------------------------------
                    // 1) El comando que viaja en el reconocimiento
                    //--------------------------------------------------
                    if (dcmd[7:4] == CASSCOM && (dcmd[3] || dcmd[1])) begin
                        if (dcmd[2]) begin
                            if (!cass_reproduce) begin
                                cass_reproduce <= 1'b1;
                                cass_graba_act <= 1'b0;
                                cass_cmd       <= dcmd[3:0];
                                cass_limpia    <= 1'b1;
                                fase           <= F_SYNC;
                                espera         <= CASS_ARRANQUE_MS[7:0];
                            end
                        end else if (!cass_graba_act) begin
                            cass_graba_act <= 1'b1;
                            cass_reproduce <= 1'b0;
                            cass_cmd       <= dcmd[3:0];
                            espera         <= CASS_ARRANQUE_MS[7:0];
                            // El sincronismo que el lector va a tirar
                            cass_graba     <= 8'h00;
                            cass_graba_wr  <= 1'b1;
                        end
                    end else if (dcmd[7:4] == NULLCOM) begin
                        if (cass_reproduce) begin
                            // Bloque abandonado (error de suma, longitud o
                            // BREAK): tirar lo que falte y la cola. Si esta
                            // interrupcion es un CASSIN con dato, ese byte ya
                            // esta elegido y la ROM lo va a leer igualmente:
                            // el descarte se lanza al entregarlo, para que
                            // la cuenta no dependa de quien lo consuma.
                            cass_reproduce <= 1'b0;
                            if (vector[7:4] == 4'h2 && !vector[0]) begin
                                aborta_pend <= 1'b1;
                            end else begin
                                fase <= F_SYNC;
                                if (restante != 16'd0) begin
                                    cass_salta   <= 1'b1;
                                    cass_salta_n <= restante;
                                    cass_cola    <= 1'b1;
                                end
                            end
                        end
                        if (cass_graba_act) begin
                            cass_graba_act <= 1'b0;
                            // si la interrupcion era CASSOUT, la ROM manda
                            // igualmente un dato viejo detras: no se graba
                            descarta_out   <= (vector[7:4] == 4'h4);
                        end
                    end

                    //--------------------------------------------------
                    // 2) La rama que toma la ROM segun el vector
                    //--------------------------------------------------
                    case (vector[7:4])
                    4'h3: begin
                        dout  <= KEY_READY;
                        state <= S_KEY1;
                    end
                    4'h2: begin
                        if (!vector[0]) begin
                            dout  <= dato_l;
                            state <= S_CASSIN;
                        end else begin
                            // Vector de estado. Con BREAK la ROM sale por
                            // ERREX y necesita tres interrupciones normales
                            // para terminar; si se siguiera en reproduccion
                            // sin cinta se quedaria esperando para siempre.
                            if (vector[1] && cass_reproduce) begin
                                cass_reproduce <= 1'b0;
                                fase           <= F_SYNC;
                                if (restante != 16'd0) begin
                                    cass_salta   <= 1'b1;
                                    cass_salta_n <= restante;
                                    cass_cola    <= 1'b1;
                                end
                            end
                            state <= S_IDLE;
                        end
                    end
                    4'h4: state <= S_CASSOUT;
                    4'h0: begin
                        if (dcmd[7:4] == DISPCOM) begin
                            data_cnt    <= 5'd18;
                            data_idx    <= 5'd0;
                            data_is_vfd <= 1'b1;
                            copint_n    <= 1'b0;    // para que SYNDLP salga
                            state       <= S_DATA;
                        end else if (dcmd[7:4] == TIMCOM) begin
                            data_cnt    <= 5'd6;
                            data_idx    <= 5'd0;
                            data_is_vfd <= 1'b0;
                            copint_n    <= 1'b0;
                            state       <= S_DATA;
                        end else begin
                            state <= S_IDLE;
                        end
                    end
                    default: state <= S_IDLE;
                    endcase
                end
            end

            S_KEY1: begin
                if (rd_fall) begin
                    dout  <= key_byte;
                    state <= S_KEY2;
                end
            end

            S_KEY2: begin
                if (rd_fall) begin
                    key_taken <= 1'b1;
                    dout      <= NO_DATA;
                    state     <= S_IDLE;
                end
            end

            S_CASSIN: begin
                if (rd_fall) begin
                    cass_pide <= 1'b1;
                    dout      <= NO_DATA;
                    espera    <= CASS_ENTRE_MS[7:0];
                    state     <= S_IDLE;

                    if (aborta_pend) begin
                        // restante incluye este byte, que se consume ahora
                        aborta_pend <= 1'b0;
                        fase        <= F_SYNC;
                        if (restante > 16'd1) begin
                            cass_salta   <= 1'b1;
                            cass_salta_n <= restante - 16'd1;
                        end
                        if (restante != 16'd0) cass_cola <= 1'b1;
                    end else if (cass_reproduce) begin
                        // Analizador de bloque
                        case (fase)
                        F_SYNC:  fase <= F_LENL;
                        F_LENL:  begin resto <= {8'd0, dato_l}; fase <= F_LENH; end
                        F_LENH:  begin
                            resto <= {dato_l, resto[7:0]};
                            fase  <= ({dato_l, resto[7:0]} == 16'd0) ? F_TIPO : F_DATOS;
                        end
                        F_DATOS: begin
                            resto <= resto - 1'b1;
                            if (resto == 16'd1) fase <= F_TIPO;
                        end
                        F_TIPO:  fase <= F_CHKL;
                        F_CHKL:  fase <= F_CHKH;
                        default: begin
                            // Suma completa: fin del bloque. La cola se tira.
                            fase           <= F_SYNC;
                            cass_reproduce <= 1'b0;
                            cass_cola      <= 1'b1;
                        end
                        endcase
                    end
                end
            end

            S_CASSOUT: begin
                if (wr_edge) begin
                    if (descarta_out) begin
                        descarta_out <= 1'b0;
                    end else begin
                        cass_graba    <= din;
                        cass_graba_wr <= 1'b1;
                    end
                    espera <= CASS_ENTRE_MS[7:0];
                    state  <= S_IDLE;
                end
            end

            S_DATA: begin
                if (wr_edge) begin
                    if (data_is_vfd && data_idx < 5'd18) begin
                        vfd_addr <= data_idx;
                        vfd_data <= din;
                        vfd_wr   <= 1'b1;
                    end
                    data_idx <= data_idx + 1'b1;
                    if (data_cnt == 5'd1) begin
                        copint_n  <= 1'b1;
                        vfd_valid <= data_is_vfd;
                        state     <= S_IDLE;
                    end
                    data_cnt <= data_cnt - 1'b1;
                end
            end

            default: state <= S_IDLE;
            endcase
        end
    end

    assign ocupado = (state != S_IDLE) | cass_reproduce | cass_graba_act;

    // Remote: los bits de motor del CASSCOM en curso (b3 cinta 1, b1 cinta
    // 2), mientras dura la operacion. Es lo que hacia el COP con G1 y G3.
    wire cass_activa = cass_reproduce | cass_graba_act;
    assign cass_motor = {cass_activa & cass_cmd[1], cass_activa & cass_cmd[3]};

endmodule

`default_nettype wire
