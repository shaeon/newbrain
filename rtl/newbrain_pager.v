//============================================================================
// NewBrain - paginacion del modulo de expansion
//
// Especificado en el Apendice F del Manual Tecnico de Software de Grundy.
// Esto no es ingenieria inversa: son los registros tal y como los documento
// el fabricante. Ver doc/07-paginacion.md
//
// PUERTO 2 (W, EI) - carga de los registros de pagina
//
//   Hay DIECISEIS registros de 8 bits. Cual se escribe lo elige la parte
//   ALTA de la direccion de E/S, no el dato:
//
//       indice = {A12, A15, A14, A13}     (de mas a menos significativo)
//
//   {A15,A14,A13} es justo la ranura de 8K a la que afecta, y A12 elige el
//   juego de registros. El valor cargado tambien mezcla direccion y dato, y
//   va TODO INVERTIDO:
//
//       pagina = ~{A11, D6, D5, D4, D3, D2, D1, D0}
//
//   D7 no se usa. Con 8 bits de pagina y paginas de 8K salen 2 MB.
//
// PUERTO 255 (W, EI/DC/NC) - registro de estado de paginacion
//
//   Cada modulo tiene el suyo; se elige por la parte alta de la direccion:
//   A8 para el modulo de expansion, A9 para la controladora de disco, A10
//   para la de red.
//
//       D0  uno habilita los circuitos de paginacion
//       D1  sin usar
//       D2  uno pone A16 local a uno, o sea activa el SEGUNDO juego de ocho
//           registros
//       D3  cero selecciona modo multiproceso, que entre otras cosas alarga
//           los registros de pagina de 8 a 12 bits
//       D4  uno aisla la maquina local (modo multiproceso)
//============================================================================
`default_nettype none

module newbrain_pager (
    input  wire        clk,
    input  wire        reset,
    input  wire        present,        // hay modulo de expansion

    // bus de E/S
    input  wire [15:0] io_addr,
    input  wire [7:0]  io_data,
    input  wire        io_wr,

    // consulta desde el decodificado de memoria
    input  wire [15:0] cpu_addr,
    output wire        paging_on,
    output wire [7:0]  page,
    output wire        page_ok,        // 0: ranura vacia, lee FF
    output wire [20:0] phys_addr,

    // Segundo puerto de consulta, para la controladora de disco, que
    // accede al bus con su propio A16 (el bit MA16 de su registro de
    // control) y no con el de la CPU
    input  wire [15:0] fdc_addr,
    input  wire        fdc_a16,
    output wire [7:0]  fdc_page,
    output wire        fdc_page_ok,

    // estado, para depuracion y para el resto del sistema
    output reg         a16,
    output reg         multiproc,
    output reg         isolated
);
    //------------------------------------------------------------------
    // Registros de pagina
    //
    // Valor: el byte de datos TAL CUAL, 7 bits. No va invertido ni lleva
    // A11, como habiamos leido en el Apendice F: la ROM del sistema
    // paginado escribe 7Bh (123) para poner su propia pagina, y el
    // emulador de cdesp, que arranca con las ROMs originales, usa el dato
    // sin tocar. Con el valor invertido la ROM se paginaba a si misma fuera.
    //
    // Arranque: el juego principal con el mapa natural (107, 106, 105, 104
    // la RAM interna, 123 la ROM de 8000, 122..120 las ROMs AB/CD/EF) y el
    // segundo juego VACIO, que lee FF. La ROM del sistema paginado solo
    // escribe las ranuras que cambia y da por hecho las demas.
    //------------------------------------------------------------------
    reg [6:0] pagereg [0:15];
    reg [15:0] valida;
    reg       enabled;
    integer   i;

    wire sel_pagereg = present & io_wr & (io_addr[7:0] == 8'd2);
    wire sel_status  = present & io_wr & (io_addr[7:0] == 8'd255) & io_addr[8];

    wire [3:0] wr_index = {io_addr[12], io_addr[15], io_addr[14], io_addr[13]};
    wire [3:0] rd_index = {a16, cpu_addr[15:13]};

    assign page      = {1'b0, pagereg[rd_index]};
    assign page_ok   = valida[rd_index];
    wire [3:0] fdc_index = {fdc_a16, fdc_addr[15:13]};
    assign fdc_page    = {1'b0, pagereg[fdc_index]};
    assign fdc_page_ok = valida[fdc_index];
    assign paging_on = enabled & present;
    assign phys_addr = {page, cpu_addr[12:0]};

    function [6:0] natural(input [2:0] ranura);
        case (ranura)
        3'd0: natural = 7'd107;  3'd1: natural = 7'd106;
        3'd2: natural = 7'd105;  3'd3: natural = 7'd104;
        3'd4: natural = 7'd123;  3'd5: natural = 7'd122;
        3'd6: natural = 7'd121;  default: natural = 7'd120;
        endcase
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1)
                pagereg[i] <= natural(i[2:0]);
            valida    <= 16'h00FF;          // el juego alternativo, vacio
            enabled   <= 1'b0;
            a16       <= 1'b0;
            multiproc <= 1'b0;
            isolated  <= 1'b0;
        end else begin
            if (sel_pagereg) begin
                pagereg[wr_index] <= io_data[6:0];
                valida[wr_index]  <= 1'b1;
            end
            if (sel_status) begin
                enabled   <= io_data[0];
                a16       <= io_data[2];
                multiproc <= ~io_data[3];
                isolated  <= io_data[4];
            end
        end
    end
endmodule

`default_nettype wire
