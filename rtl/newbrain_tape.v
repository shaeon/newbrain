//============================================================================
// NewBrain - fuente y sumidero de bytes de cinta
//
// El COP no entrega una señal modulada al Z80: le entrega **bytes**, uno por
// interrupcion CASSIN, y recoge uno por interrupcion CASSOUT. Este modulo es
// el otro extremo de esa conversacion. Quien decide cuando se entrega cada
// byte, y cuantos, es el HLE del COP (newbrain_cop_hle.v); aqui solo se
// consiguen y se guardan.
//
// LECTURA, FICHERO (fuente = 0)
//   Imagen en la SDRAM con el formato de cdesp, tal cual: por cada bloque
//   un 00 de sincronismo, longitud, datos, tipo, suma y nueve ceros. Ver
//   doc/11-cinta.md
//
// LECTURA, AUDIO (fuente = 1)
//   Formato sacado de newbrain-bin-wav (gylles38), que carga en maquinas
//   reales:
//
//     bit 0   un ciclo largo    semiperiodos de ~408 us
//     bit 1   dos ciclos cortos semiperiodos de ~204 us
//     piloto  largo, corto, corto, largo, repetido ~0,8 s
//     inicio  un bit 1
//     byte    8 bits, el mas significativo primero, y despues 0 y 1
//
//   Solo se miden duraciones de semiperiodo, asi que la polaridad del
//   comparador de la placa no importa. El umbral entre corto y largo es
//   ajustable desde el OSD por si la cinta corre algo rapida o lenta.
//
// DESCARTE
//   El HLE puede pedir que se tiren N bytes (el resto de un bloque que la ROM
//   ha abandonado) y la cola de hasta nueve ceros de cada bloque. Vale igual
//   para las dos fuentes.
//
// GRABACION
//   Los bytes que entrega la ROM se modulan con el mismo formato y salen por
//   tape_out, que el top manda al audio. Cada vez que empieza una grabacion
//   se emite el piloto antes del primer byte.
//============================================================================
`default_nettype none

module newbrain_tape #(
    parameter CLK_HZ = 32_000_000
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        fuente,          // 0 = fichero, 1 = audio
    input  wire        rebobina,        // vuelve al principio de la imagen

    // imagen en SDRAM. sd_rd se mantiene hasta sd_ack.
    input  wire [23:0] img_base,
    input  wire [23:0] img_tam,
    output reg  [23:0] sd_addr,
    output reg         sd_rd = 1'b0,
    input  wire [7:0]  sd_dout,
    input  wire        sd_ack,

    // entrada de audio, ya sincronizada
    input  wire        audio,
    input  wire [7:0]  umbral,          // frontera corto/largo, en unidades de 4 us

    // lectura, hacia el COP
    input  wire        pide,            // pulso: se ha consumido el byte
    input  wire        limpia,          // pulso: empieza una reproduccion
    input  wire        salta,           // pulso: descartar salta_n bytes
    input  wire [15:0] salta_n,
    input  wire        cola_ini,        // pulso: tirar hasta nueve ceros
    output wire [7:0]  dato,
    output wire        hay,
    output reg         err_audio,       // pulso: error de encuadre

    // grabacion, desde el COP
    input  wire        graba,           // hay una grabacion en curso
    input  wire [7:0]  graba_dato,
    input  wire        graba_wr,
    output wire        graba_listo,     // se puede aceptar otro byte
    output reg         tape_out
);
    //------------------------------------------------------------------
    // Base de tiempos: un pulso por microsegundo
    //------------------------------------------------------------------
    localparam US_DIV = (CLK_HZ >= 2_000_000) ? CLK_HZ / 1_000_000 : 2;
    reg [7:0] us_cnt;
    reg       us_tick;
    always @(posedge clk) begin
        us_tick <= 1'b0;
        if (reset || us_cnt >= US_DIV[7:0] - 1) begin
            us_cnt  <= 8'd0;
            us_tick <= ~reset;
        end else begin
            us_cnt <= us_cnt + 1'b1;
        end
    end

    //------------------------------------------------------------------
    // Descarte de bytes, comun a las dos fuentes
    //
    // Dos contadores: `descarta` tira N bytes sean los que sean (el resto de
    // un bloque abandonado) y `cola` tira hasta nueve CEROS, parando en el
    // primer byte que no lo sea. Asi un fichero con la cola mas corta de lo
    // normal no se come el sincronismo y la longitud del bloque siguiente.
    //------------------------------------------------------------------
    localparam [3:0] COLA_N = 4'd9;

    reg  [15:0] descarta;
    reg  [3:0]  cola;
    wire        buf_hay;
    wire [7:0]  buf_dato;
    wire        tira_n = (descarta != 16'd0) && buf_hay;
    wire        tira_c = (descarta == 16'd0) && (cola != 4'd0) && buf_hay
                       && (buf_dato == 8'h00);
    wire        tira   = tira_n | tira_c;
    wire        vacio  = (descarta == 16'd0)
                       && ((cola == 4'd0) || (buf_hay && buf_dato != 8'h00));
    wire        consume = (pide && vacio) || tira;

    always @(posedge clk) begin
        // En audio, una reproduccion nueva empieza buscando piloto y no
        // hereda descartes. En fichero el descarte del bloque anterior tiene
        // que completarse aunque la ROM ya pida el siguiente.
        if (reset || rebobina || (limpia && fuente)) begin
            descarta <= 16'd0;
            cola     <= 4'd0;
        end else begin
            if (salta)
                descarta <= descarta + salta_n - {15'd0, tira_n};
            else if (tira_n)
                descarta <= descarta - 1'b1;

            if (cola_ini)
                cola <= COLA_N;
            else if (tira_c)
                cola <= cola - 1'b1;
            else if (descarta == 16'd0 && cola != 4'd0 && buf_hay)
                cola <= 4'd0;           // no era un cero: se acabo la cola
        end
    end

    //------------------------------------------------------------------
    // Fuente de fichero
    //
    // La peticion se RETIENE hasta sd_ack. Antes era un pulso de un ciclo y
    // se podia perder si la CPU ganaba el puerto de la SDRAM justo en ese
    // ciclo; como `pendiente` quedaba a uno, no se reintentaba nunca y la
    // cinta se quedaba muda para siempre.
    //------------------------------------------------------------------
    // Como un casete de verdad: la cinta solo vuelve al principio cuando se
    // rebobina (OSD) o se mete una nueva. Reiniciar la maquina NO la mueve:
    // antes lo hacia, y tras un reset se volvia a cargar el primer programa
    // en vez del siguiente. Por eso aqui no entra `reset`, y los valores
    // iniciales cubren el arranque de la FPGA.
    reg [23:0] pos       = 24'd0;
    reg [7:0]  buf_f;
    reg        buf_ok    = 1'b0;
    reg        pendiente = 1'b0;

    wire fin = (pos >= img_tam) || (img_tam == 24'd0);

    always @(posedge clk) begin
        if (rebobina) begin
            pos       <= 24'd0;
            buf_ok    <= 1'b0;
            pendiente <= 1'b0;
            sd_rd     <= 1'b0;
        end else begin
            // Una lectura ya lanzada se termina siempre, aunque cambie la
            // fuente, para no dejar al arbitro esperando.
            if (sd_ack && pendiente) begin
                buf_f     <= sd_dout;
                buf_ok    <= 1'b1;
                sd_rd     <= 1'b0;
                pendiente <= 1'b0;
            end else if (!fuente && !buf_ok && !pendiente && !fin) begin
                sd_addr   <= img_base + pos;
                sd_rd     <= 1'b1;
                pendiente <= 1'b1;
            end

            if (!fuente && consume && buf_ok) begin
                buf_ok <= 1'b0;
                pos    <= pos + 1'b1;
            end
        end
    end

    //------------------------------------------------------------------
    // Fuente de audio
    //------------------------------------------------------------------
    localparam [11:0] RUIDO_US    = 12'd60;     // mas corto: se ignora
    localparam [11:0] SILENCIO_US = 12'd1500;   // mas largo: se perdio la señal
    localparam [9:0]  PILOTO_MIN  = 10'd64;     // parejas de piloto antes del inicio

    localparam A_BUSCA = 2'd0, A_BITS = 2'd1;

    reg        audio_d;
    reg [11:0] semi;              // duracion del semiperiodo en curso, en us
    reg [1:0]  a_est;
    reg        sim_ant;           // simbolo de la racha actual: 1 = corto
    reg [3:0]  racha;
    reg [9:0]  piloto;
    reg [2:0]  cortos;            // cortos acumulados dentro de un bit
    reg        largo1;            // ya llego el primer largo de un bit 0
    reg [3:0]  nbit;              // 0-7 datos, 8 y 9 parada
    reg [7:0]  sr;
    reg [7:0]  buf_a;
    reg        buf_a_ok;

    wire flanco = audio ^ audio_d;
    wire corto  = {semi, 2'b00} < {2'b00, umbral, 4'b0000};  // semi*4 < umbral*16

    // Bit completo en este ciclo, y su valor. Se calculan dentro del always
    // con asignacion bloqueante y se tratan al final de el.
    reg hecho, bval;

    always @(posedge clk) begin
        err_audio <= 1'b0;
        audio_d   <= audio;
        hecho = 1'b0;
        bval  = 1'b0;

        if (reset || limpia || !fuente) begin
            semi     <= 12'd0;
            a_est    <= A_BUSCA;
            racha    <= 4'd0;
            piloto   <= 10'd0;
            buf_a_ok <= 1'b0;
            cortos   <= 3'd0;
            largo1   <= 1'b0;
            nbit     <= 4'd0;
        end else begin
            if (consume && buf_a_ok) buf_a_ok <= 1'b0;

            if (us_tick && semi != 12'hFFF) semi <= semi + 1'b1;

            if (semi >= SILENCIO_US) begin
                // Sin señal: se abandona lo que hubiera a medias
                if (a_est == A_BITS && nbit != 4'd0) err_audio <= 1'b1;
                a_est  <= A_BUSCA;
                piloto <= 10'd0;
                racha  <= 4'd0;
            end

            if (flanco && semi >= RUIDO_US) begin
                semi <= 12'd0;

                case (a_est)
                A_BUSCA: begin
                    // El piloto son rachas de dos: LL SS LL SS... El inicio
                    // es una racha de cuatro cortos tras suficiente piloto.
                    if (racha == 4'd0 || corto != sim_ant) begin
                        if (racha == 4'd2) begin
                            if (piloto != 10'h3FF) piloto <= piloto + 1'b1;
                        end else if (racha >= 4'd3) begin
                            piloto <= 10'd0;
                        end
                        sim_ant <= corto;
                        racha   <= 4'd1;
                    end else begin
                        if (racha != 4'hF) racha <= racha + 1'b1;
                        if (corto && racha == 4'd3) begin
                            if (piloto >= PILOTO_MIN) begin
                                a_est  <= A_BITS;
                                nbit   <= 4'd0;
                                cortos <= 3'd0;
                                largo1 <= 1'b0;
                            end
                            piloto <= 10'd0;
                        end else if (!corto && racha >= 4'd2) begin
                            piloto <= 10'd0;
                        end
                    end
                end

                A_BITS: begin
                    if (corto) begin
                        if (largo1) begin
                            a_est     <= A_BUSCA;
                            err_audio <= 1'b1;
                        end else if (cortos == 3'd3) begin
                            hecho = 1'b1; bval = 1'b1;
                        end else begin
                            cortos <= cortos + 1'b1;
                        end
                    end else begin
                        if (cortos != 3'd0) begin
                            a_est     <= A_BUSCA;
                            err_audio <= 1'b1;
                        end else if (largo1) begin
                            hecho = 1'b1; bval = 1'b0;
                        end else begin
                            largo1 <= 1'b1;
                        end
                    end
                    racha <= 4'd0;
                end

                default: a_est <= A_BUSCA;
                endcase
            end

            if (hecho) begin
                cortos <= 3'd0;
                largo1 <= 1'b0;
                if (nbit < 4'd8) begin
                    sr   <= {sr[6:0], bval};
                    nbit <= nbit + 1'b1;
                end else if (nbit == 4'd8) begin
                    if (bval) begin                 // la primera de parada es 0
                        a_est     <= A_BUSCA;
                        err_audio <= 1'b1;
                    end
                    nbit <= 4'd9;
                end else begin
                    if (!bval) begin                // la segunda es 1
                        a_est     <= A_BUSCA;
                        err_audio <= 1'b1;
                    end else begin
                        buf_a    <= sr;
                        buf_a_ok <= 1'b1;
                    end
                    nbit <= 4'd0;
                end
            end
        end
    end

    assign buf_hay  = fuente ? buf_a_ok : buf_ok;
    assign buf_dato = fuente ? buf_a    : buf_f;
    assign dato     = buf_dato;
    assign hay      = buf_hay && vacio;

    //------------------------------------------------------------------
    // Grabacion: modulador
    //------------------------------------------------------------------
    localparam [11:0] SEMI_CORTO = 12'd204;
    localparam [11:0] SEMI_LARGO = 12'd408;
    localparam [11:0] PILOTO_N   = 12'd1000;

    localparam M_REPOSO = 3'd0, M_PILOTO = 3'd1, M_INICIO = 3'd2,
               M_BITS = 3'd3, M_ESPERA = 3'd4;

    reg [2:0]  m_est;
    reg [11:0] m_cnt;             // us que faltan del semiperiodo
    reg [11:0] m_pil;             // patrones de piloto que faltan
    reg [1:0]  m_semi;            // semiperiodo dentro del simbolo (0-3)
    reg [9:0]  m_sr;              // bits pendientes del byte, MSB primero
    reg [3:0]  m_nb;
    reg        m_bit;
    reg [7:0]  m_buf;
    reg        m_buf_ok;
    reg        graba_d;
    reg        pil_pend;          // hay que emitir piloto antes del proximo byte

    assign graba_listo = !m_buf_ok;

    // Duracion del semiperiodo s (0-3) del simbolo actual
    //   piloto: largo corto corto largo
    //   bit 0 : largo largo  (solo dos)
    //   bit 1 : corto corto corto corto
    function [11:0] dur(input [2:0] est, input b, input [1:0] s);
        begin
            if (est == M_PILOTO)
                dur = (s == 2'd0 || s == 2'd3) ? SEMI_LARGO : SEMI_CORTO;
            else
                dur = b ? SEMI_CORTO : SEMI_LARGO;
        end
    endfunction

    always @(posedge clk) begin
        graba_d <= graba;

        if (reset) begin
            m_est    <= M_REPOSO;
            m_buf_ok <= 1'b0;
            pil_pend <= 1'b0;
            tape_out <= 1'b0;
            m_cnt    <= 12'd0;
        end else begin
            if (graba_wr) begin
                m_buf    <= graba_dato;
                m_buf_ok <= 1'b1;
            end

            // Cada grabacion nueva empieza con su piloto. Si todavia se esta
            // modulando el ultimo byte de la anterior, se espera a que acabe:
            // cortarlo a medias dejaria un simbolo mal formado en la cinta.
            if (graba && !graba_d)
                pil_pend <= 1'b1;

            if (pil_pend && (m_est == M_REPOSO || m_est == M_ESPERA)) begin
                pil_pend <= 1'b0;
                m_est    <= M_PILOTO;
                m_pil    <= PILOTO_N;
                m_semi   <= 2'd0;
                m_cnt    <= SEMI_LARGO;
            end else if (us_tick && m_est != M_REPOSO && m_est != M_ESPERA) begin
                if (m_cnt > 12'd1) begin
                    m_cnt <= m_cnt - 1'b1;
                end else begin
                    // Fin de semiperiodo: se invierte la salida
                    tape_out <= ~tape_out;
                    m_semi   <= m_semi + 1'b1;

                    if (m_est == M_PILOTO) begin
                        if (m_semi == 2'd3) begin
                            if (m_pil == 12'd1) begin
                                m_est  <= M_INICIO;
                                m_semi <= 2'd0;
                                m_bit  <= 1'b1;
                                m_cnt  <= SEMI_CORTO;
                            end else begin
                                m_pil <= m_pil - 1'b1;
                                m_cnt <= SEMI_LARGO;
                            end
                        end else begin
                            m_cnt <= dur(M_PILOTO, 1'b0, m_semi + 1'b1);
                        end
                    end else begin
                        // Un bit se acaba tras 4 cortos o 2 largos
                        if ((m_bit && m_semi == 2'd3) || (!m_bit && m_semi == 2'd1)) begin
                            m_semi <= 2'd0;
                            if (m_est == M_BITS && m_nb != 4'd0) begin
                                m_bit <= m_sr[9];
                                m_sr  <= {m_sr[8:0], 1'b0};
                                m_nb  <= m_nb - 1'b1;
                                m_cnt <= dur(M_BITS, m_sr[9], 2'd0);
                            end else if (m_buf_ok && !pil_pend) begin
                                m_est    <= M_BITS;
                                m_bit    <= m_buf[7];
                                m_sr     <= {m_buf[6:0], 2'b01, 1'b0};
                                m_nb     <= 4'd9;
                                m_buf_ok <= graba_wr;   // si entra otro, se queda
                                m_cnt    <= dur(M_BITS, m_buf[7], 2'd0);
                            end else begin
                                m_est <= graba ? M_ESPERA : M_REPOSO;
                            end
                        end else begin
                            m_cnt <= dur(m_est, m_bit, m_semi + 1'b1);
                        end
                    end
                end
            end else if (m_est == M_ESPERA) begin
                // Hueco entre bytes: la ROM tardo en dar el siguiente. Se
                // retoma sin piloto, que es lo que esperaria el lector.
                if (m_buf_ok) begin
                    m_est    <= M_BITS;
                    m_bit    <= m_buf[7];
                    m_sr     <= {m_buf[6:0], 2'b01, 1'b0};
                    m_nb     <= 4'd9;
                    m_buf_ok <= graba_wr;
                    m_semi   <= 2'd0;
                    m_cnt    <= dur(M_BITS, m_buf[7], 2'd0);
                end else if (!graba) begin
                    m_est <= M_REPOSO;
                end
            end
        end
    end

endmodule

`default_nettype wire
