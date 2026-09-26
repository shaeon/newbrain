# Restricciones de la SiDi. Las de la SDRAM son las de la Calypso: el
# reloj interno (32 MHz) y el de la SDRAM son los mismos, pero el
# rutado de la placa no, asi que si TimeQuest se queja de las rutas de la
# SDRAM, estos numeros son lo primero que hay que ajustar.

create_clock -name "CLOCK_27" -period 37.037 [get_ports {CLOCK_27}]
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

# Reloj de pixel: c2 (27 MHz, Wide) y c3 (32 MHz, Original) pasan por el
# conmutador newbrain_clkmux y alimentan el barrido, el generador de
# caracteres y mist_video. Con el sistema (c1 y sdram_clk) solo se comunican por
# sincronizadores y memorias de doble reloj, y entre si no conviven nunca.
set_clock_groups -asynchronous \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1] sdram_clk}] \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}] \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[3]}]
