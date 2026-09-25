`timescale 1ns/1ps
module tb_newbrain_mem;
    reg  [15:0] addr;
    reg         pwrup;
    reg         disc_rom = 1'b0;
    reg         paging_on = 1'b0;
    reg [7:0]   page = 8'd0;
    reg         page_ok = 1'b1;
    reg [1:0]   ram_size = 2'd0;
    wire [20:0] ram_phys;
    wire        ram_oor;
    wire        ram_cs, rom_cs;
    wire [14:0] ram_addr;
    wire [15:0] rom_addr;
    reg         eim = 1'b0;
    integer errors = 0;

    newbrain_mem dut (
        .addr(addr), .pwrup(pwrup),
        .romov(1'b1), .exrm(3'd0), .raminh(1'b0), .disc_rom(disc_rom), .eim(eim),
        .paging_on(paging_on), .page(page), .page_ok(page_ok), .ram_size(ram_size),
        .ram_phys(ram_phys), .ram_oor(ram_oor),
        .ram_cs(ram_cs), .ram_addr(ram_addr),
        .rom_cs(rom_cs), .rom_addr(rom_addr)
    );

    task check;
        input [15:0] a;
        input        pu;
        input        exp_ram;
        input        exp_rom;
        input [15:0] exp_addr;
        begin
            addr = a; pwrup = pu; #1;
            if (ram_cs !== exp_ram || rom_cs !== exp_rom ||
                (exp_rom && rom_addr !== exp_addr) ||
                (exp_ram && {1'b0, ram_addr} !== exp_addr)) begin
                $display("FAIL addr=%04h pwrup=%b -> ram_cs=%b rom_cs=%b addr=%04h (esperado ram=%b rom=%b addr=%04h)",
                         a, pu, ram_cs, rom_cs,
                         exp_rom ? rom_addr : {1'b0, ram_addr},
                         exp_ram, exp_rom, exp_addr);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $display("-- mapa de memoria con PWRUP alto --");
        check(16'h0000, 1'b1, 1'b1, 1'b0, 16'h0000);  // RAM
        check(16'h4321, 1'b1, 1'b1, 1'b0, 16'h4321);  // RAM
        check(16'h7FFF, 1'b1, 1'b1, 1'b0, 16'h7FFF);  // RAM ultimo byte
        check(16'h8000, 1'b1, 1'b0, 1'b0, 16'h0000);  // hueco
        check(16'h9FFF, 1'b1, 1'b0, 1'b0, 16'h0000);  // hueco
        check(16'hA000, 1'b1, 1'b0, 1'b1, 16'h0000);  // ROM banco 0
        check(16'hBFFF, 1'b1, 1'b0, 1'b1, 16'h1FFF);
        check(16'hC000, 1'b1, 1'b0, 1'b1, 16'h2000);  // ROM banco 1
        check(16'hDFFF, 1'b1, 1'b0, 1'b1, 16'h3FFF);
        check(16'hE000, 1'b1, 1'b0, 1'b1, 16'h4000);  // ROM banco 2
        check(16'hFFFF, 1'b1, 1'b0, 1'b1, 16'h5FFF);

        $display("-- con PWRUP bajo todo el espacio es ROM banco 2 --");
        check(16'h0000, 1'b0, 1'b0, 1'b1, 16'h4000);  // el Z80 arranca aqui
        check(16'h0066, 1'b0, 1'b0, 1'b1, 16'h4066);
        check(16'h1FFF, 1'b0, 1'b0, 1'b1, 16'h5FFF);
        check(16'h2000, 1'b0, 1'b0, 1'b1, 16'h4000);  // espejo cada 8K
        check(16'hFFFF, 1'b0, 1'b0, 1'b1, 16'h5FFF);

        $display("-- con la ROM de la controladora de disco en 8000 --");
        disc_rom = 1'b1;
        check(16'h8000, 1'b1, 1'b0, 1'b1, 16'h6000);  // banco 3
        check(16'h8001, 1'b1, 1'b0, 1'b1, 16'h6001);  // punto de entrada
        check(16'h9FFF, 1'b1, 1'b0, 1'b1, 16'h7FFF);
        check(16'h7FFF, 1'b1, 1'b1, 1'b0, 16'h7FFF);  // la RAM no se toca
        check(16'hA000, 1'b1, 1'b0, 1'b1, 16'h0000);  // ni las ROMs altas
        check(16'hE000, 1'b1, 1'b0, 1'b1, 16'h4000);
        // durante el arranque sigue mandando el forzado a ROM2
        check(16'h8000, 1'b0, 1'b0, 1'b1, 16'h4000);
        disc_rom = 1'b0;
        check(16'h8000, 1'b1, 1'b0, 1'b0, 16'h0000);  // sin ella, hueco
        // Con el modulo de expansion, en 8000 esta su ROM (POS) desde el
        // arranque: la ROM AB la busca ahi para ponerla en marcha
        eim = 1'b1;
        check(16'h8000, 1'b1, 1'b0, 1'b1, 16'h8000);
        eim = 1'b0;

        // ---------- tamaño de RAM instalada ----------
        $display("-- limite por tamaño de RAM --");
        paging_on = 1'b0; ram_size = 2'd0; addr = 16'h7FFF; #1;
        if (ram_oor !== 1'b0) begin
            $display("FAIL 32K: 7FFF deberia estar dentro (phys=%06h oor=%b pwrup=%b)",
                     ram_phys, ram_oor, pwrup); errors = errors + 1;
        end

        paging_on = 1'b1;
        // La RAM va de la pagina 107 hacia abajo: indice fisico = 107 - pagina.
        // 96K (el modulo de expansion original): 107..96; la 95 queda fuera.
        page = 8'd96; addr = 16'h1FFF; ram_size = 2'd1; #1;
        if (ram_phys !== 21'h017FFF || ram_oor !== 1'b0) begin
            $display("FAIL 96K: la pagina 96 es el ultimo trozo (phys=%06h oor=%b)", ram_phys, ram_oor);
            errors = errors + 1;
        end
        page = 8'd95; addr = 16'h0000; #1;
        if (ram_phys !== 21'h018000 || ram_oor !== 1'b1) begin
            $display("FAIL 96K: la pagina 95 deberia quedar fuera (phys=%06h oor=%b)", ram_phys, ram_oor);
            errors = errors + 1;
        end
        ram_size = 2'd2; #1;      // 512K: 107..44
        if (ram_oor !== 1'b0) begin
            $display("FAIL 512K: la pagina 95 deberia entrar"); errors = errors + 1;
        end
        page = 8'd43; #1;
        if (ram_phys !== 21'h080000 || ram_oor !== 1'b1) begin
            $display("FAIL 512K: la pagina 43 deberia quedar fuera"); errors = errors + 1;
        end
        ram_size = 2'd3; #1;      // 768K: 107..12
        if (ram_oor !== 1'b0) begin
            $display("FAIL 768K: la pagina 43 deberia entrar"); errors = errors + 1;
        end
        page = 8'd12; addr = 16'h1FFF; #1;
        if (ram_phys !== 21'h0BFFFF || ram_oor !== 1'b0) begin
            $display("FAIL 768K: la pagina 12 es el tope"); errors = errors + 1;
        end
        page = 8'd11; addr = 16'h0000; #1;
        if (ram_oor !== 1'b1) begin
            $display("FAIL 768K: la pagina 11 deberia quedar fuera"); errors = errors + 1;
        end
        // Una ranura sin asignar (el juego alternativo al arrancar) lee FF
        page = 8'd107; page_ok = 1'b0; #1;
        if (ram_oor !== 1'b1 || rom_cs !== 1'b0) begin
            $display("FAIL una ranura vacia deberia leer FF"); errors = errors + 1;
        end
        page_ok = 1'b1;
        // La RAM interna, sin paginar y paginada, es la misma memoria
        page = 8'd107; addr = 16'h0123; #1;
        if (ram_phys !== 21'h000123) begin
            $display("FAIL la pagina 107 es la RAM de 0000 (phys=%06h)", ram_phys); errors = errors + 1;
        end
        page = 8'd104; addr = 16'h0000; #1;
        if (ram_phys !== 21'h006000) begin
            $display("FAIL la pagina 104 es la RAM de 6000 (phys=%06h)", ram_phys); errors = errors + 1;
        end

        // ---------- paginacion: las paginas 120-123 son ROM ----------
        $display("-- paginacion --");
        ram_size = 2'd3;
        page = 8'd122; addr = 16'h0000; #1;
        if (rom_cs !== 1'b1 || ram_cs !== 1'b0 || rom_addr !== 16'h0000) begin
            $display("FAIL pagina 122 deberia ser la ROM AB"); errors = errors + 1;
        end
        page = 8'd120; addr = 16'h1FFF; #1;
        if (rom_cs !== 1'b1 || rom_addr !== 16'h5FFF) begin
            $display("FAIL pagina 120 deberia ser la ROM EF"); errors = errors + 1;
        end
        page = 8'd123; addr = 16'h0001; #1;
        if (rom_addr !== 16'h6001) begin
            $display("FAIL pagina 123 deberia ser la ROM de disco"); errors = errors + 1;
        end
        // Con expansion aparecen las paginas del propio modulo
        eim = 1'b1;
        page = 8'd123; addr = 16'h0000; #1;
        if (rom_addr !== 16'h8000) begin
            $display("FAIL con expansion la pagina 123 es el sistema paginado");
            errors = errors + 1;
        end
        page = 8'd124; #1;
        if (rom_addr !== 16'hA000) begin
            $display("FAIL pagina 124 (MTV)"); errors = errors + 1;
        end
        page = 8'd125; addr = 16'h1FFF; #1;
        if (rom_addr !== 16'hDFFF || rom_cs !== 1'b1) begin
            $display("FAIL pagina 125 (ACI): %04h", rom_addr); errors = errors + 1;
        end
        // con la ROM de disco, en la pagina 119 (la 123 es del sistema paginado)
        disc_rom = 1'b1; page = 8'd119; addr = 16'h0010; #1;
        if (rom_cs !== 1'b1 || rom_addr !== 16'h6010) begin
            $display("FAIL con expansion la ROM de disco es la pagina 119 (%04h)", rom_addr); errors = errors + 1;
        end
        disc_rom = 1'b0; #1;
        if (rom_cs !== 1'b0) begin
            $display("FAIL sin ROM de disco la pagina 119 no es ROM"); errors = errors + 1;
        end
        page = 8'd126; #1;
        if (rom_cs !== 1'b0 || ram_oor !== 1'b1) begin
            $display("FAIL la pagina 126 no es ROM ni RAM instalada"); errors = errors + 1;
        end
        eim = 1'b0;

        page = 8'd107; addr = 16'h0000; #1;
        if (ram_cs !== 1'b1 || rom_cs !== 1'b0) begin
            $display("FAIL pagina 107 deberia ser RAM"); errors = errors + 1;
        end
        paging_on = 1'b0;

        if (errors == 0) $display("tb_newbrain_mem: OK");
        else begin $display("tb_newbrain_mem: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
