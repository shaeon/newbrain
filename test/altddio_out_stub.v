// Stub de altddio_out (megafuncion de Altera) para elaborar el top sin
// Quartus: dataout vale datain_h con el reloj alto y datain_l con el bajo.
`default_nettype none
module altddio_out #(
    parameter extend_oe_disable = "OFF",
    parameter intended_device_family = "Cyclone 10 LP",
    parameter invert_output = "OFF",
    parameter lpm_hint = "UNUSED",
    parameter lpm_type = "altddio_out",
    parameter oe_reg = "UNREGISTERED",
    parameter power_up_high = "OFF",
    parameter width = 1
) (
    input  wire [width-1:0] datain_h,
    input  wire [width-1:0] datain_l,
    input  wire             outclock,
    output wire [width-1:0] dataout,
    input  wire             aclr, aset, oe, outclocken, sclr, sset
);
    assign dataout = outclock ? datain_h : datain_l;
endmodule
`default_nettype wire
