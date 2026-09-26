create_clock -name "CLK12M" -period 83.333 [get_ports {CLK12M}]
create_clock -name {SPI_SCK}  -period 41.666 [get_ports {SPI_SCK}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# SDRAM. SDRAM_CLK sale de un registro DDR del pin (sdramclk_ddr en
# newbrain_top.sv) que da clk_sys invertido, o sea el reloj del sistema
# adelantado medio periodo. Va antes de
# cualquier otra restriccion que lo nombre. c0 ya no se usa y Quartus lo
# quita, por eso no aparece en los grupos.
create_generated_clock -name sdram_clk -source [get_pins {pll|altpll_component|auto_generated|pll1|clk[1]}] -invert [get_ports {SDRAM_CLK}]

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*] sdram_clk}]


# SDRAM: los retardos van contra sdram_clk, definido arriba.

set_input_delay -clock [get_clocks {sdram_clk}] -max 6.4 [get_ports SDRAM_DQ[*]]
set_input_delay -clock [get_clocks {sdram_clk}] -min 3.2 [get_ports SDRAM_DQ[*]]

set_output_delay -clock [get_clocks {sdram_clk}] -max 1.5 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
set_output_delay -clock [get_clocks {sdram_clk}] -min -0.8 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]

# Reloj de pixel: c2 (27 MHz) alimenta el barrido, el generador de
# caracteres y mist_video. Con el sistema (c1 y sdram_clk) solo se comunica
# por sincronizadores y memorias de doble reloj. c3 ya no se usa.
set_clock_groups -asynchronous \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1] sdram_clk}] \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}]
