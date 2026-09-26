// Copia de common/mist-modules/scandoubler/scandoubler_scaledepth.v para
// simular con Verilator: el original selecciona d[IN_DEPTH-1 -:n] tambien
// cuando n vale 0, en una rama que nunca se ejecuta, y Verilator la rechaza.
// Aqui la eleccion va en un generate. Mismo resultado.
module scandoubler_scaledepth (
	input [IN_DEPTH-1:0] d,
	output wire [OUT_DEPTH-1:0] q
);
parameter IN_DEPTH = 6;
parameter OUT_DEPTH = 6;

localparam m = OUT_DEPTH < IN_DEPTH ? 1 : OUT_DEPTH/IN_DEPTH;
localparam n = OUT_DEPTH < IN_DEPTH ? 0 : OUT_DEPTH%IN_DEPTH;
localparam o = OUT_DEPTH < IN_DEPTH ? OUT_DEPTH : IN_DEPTH;

generate
	if (n > 0) begin : con_resto
		assign q = { {m{d[IN_DEPTH-1 -:o]}}, d[IN_DEPTH-1 -:n] };
	end else begin : sin_resto
		assign q = { {m{d[IN_DEPTH-1 -:o]}} };
	end
endgenerate
endmodule
