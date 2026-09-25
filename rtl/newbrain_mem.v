//============================================================================
// NewBrain - decodificacion de memoria
//
//   0000-7FFF  RAM 32K
//   8000-9FFF  vacio, o la ROM de la controladora de disco si esta presente
//   A000-BFFF  ROM banco 0   (AB)
//   C000-DFFF  ROM banco 1   (CD)
//   E000-FFFF  ROM banco 2   (EF)
//
// Mientras PWRUP esta bajo, TODO el espacio se fuerza al banco 2, de modo
// que el Z80 arranca en 0000 ejecutando la ROM alta. Ver doc/01-hardware.md
//
// romov/exrm/raminh son las senales del conector de expansion. Con romov=1,
// raminh=0 el decodificado es el interno; quedan expuestas para cuando se
// implemente la paginacion del EIM.
//
// El hueco de 8000 no es casual: es donde la controladora de disco pone sus
// 8K de ROM (la d413). La ROM del sistema comprueba al arrancar si hay algo
// ahi y, si lo encuentra, salta a 8001 y cede el control. Ver
// doc/06-expansion.md
//============================================================================
`default_nettype none

module newbrain_mem (
    input  wire [15:0] addr,
    input  wire        pwrup,

    input  wire        romov,     // 1 = decodificado interno
    input  wire [2:0]  exrm,      // bloque suministrado por la expansion
    input  wire        raminh,    // 1 = la expansion inhibe la RAM interna
    input  wire        disc_rom,  // 1 = hay ROM de controladora de disco en 8000
    input  wire        eim,       // 1 = modulo de expansion presente

    // paginacion del modulo de expansion
    input  wire        paging_on,
    input  wire [7:0]  page,
    input  wire        page_ok,   // 0: ranura sin asignar (lee FF)
    input  wire [1:0]  ram_size,  // 0:32K 1:96K 2:512K 3:768K

    output wire        ram_cs,
    output wire [14:0] ram_addr,
    output wire        rom_cs,
    output wire [15:0] rom_addr,

    output wire [20:0] ram_phys,  // direccion dentro del espacio fisico de RAM
    output wire        ram_oor    // 1 = por encima de la RAM instalada
);

    // Bloque de 8K seleccionado
    wire [2:0] blk = pwrup ? (romov ? addr[15:13] : exrm) : 3'd7;

    // A15 del bloque: 0 => RAM interna
    wire a15g = blk[2];

    wire base_ram_cs = ~a15g & ~raminh;
    assign ram_addr  = addr[14:0];

    // blk 5/6/7 -> bancos ROM 0/1/2 (A000, C000, E000).
    // blk 4 -> banco 3, la ROM de disco en 8000, solo si esta presente.
    //------------------------------------------------------------------
    // Sin paginacion
    //------------------------------------------------------------------
    // 8000-9FFF: con modulo de expansion, su ROM del sistema paginado (POS);
    // si no, la ROM de la controladora de disco, si la hay. La ROM AB mira
    // en 8000 al arrancar y, si encuentra algo, lo ejecuta: sin la POS ahi
    // el sistema paginado no llegaria a arrancar nunca.
    wire in_disc = a15g & (blk[1:0] == 2'b00);
    wire base_rom_cs = a15g & ((blk[1:0] != 2'b00) | disc_rom | eim);
    wire [2:0] base_bank = in_disc ? (eim ? 3'd4 : 3'd3)
                                   : {1'b0, (blk[1:0] - 2'd1)};

    //------------------------------------------------------------------
    // Con paginacion: numeracion de paginas
    //
    // Es la del emulador de cdesp, que arranca el sistema paginado con las
    // ROMs originales, y va AL REVES de lo que uno supondria:
    //
    //   RAM interna   0000 -> 107   2000 -> 106   4000 -> 105   6000 -> 104
    //   ROM           A000 -> 122   C000 -> 121   E000 -> 120
    //                 8000 -> 123 (POS con expansion, d413 sin ella)
    //                 124 MTV, 125 ACI
    //   RAM del modulo de expansion: 103 hacia abajo
    //
    // Antes estaba al derecho (pagina 0 en 0000, 120 = AB): al encender la
    // paginacion, el sistema paginado se encontraba otra memoria debajo y
    // la ROM EF en el sitio de la AB.
    //------------------------------------------------------------------
    // Con el modulo de expansion, la ROM de disco del NewBrain vive en la
    // pagina 119 (la 123 es del sistema paginado). El menu del sistema
    // paginado la encuentra ahi y ofrece "CP/M 2.2". Como en cdesp.
    wire pg_disco  = eim & disc_rom & (page == 8'd119);
    wire pg_is_rom = ((page >= 8'd120) && (page <= (eim ? 8'd125 : 8'd123))) | pg_disco;
    wire [2:0] pg_bank = pg_disco         ? 3'd3 :       // ROM de disco
                         (page == 8'd122) ? 3'd0 :       // AB
                         (page == 8'd121) ? 3'd1 :       // CD
                         (page == 8'd120) ? 3'd2 :       // EF
                         (page == 8'd123) ? (eim ? 3'd4 : 3'd3) :
                         (page == 8'd124) ? 3'd5 : 3'd6;

    // RAM: indice fisico = 107 - pagina (modulo 256). Deja la RAM interna
    // (107..104) en los primeros 32K, que es donde esta sin paginar y donde
    // la lee el video, y la del modulo (103, 102...) justo detras. Es una
    // biyeccion, asi que con 2 MB caben las 256 paginas.
    wire [7:0] pg_idx = {1'b0, 7'd107 - page[6:0]};

    assign rom_cs   = paging_on ? (page_ok &  pg_is_rom) : base_rom_cs;
    assign ram_cs   = paging_on ? (page_ok & ~pg_is_rom) : base_ram_cs;
    assign rom_addr = {(paging_on ? pg_bank : base_bank), addr[12:0]};
    assign ram_phys = paging_on ? {pg_idx, addr[12:0]} : {6'd0, addr[14:0]};
    // RAM instalada, en paginas contadas desde la 107 hacia abajo. El
    // maximo que arranca el sistema paginado esta entre 768K y 864K: con
    // mas, su ROM llega a probar la pagina 0 y se lia (medido con
    // tools/nbpag.py). 96K es lo que traia el modulo de expansion.
    wire [20:0] size_mask = (ram_size == 2'd0) ? 21'h007FFF :   // 32K
                            (ram_size == 2'd1) ? 21'h017FFF :   // 96K (12 paginas)
                            (ram_size == 2'd2) ? 21'h07FFFF :   // 512K
                                                 21'h0BFFFF;    // 768K (96 paginas)
    assign ram_oor = (ram_phys > size_mask) | (paging_on & ~page_ok);

endmodule

`default_nettype wire
