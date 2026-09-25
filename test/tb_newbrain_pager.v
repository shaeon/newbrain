`timescale 1ns/1ps
//
// Paginacion del modulo de expansion, contra el Apendice F del Manual
// Tecnico de Software.
//
module tb_newbrain_pager;
    reg clk = 0, reset = 1, present = 1;
    reg [15:0] io_addr = 0;
    reg [7:0]  io_data = 0;
    reg        io_wr = 0;
    reg [15:0] cpu_addr = 0;
    wire       paging_on;
    wire [7:0] page;
    wire       page_ok;
    wire [20:0] phys_addr;
    wire       a16, multiproc, isolated;
    integer errors = 0;

    always #5 clk = ~clk;

    newbrain_pager dut (
        .clk(clk), .reset(reset), .present(present),
        .io_addr(io_addr), .io_data(io_data), .io_wr(io_wr),
        .cpu_addr(cpu_addr), .paging_on(paging_on),
        .page(page), .page_ok(page_ok), .phys_addr(phys_addr),
        .a16(a16), .multiproc(multiproc), .isolated(isolated)
    );

    // Escribe un registro de pagina como lo hace la ROM del sistema
    // paginado: la ranura y el juego viajan en la direccion y la pagina es
    // el dato tal cual (la ROM escribe OUT 8802 <- 7B para su pagina 123).
    task set_page(input [2:0] slot, input set_sel, input [7:0] pg);
        reg [15:0] a;
        begin
            a = 16'h0802;                   // A11 a uno, como la ROM
            a[15:13] = slot;
            a[12]    = set_sel;
            @(negedge clk);
            io_addr = a; io_data = pg; io_wr = 1;
            @(negedge clk); io_wr = 0;
            @(negedge clk);
        end
    endtask

    task set_status(input [7:0] v);
        begin
            @(negedge clk);
            io_addr = 16'h01FF; io_data = v; io_wr = 1;   // A8 = modulo EI
            @(negedge clk); io_wr = 0;
            @(negedge clk);
        end
    endtask

    task chk(input [255:0] name, input cond);
        begin
            if (!cond) begin
                $display("FAIL %0s", name);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        reset = 0;
        @(negedge clk);

        chk("al arrancar la paginacion esta apagada", paging_on == 1'b0);

        // Al arrancar, el juego principal tiene el mapa natural y el
        // alternativo esta vacio
        present = 1;
        cpu_addr = 16'h0000; #1;
        chk("arranque: ranura 0 -> 107", page == 8'd107 && page_ok);
        cpu_addr = 16'h8000; #1;
        chk("arranque: ranura 4 -> 123", page == 8'd123 && page_ok);
        cpu_addr = 16'hE000; #1;
        chk("arranque: ranura 7 -> 120", page == 8'd120 && page_ok);
        set_status(8'b0000_1101);
        cpu_addr = 16'h4000; #1;
        chk("arranque: el juego alternativo esta vacio", page_ok == 1'b0);
        set_status(8'b0000_1000);

        // Lo que hace la ROM del sistema paginado: su pagina 123 en 8000
        set_page(3'd4, 1'b0, 8'h7B);
        cpu_addr = 16'h8000; #1;
        chk("OUT 8802 <- 7B pone la pagina 123", page == 8'd123);

        // Mapa del juego principal: la RAM interna son las paginas 104-107
        set_page(3'd0, 1'b0, 8'd107);
        set_page(3'd1, 1'b0, 8'd106);
        set_page(3'd2, 1'b0, 8'd105);
        set_page(3'd3, 1'b0, 8'd104);
        set_page(3'd5, 1'b0, 8'd122);
        set_page(3'd7, 1'b0, 8'd120);
        // Juego alternativo: una pagina alta cualquiera en la misma ranura
        set_page(3'd0, 1'b1, 8'd100);

        set_status(8'b0000_1001);      // D0 habilita, D3 a uno = sin multiproceso
        chk("la paginacion queda habilitada", paging_on == 1'b1);
        chk("sin multiproceso", multiproc == 1'b0);
        chk("A16 a cero", a16 == 1'b0);

        cpu_addr = 16'h0000; #1;
        chk("ranura 0 -> pagina 107", page == 8'd107);
        chk("direccion fisica de 0000", phys_addr == {8'd107, 13'h0000});

        cpu_addr = 16'h2345; #1;
        chk("ranura 1 -> pagina 106", page == 8'd106);
        chk("desplazamiento dentro de la pagina", phys_addr == {8'd106, 13'h0345});

        cpu_addr = 16'hA000; #1;
        chk("ranura 5 -> pagina 122", page == 8'd122);
        cpu_addr = 16'hFFFF; #1;
        chk("ranura 7 -> pagina 120", page == 8'd120);
        chk("ultimo byte de la pagina", phys_addr == {8'd120, 13'h1FFF});

        // D2 conmuta al segundo juego de ocho registros
        set_status(8'b0000_1101);
        chk("A16 a uno", a16 == 1'b1);
        cpu_addr = 16'h0000; #1;
        chk("mismo hueco, juego alternativo -> pagina 100", page == 8'd100);
        set_status(8'b0000_1001);
        cpu_addr = 16'h0000; #1;
        chk("vuelta al juego principal", page == 8'd107);

        // D3 a cero selecciona multiproceso
        set_status(8'b0000_0001);
        chk("multiproceso seleccionado", multiproc == 1'b1);
        set_status(8'b0001_1001);
        chk("maquina aislada", isolated == 1'b1);

        // La pagina tiene 7 bits: el octavo del dato se ignora
        set_status(8'b0000_1001);
        set_page(3'd0, 1'b0, 8'hFF);
        cpu_addr = 16'h1FFF; #1;
        chk("pagina de 7 bits", page == 8'd127);

        // Sin modulo de expansion no debe pasar nada
        present = 0; #1;
        chk("sin expansion no hay paginacion", paging_on == 1'b0);

        if (errors == 0) $display("tb_newbrain_pager: OK");
        else begin $display("tb_newbrain_pager: %0d FALLOS", errors); $fatal; end
        $finish;
    end
endmodule
