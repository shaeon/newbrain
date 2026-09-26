//============================================================================
// NewBrain - generador de imagen
//
// Temporizacion, deducida del cristal de 16 MHz y confirmada por el Apendice F:
//   punto 16 MHz, 1024 puntos por linea, 312 lineas
//   -> 15,625 kHz horizontal, 50,08 Hz vertical, 640 puntos activos
//
// Direccion de pantalla: la CPU escribe el puerto 09 con los 8 bits altos de
// un contador de 9 bits en unidades de 64 bytes, y el puerto 08 pone el bit
// que falta. Confirmado en E1FD de la ROM EF y en el Apendice F.
//
// Registro de modo (puerto 0C):
//   b0 video inverso global
//   b1 uno: 256 caracteres. cero: 128 mas 128 en campo inverso
//   b2 uno: 256 o 512 puntos horizontales. cero: 320 o 640
//   b3 uno: matriz 8x8, hasta 31 lineas. cero: 8x10, hasta 25
//   b6 uno: 80 columnas, EL=128. cero: 40 columnas, EL=64
//
// Recorrido: cada fila de caracteres empieza en base + fila*EL. Dentro de la
// fila, un byte 0 deja en blanco lo que queda. Cuatro bytes 00 00 20 20 o
// 00 00 00 00 marcan el final del texto y el comienzo de los graficos.
//
// La RAM vive en SDRAM, asi que no se puede leer un byte por celda: en 80
// columnas eso deja 16 ciclos de sistema por acceso, con la CPU y el refresco
// compitiendo por el mismo camino. En vez de eso se llena un **buffer de
// linea** en rafaga durante el borrado horizontal, y el barrido activo lee de
// ese buffer, que es block RAM y responde en un ciclo.
//
// Cabe de sobra: 40 palabras a 7 ciclos son 280 de los 768 que dura el
// borrado horizontal. Y de paso es lo que hacia la maquina real, que le
// robaba ciclos de DRAM a la CPU para pintar.
//
// Ver doc/04-video.md
//============================================================================
`default_nettype none

module newbrain_video #(
    parameter H_TOTAL  = 1024,
    parameter H_ACTIVE = 640,
    parameter H_SYNC   = 76,
    parameter [10:0] H_START = 230,
    parameter V_TOTAL  = 312,
    parameter V_ACTIVE = 250,
    parameter V_SYNC   = 3,
    parameter V_START  = 33,
    parameter [15:0] START_OFS_80 = 4,
    parameter [15:0] START_OFS_40 = 2
) (
    input  wire        clk,           // sistema: relleno contra la SDRAM
    input  wire        clk_pix,       // pixel: barrido y salida
    input  wire        ce_pix,        // en clk_pix: 16 MHz (Original) o 13,5 (Wide)
    input  wire        reset,
    input  wire        ancho,         // 1: Wide, linea de 864 puntos a 13,5 MHz

    input  wire        tv_enable_in,
    input  wire signed [7:0] h_off,   // centrado horizontal, en puntos
    input  wire signed [7:0] v_off,   // centrado vertical, en lineas
    input  wire [15:0] tv_addr_in,
    input  wire [7:0]  tvtl_in,

    // rafaga contra la SDRAM
    output reg  [23:0] sd_addr,
    output reg         sd_rd,
    input  wire [15:0] sd_dout,
    input  wire        sd_ack,
    input  wire [23:0] ram_base,      // donde empieza la RAM en la SDRAM

    // generador de caracteres
    output wire [7:0]  cg_char,
    output wire [3:0]  cg_line,
    input  wire [7:0]  cg_data,

    output reg  [7:0]  R,
    output reg  [7:0]  G,
    output reg  [7:0]  B,
    // Sincronismos activos a nivel BAJO, como los de los demas cores y como
    // los espera mist_video: su scandoubler empieza la linea en el flanco de
    // bajada de la hsync, y a 31 kHz el 720x576 de 50 Hz (el modo Wide) va
    // con las dos negativas. Con los pulsos positivos el scandoubler tomaba
    // el final del pulso por el principio de la linea y el monitor recibia
    // una polaridad que no es la del modo.
    output reg         hsync,
    output reg         hsync_cs,      // hsync para el sincronismo compuesto
    output reg         vsync,
    output reg         hblank,
    output reg         vblank,
    output reg         vsync_pulse
);
    //------------------------------------------------------------------
    // Modo
    //------------------------------------------------------------------
    //------------------------------------------------------------------
    // Dos dominios de reloj. El relleno del buffer de linea va con el
    // sistema (clk), que es el de la SDRAM; el barrido, con el reloj de pixel
    // (clk_pix), que puede ser otro: 32 MHz en Original y 27 MHz en Wide.
    // Se comunican por fill_tog (conmutador, sincronizado en clk) y por el
    // buffer de linea, que es una memoria de doble reloj. Los registros del
    // NewBrain que llegan aqui cambian muy de tarde en tarde y se pasan por
    // dos biestables.
    //------------------------------------------------------------------
    reg [1:0]  rst_s;
    reg [7:0]  tvtl_1, tvtl;
    reg [15:0] tva_1, tv_addr;
    reg [1:0]  ten_s, anc_s;
    always @(posedge clk_pix) begin
        rst_s  <= {rst_s[0], reset};
        tvtl_1 <= tvtl_in;  tvtl    <= tvtl_1;
        tva_1  <= tv_addr_in; tv_addr <= tva_1;
        ten_s  <= {ten_s[0], tv_enable_in};
        anc_s  <= {anc_s[0], ancho};
    end
    wire reset_p   = rst_s[1];
    wire tv_enable = ten_s[1];

    // Parametros de linea. Original: los del modulo (1024 a 16 MHz). Wide:
    // 864 a 13,5 MHz, que son los mismos 64 us; los 640 puntos activos
    // ocupan 47,4 us en vez de 40 y llenan el ancho como en los emuladores.
    // La zona activa se centra en el mismo instante de la linea.
    wire [10:0] h_total = anc_s[1] ? 11'd864 : H_TOTAL[10:0];
    wire [10:0] h_sync  = anc_s[1] ? 11'd64  : H_SYNC[10:0];
    wire [10:0] h_start = anc_s[1] ? 11'd144 : H_START;

    wire rev_all  = tvtl[0];
    wire full_set = tvtl[1];
    wire short_ch = tvtl[3];
    wire wide80   = tvtl[6];

    wire estrecha = tvtl[2];

    wire [7:0] el       = wide80 ? 8'd128 : 8'd64;
    wire [6:0] line_len = wide80 ? 7'd80  : 7'd40;

    //------------------------------------------------------------------
    // Zona grafica: bytes por LINEA DE BARRIDO
    //
    // No es EL. Los graficos van empaquetados, sin los bytes de sobra que
    // el sistema operativo se reserva en las filas de texto: cada linea
    // ocupa exactamente ancho/8 bytes y la siguiente empieza justo detras.
    //
    //   80 columnas  640 puntos  80 bytes   (estrecha: 512 -> 64)
    //   40 columnas  320 puntos  40 bytes   (estrecha: 256 -> 32)
    //
    // Medido contra la propia maquina: con la pantalla abierta como
    // "l110" y los graficos como "w150", PEN(7) = 2596, PEN(8) = 14596 y
    // PEN(9) = 640, o sea 12000 bytes para 150 lineas = 80 por linea. Y el
    // hueco entre el terminador de texto y PEN(7) mide 800 bytes = 10
    // lineas de 80, que son justo las 10 que el sistema deja de margen:
    // 9 filas de texto x 10 + 160 lineas graficas = las 250 visibles.
    //
    // Antes se avanzaba EL (128) por linea y la imagen salia desplazada y
    // repetida en diagonal.
    //------------------------------------------------------------------
    wire [6:0] gfx_len  = wide80 ? (estrecha ? 7'd64 : 7'd80)
                                 : (estrecha ? 7'd32 : 7'd40);

    // Con la pantalla estrecha la imagen va CENTRADA: 64 puntos en blanco a
    // cada lado. Son 8 bytes en 80 columnas y 4 en 40, porque alli cada
    // punto se pinta doble. Medido contra la maquina: con los graficos
    // abiertos como "n180" sobre una pantalla "l100", PEN(7) cae 8 bytes
    // despues del comienzo de la fila del terminador, y una linea dibujada
    // en x=0 aparece en el bit 0 de ese byte mientras que la de x=511 cae en
    // el bit 7 del byte 63 de la fila anterior.
    wire [6:0] gfx_hueco = estrecha ? (wide80 ? 7'd8 : 7'd4) : 7'd0;
    wire [3:0] char_h   = short_ch ? 4'd8 : 4'd10;
    wire [3:0] cellmask = wide80 ? 4'd7 : 4'd15;

    // Comienzo efectivo de la zona activa, con el ajuste del OSD
    wire [10:0] hs_eff = h_start + {{3{h_off[7]}}, h_off};
    wire [9:0]  vs_eff = V_START + {{2{v_off[7]}}, v_off};

    wire [10:0] win_start = hs_eff - (wide80 ? 11'd10 : 11'd18);
    wire [15:0] start_ofs = wide80 ? START_OFS_80 : START_OFS_40;

    //------------------------------------------------------------------
    // Contadores de barrido
    //------------------------------------------------------------------
    reg [10:0] hcnt;
    reg [9:0]  vcnt;
    reg [3:0]  cellpix;
    reg [6:0]  col;
    reg        in_win;
    reg [3:0]  char_line;
    reg [15:0] line_base;
    reg        gfx_mode;
    reg        pantalla_fin;
    reg        primera_gfx;
    reg [15:0] gfx_base;
    reg        eol;
    reg [7:0]  t0, t1, t2;
    reg [7:0]  ch_latch;
    reg        rev_latch;
    reg [7:0]  shifter;
    reg        shift_rev;

    //------------------------------------------------------------------
    // Buffer de linea: 64 palabras = 128 bytes, el EL mayor
    //------------------------------------------------------------------
    reg [15:0] lbuf [0:63];
    reg [5:0]  lb_raddr;
    reg        lb_bytesel;
    reg [15:0] lb_rdata;

    always @(posedge clk_pix) lb_rdata <= lbuf[lb_raddr];
    wire [7:0] ram_data = lb_bytesel ? lb_rdata[15:8] : lb_rdata[7:0];

    assign cg_char = (!full_set && ch_latch[7]) ? {1'b0, ch_latch[6:0]} : ch_latch;

    // En la zona grafica el bit 0 es el punto de la IZQUIERDA, al reves que
    // en el generador de caracteres. Se ve en el mismo experimento: la linea
    // de x=0 enciende el bit 0 del primer byte y la de x=511 el bit 7 del
    // ultimo. Pintandolo al reves los textos que los programas dibujan sobre
    // los graficos salian en espejo.
    function [7:0] voltea(input [7:0] b);
        voltea = {b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7]};
    endfunction
    //------------------------------------------------------------------
    // Generador de caracteres y descendentes
    //
    // Cada glifo ocupa 8 filas de la EPROM, pero la celda es de 10 lineas.
    // Las dos que faltan son el descendente, y estan guardadas en las filas
    // **0 y 1**, marcadas con el bit 0 puesto. El bit 0 es la columna de
    // separacion entre caracteres, que ningun glifo usa en esas dos filas, o
    // sea que sale gratis como marca.
    //
    // Los caracteres marcados son exactamente , ; _ g j p q y, que son justo
    // los que bajan de la linea base.
    //
    // La regla es por fila y no necesita mirar el glifo entero:
    //
    //   lineas 0 y 1  -> filas 0 y 1, en blanco si llevan la marca
    //   lineas 2 a 7  -> filas 2 a 7 tal cual
    //   lineas 8 y 9  -> filas 0 y 1 SOLO si llevan la marca, y sin el bit 0
    //
    // Ver doc/04-video.md
    //------------------------------------------------------------------
    wire linea_alta = (char_line < 4'd2);
    wire linea_baja = (char_line >= 4'd8);
    wire marca_desc = cg_data[0];

    assign cg_line = linea_baja ? {3'd0, char_line[0]}
                                : {1'b0, char_line[2:0]};

    wire [7:0] patron = linea_baja ? (marca_desc ? (cg_data & 8'hFE) : 8'h00)
                      : linea_alta ? (marca_desc ? 8'h00 : cg_data)
                                   : cg_data;

    //------------------------------------------------------------------
    // Relleno del buffer durante el borrado horizontal
    //------------------------------------------------------------------
    // Ojo: fstate y fidx los escribe SOLO este bloque. El barrido, que va en
    // el dominio de ce_pix, no puede tocarlos o serian dos excitadores del
    // mismo registro: Icarus lo deja pasar, Quartus lo rechaza y con razon.
    // El arranque de la rafaga se comunica conmutando fill_tog.
    localparam F_IDLE = 2'd0, F_REQ = 2'd1, F_WAIT = 2'd2;
    reg [1:0] fstate;
    reg [6:0] fidx;
    reg [6:0] fwords;
    reg       fill_tog, fill_tog_d;
    reg [2:0] fill_s;                 // fill_tog en el dominio del sistema
    reg [23:0] fill_base;
    reg [6:0]  fill_n;

    always @(posedge clk) begin
        sd_rd <= 1'b0;
        if (reset) begin
            fstate     <= F_IDLE;
            fidx       <= 7'd0;
            fill_tog_d <= 1'b0;
            fill_s     <= 3'b000;
        end else begin
            fill_s     <= {fill_s[1:0], fill_tog};
            fill_tog_d <= fill_s[2];

            // line_base y fwords los deja fijos el barrido antes de conmutar
            // fill_tog y no los vuelve a tocar hasta el final de la linea
            // siguiente: se pueden coger aqui sin mas.
            if (fill_s[2] != fill_tog_d) begin
                fidx      <= 7'd0;
                fill_base <= ram_base + {8'd0, line_base};
                fill_n    <= fwords;
                fstate    <= F_REQ;
            end else
            case (fstate)
            F_IDLE: ;
            F_REQ: begin
                sd_addr <= fill_base + {16'd0, fidx, 1'b0};
                sd_rd   <= 1'b1;
                fstate  <= F_WAIT;
            end
            F_WAIT: if (sd_ack) begin
                lbuf[fidx[5:0]] <= sd_dout;
                if (fidx == fill_n - 1) fstate <= F_IDLE;
                else begin
                    fidx   <= fidx + 1'b1;
                    fstate <= F_REQ;
                end
            end
            default: fstate <= F_IDLE;
            endcase
        end
    end

    //------------------------------------------------------------------
    wire last_pix = (cellpix == cellmask);

    // Fila dentro de la zona activa de la pantalla
    wire fila_visible = (vcnt >= vs_eff) && (vcnt < vs_eff + V_ACTIVE);

    // Celda que toca leer del buffer y si cae dentro de la imagen.
    //
    // El hueco de la pantalla estrecha se salta UNA sola vez: en la primera
    // linea de la zona grafica esos 8 bytes todavia se leen (valen cero, o
    // sea que no se ven) y a partir de la segunda la fila ya empieza en el
    // primer byte de la imagen, que es lo que apunta PEN(7).
    wire [6:0] hueco_ef = (gfx_mode && !primera_gfx) ? gfx_hueco : 7'd0;
    wire [6:0] len_ef   = gfx_len + gfx_hueco - hueco_ef;
    wire [6:0] col_buf   = gfx_mode ? (col - hueco_ef) : col;
    wire       gfx_dentro = (col >= hueco_ef) && (col < hueco_ef + len_ef);

    // El pixel que se calcula ahora sale por R en el ciclo siguiente, asi que
    // el blanqueo se evalua sobre la posicion siguiente y todo queda alineado.
    wire [10:0] hn = (hcnt == h_total - 1) ? 11'd0 : hcnt + 11'd1;
    wire [9:0]  vn = (hcnt == h_total - 1)
                     ? ((vcnt == V_TOTAL - 1) ? 10'd0 : vcnt + 10'd1)
                     : vcnt;
    wire hb_n = (hn < hs_eff) || (hn >= hs_eff + H_ACTIVE);
    wire vb_n = (vn < vs_eff) || (vn >= vs_eff + V_ACTIVE);
    wire visible = ~hb_n & ~vb_n & tv_enable;
    wire pix = visible & ~pantalla_fin
             & (shifter[7] ^ (gfx_mode ? 1'b0 : shift_rev) ^ rev_all);

    always @(posedge clk_pix) begin
        vsync_pulse <= 1'b0;

        if (reset_p) begin
            hcnt      <= 0;
            vcnt      <= 0;
            char_line <= 0;
            line_base <= 16'd0;
            gfx_mode  <= 1'b0;
            pantalla_fin <= 1'b0;
            primera_gfx <= 1'b1;
            shifter   <= 8'h00;
            in_win    <= 1'b0;
            fill_tog  <= 1'b0;
        end else if (ce_pix) begin
            //--------------------------------------------------------------
            // Barrido
            //--------------------------------------------------------------
            if (hcnt == h_total - 1) begin
                hcnt <= 0;
                if (vcnt == V_TOTAL - 1) begin
                    vcnt        <= 0;
                    vsync_pulse <= 1'b1;
                    char_line   <= 0;
                    line_base   <= tv_addr + start_ofs;
                    gfx_mode    <= 1'b0;
                    pantalla_fin <= 1'b0;
                    primera_gfx <= 1'b1;
                end else begin
                    vcnt <= vcnt + 1'b1;
                end
            end else begin
                hcnt <= hcnt + 1'b1;
            end

            hsync  <= ~(hn < h_sync);
            vsync  <= ~(vn < V_SYNC);

            // Para el sincronismo compuesto, que mist_video forma como
            // ~(hsync ^ vsync): durante la vsync el pulso va al FINAL de la
            // linea. Asi el XOR da los pulsos anchos de PAL, con la muesca
            // al final, y el flanco de bajada sigue cayendo al principio de
            // cada linea. Con la hsync normal esos flancos llegaban 4,75 us
            // tarde en las lineas de vsync y uno se perdia: el monitor
            // contaba 311 lineas por trama y marcaba 50,29 Hz en vez de 50,08.
            // La maquina real hacia el mismo XOR (un 74LS86), pero iba a una
            // tele, que no se fija en eso.
            // Con las dos a nivel bajo el XOR da lo mismo que con las dos a
            // nivel alto.
            hsync_cs <= ~((vn < V_SYNC) ? (hn >= h_total - h_sync) : (hn < h_sync));
            hblank <= hb_n;
            vblank <= vb_n;

            //--------------------------------------------------------------
            // Al empezar el borrado horizontal: avanzar la fila y rellenar el
            // buffer con la linea que toca pintar a continuacion.
            //--------------------------------------------------------------
            if (hcnt == hs_eff + H_ACTIVE) begin
                // Con vs_eff y no con V_START: si no, al mover la imagen con
                // el ajuste vertical del OSD las filas empezaban a avanzar
                // antes o despues de la primera linea visible, y cada fila
                // salia cortada o con su primera linea repetida.
                if (vcnt >= vs_eff) begin
                    if (gfx_mode) begin
                        line_base   <= line_base + {1'd0, len_ef};
                        primera_gfx <= 1'b0;
                    end else if (char_line == char_h - 1) begin
                        char_line <= 0;
                        line_base <= line_base + {8'd0, el};
                    end else begin
                        char_line <= char_line + 1'b1;
                    end
                end
                fwords   <= {1'b0, line_len[6:1]} + {6'd0, line_len[0]};
                fill_tog <= ~fill_tog;
            end

            //--------------------------------------------------------------
            // Ventana de caracteres
            //--------------------------------------------------------------
            if (hcnt == win_start) begin
                in_win  <= 1'b1;
                cellpix <= 0;
                col     <= 0;
                eol     <= 1'b0;
            end else if (hcnt >= hs_eff + H_ACTIVE) begin
                in_win <= 1'b0;
            end else if (in_win) begin
                if (last_pix) begin
                    cellpix   <= 0;
                    col       <= col + 1'b1;
                    shifter   <= gfx_mode ? (gfx_dentro ? voltea(ch_latch) : 8'h00)
                                          : patron;
                    shift_rev <= rev_latch;
                end else begin
                    cellpix <= cellpix + 1'b1;
                    if (wide80 || cellpix[0]) shifter <= {shifter[6:0], 1'b0};
                end
            end

            //--------------------------------------------------------------
            // Captacion desde el buffer de linea
            //--------------------------------------------------------------
            if (in_win) begin
                case (cellpix)
                0: begin
                       lb_raddr   <= col_buf[6:1];
                       lb_bytesel <= col_buf[0];
                   end
                2: begin
                       if (gfx_mode) begin
                           ch_latch  <= ram_data;
                           rev_latch <= 1'b0;
                       end else if (eol || (ram_data == 8'h00)) begin
                           ch_latch  <= 8'h20;
                           rev_latch <= 1'b0;
                           if (ram_data == 8'h00) eol <= 1'b1;
                       end else begin
                           ch_latch  <= ram_data;
                           rev_latch <= ~full_set & ram_data[7];
                       end

                       // La deteccion del terminador solo vale dentro de la
                       // zona activa. Durante el borrado vertical el buffer
                       // de linea todavia lleva lo ultimo que se leyo en la
                       // trama anterior, y si eran ceros (zona grafica, o la
                       // maquina recien arrancada) se daba el terminador por
                       // bueno y la trama entera se pintaba como graficos.
                       // Como el fallo se realimentaba trama a trama, bastaba
                       // con que colara una vez.
                       if (!gfx_mode && char_line == 0 && fila_visible) begin
                           if (col == 0) t0 <= ram_data;
                           if (col == 1) t1 <= ram_data;
                           if (col == 2) t2 <= ram_data;
                           if (col == 3) begin
                               // 00 00 20 20 NO es el comienzo de los
                               // graficos: es el final de la pantalla, y lo
                               // que queda por debajo va en blanco. Es lo que
                               // el sistema deja detras del texto al
                               // arrancar, y tomarlo por graficos pintaba una
                               // fila de basura abajo del todo.
                               if (t0 == 8'h00 && t1 == 8'h00 &&
                                   t2 == 8'h20 && ram_data == 8'h20)
                                   pantalla_fin <= 1'b1;

                               if (t0 == 8'h00 && t1 == 8'h00 &&
                                   t2 == 8'h00 && ram_data == 8'h00) begin
                                   // Los graficos empiezan EN ESTA MISMA
                                   // fila, no en la siguiente. Se ve en las
                                   // cuentas de la maquina: 9 filas de texto
                                   // x 10 lineas + 160 lineas graficas son
                                   // las 250 visibles, sin sitio para una
                                   // fila de texto de mas. Y los cuatro
                                   // bytes del terminador son parte de los
                                   // graficos: valen cero, o sea que no se
                                   // ven. Esperar al final de la fila hacia
                                   // que la primera linea de la imagen
                                   // saliera como caracteres sueltos.
                                   gfx_base  <= line_base;
                                   gfx_mode  <= 1'b1;
                               end
                           end
                       end
                   end
                endcase
            end

            //--------------------------------------------------------------
            R <= pix ? 8'hFF : 8'h00;
            G <= pix ? 8'hFF : 8'h00;
            B <= pix ? 8'hFF : 8'h00;
        end
    end
endmodule

`default_nettype wire
