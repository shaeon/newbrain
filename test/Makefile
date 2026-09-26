# Tests unitarios con Icarus Verilog.
#   make          -> compila y ejecuta todo
#   make mem      -> solo un banco de pruebas
RTL   := ../rtl
IV    := iverilog -g2012 -Wall
TESTS := mem powerup io kbd ps2 cop cintamux vfd lcd cinta fdc video videosync sdram pager load cpumem copreal

all: $(TESTS) drivers

mem:
	@$(IV) -o build_mem.vvp tb_newbrain_mem.v $(RTL)/newbrain_mem.v && vvp -n build_mem.vvp

powerup:
	@$(IV) -o build_powerup.vvp tb_newbrain_powerup.v $(RTL)/newbrain_powerup.v && vvp -n build_powerup.vvp

io:
	@$(IV) -o build_io.vvp tb_newbrain_io.v $(RTL)/newbrain_io.v && vvp -n build_io.vvp

clean:
	@rm -rf *.vvp *.vcd cinta_prueba.txt build_vsync build_vsync_w

.PHONY: all clean $(TESTS)

# Comprobacion de sintaxis y elaboracion de todo el RTL de la maquina,
# usando un stub del T80 (el submodulo no hace falta para esto).
lint:
	@iverilog -g2012 -Wall -o build_lint.vvp -s newbrain \
	    t80pa_stub.v \
	    $(RTL)/newbrain.v $(RTL)/newbrain_mem.v $(RTL)/newbrain_io.v \
	    $(RTL)/newbrain_powerup.v \
	    $(RTL)/newbrain_sdram.v $(RTL)/newbrain_pager.v $(RTL)/newbrain_cop_hle.v $(RTL)/newbrain_cop_mux.v $(RTL)/newbrain_vfd_espia.v $(RTL)/newbrain_kbd.v $(RTL)/newbrain_tape.v $(RTL)/newbrain_cop_mem.v $(RTL)/newbrain_cop_real.v $(RTL)/t400_core.v $(RTL)/newbrain_video.v $(RTL)/newbrain_chargen.v $(RTL)/newbrain_clkmux.v $(RTL)/newbrain_fdc.v u765_stub.v \
	&& echo "lint: OK"

.PHONY: lint

kbd:
	@$(IV) -o build_kbd.vvp tb_newbrain_kbd.v $(RTL)/newbrain_kbd.v $(RTL)/newbrain_tape.v $(RTL)/newbrain_cop_mem.v $(RTL)/newbrain_cop_real.v $(RTL)/t400_core.v && vvp -n build_kbd.vvp

cop:
	@$(IV) -o build_cop.vvp tb_newbrain_cop.v $(RTL)/newbrain_cop_hle.v $(RTL)/newbrain_cop_mux.v $(RTL)/newbrain_tape.v && vvp -n build_cop.vvp

video:
	@$(IV) -o build_video.vvp tb_newbrain_video.v $(RTL)/newbrain_video.v && vvp -n build_video.vvp
	@$(IV) -P tb_newbrain_video.ANCHO=1 -o build_video_w.vvp tb_newbrain_video.v $(RTL)/newbrain_video.v && vvp -n build_video_w.vvp
	@$(IV) -o build_clkmux.vvp tb_newbrain_clkmux.v $(RTL)/newbrain_clkmux.v && vvp -n build_clkmux.vvp

# Sincronismos y lineas de la salida de 15 kHz: el generador mas mist_video
# con el scandoubler desactivado, en Original y en Wide. Va con Verilator
# porque Icarus no elabora mist-modules (parametros declarados despues de los
# puertos que los usan). scandoubler_scaledepth_sim.v sustituye al original,
# que Verilator rechaza por una rama muerta.
VSYNC_SRC = tb_newbrain_video_sync.v $(RTL)/newbrain_video.v $(MM)/mist_video.v $(MM)/osd.v \
            $(MM)/rgb2ypbpr.v $(MM)/video_cleaner.v $(MM)/cofi.sv \
            $(filter-out %scandoubler_scaledepth.v,$(SD)) scandoubler_scaledepth_sim.v
VL := verilator --binary --timing -Wno-fatal -Wno-lint -Wno-style --top-module tb_newbrain_video_sync

videosync:
	@$(VL) -Mdir build_vsync -o sim $(VSYNC_SRC) >/dev/null && build_vsync/sim
	@$(VL) -GANCHO=1 -Mdir build_vsync_w -o sim $(VSYNC_SRC) >/dev/null && build_vsync_w/sim

# Elaboracion del top completo contra los modulos reales de mist-modules.
# El T80 (VHDL) y el PLL (IP de Altera) se sustituyen por stubs; el resto es
# el codigo de verdad, asi que esto detecta nombres de puerto y anchos mal.
# user_io dispara un aviso de bucle sin retardo propio de Icarus: es
# sintetizable en Quartus, solo impide generar un binario ejecutable aqui.
MM := ../common/mist-modules
SD := $(MM)/scandoubler/scandoubler.v $(MM)/scandoubler/scandoubler_framing.v \
      $(MM)/scandoubler/scandoubler_linedouble.v $(MM)/scandoubler/scandoubler_rotate.v \
      $(MM)/scandoubler/scandoubler_rgb_interp.v $(MM)/scandoubler/scandoubler_scaledepth.v \
      $(MM)/scandoubler/pixel_interp.v $(MM)/scandoubler/frac_interp.v \
      $(MM)/scandoubler/unsigned_division.v

integration:
	@if [ ! -f $(MM)/user_io.v ]; then \
	    echo "integration: faltan los submodulos, ejecuta git submodule update --init"; \
	    exit 1; fi
	@# Icarus no elabora del todo user_io (un always sin retardo), asi que se
	@# filtran esos avisos y se da por buena la integracion si no queda ningun
	@# otro error: puertos que no existen, anchos, conexiones rotas.
	@out=$$(iverilog -g2012 -o build_top.vvp -s newbrain_top \
	    -DNO_DIRECT_UPLOAD=1 -DBIG_OSD=1 -DI2S_AUDIO=1 -DUSE_AUDIO_IN=1 -I. \
	    t80pa_stub.v pll_stub.v u765_stub.v $(RTL)/*.v $(RTL)/*.sv \
	    $(MM)/user_io.v $(MM)/data_io.v $(MM)/mist_video.v $(MM)/osd.v \
	    $(MM)/rgb2ypbpr.v $(MM)/video_cleaner.v $(MM)/cofi.sv $(MM)/i2s.v $(SD) \
	    2>&1 | grep -viE "warning|infinite loop|always process|Elaboration failed|^\s*:"); \
	 if echo "$$out" | grep -qi error; then echo "$$out"; echo "integration I2S: FALLO"; exit 1; \
	 else echo "integration I2S: OK (sin errores de conexion)"; fi
	@out=$$(iverilog -g2012 -o build_top_ds.vvp -s newbrain_top \
	    -DNO_DIRECT_UPLOAD=1 -DBIG_OSD=1 -DDELTASIGMA_AUDIO=1 -DUSE_AUDIO_IN=1 -I. \
	    t80pa_stub.v pll_stub.v dac_stub.v u765_stub.v $(RTL)/*.v $(RTL)/*.sv \
	    $(MM)/user_io.v $(MM)/data_io.v $(MM)/mist_video.v $(MM)/osd.v \
	    $(MM)/rgb2ypbpr.v $(MM)/video_cleaner.v $(MM)/cofi.sv $(SD) \
	    2>&1 | grep -viE "warning|infinite loop|always process|Elaboration failed|^\s*:"); \
	 if echo "$$out" | grep -qi error; then echo "$$out"; echo "integration sigma-delta: FALLO"; exit 1; \
	 else echo "integration sigma-delta: OK (sin errores de conexion)"; fi
	@out=$$(iverilog -g2012 -o build_top_sidi.vvp -s newbrain_top \
	    -DSIDI=1 -DNO_DIRECT_UPLOAD=1 -DBIG_OSD=1 -DDELTASIGMA_AUDIO=1 -DUSE_AUDIO_IN=1 -I. \
	    t80pa_stub.v pll_stub.v dac_stub.v u765_stub.v $(RTL)/*.v $(RTL)/*.sv \
	    $(MM)/user_io.v $(MM)/data_io.v $(MM)/mist_video.v $(MM)/osd.v \
	    $(MM)/rgb2ypbpr.v $(MM)/video_cleaner.v $(MM)/cofi.sv $(SD) \
	    2>&1 | grep -viE "warning|infinite loop|always process|Elaboration failed|^\s*:"); \
	 if echo "$$out" | grep -qi error; then echo "$$out"; echo "integration SiDi: FALLO"; exit 1; \
	 else echo "integration SiDi: OK (sin errores de conexion)"; fi
	@python3 ../tools/nbpines.py ../rtl/newbrain_top.sv ../calypso/newbrain_calypso.qsf
	@out=$$(iverilog -g2012 -o build_top_pos.vvp -s newbrain_top \
	    -DPOSEIDON=1 -DNO_DIRECT_UPLOAD=1 -DBIG_OSD=1 -DI2S_AUDIO=1 -DUSE_AUDIO_IN=1 -I. \
	    t80pa_stub.v pll_stub.v u765_stub.v $(RTL)/*.v $(RTL)/*.sv \
	    $(MM)/user_io.v $(MM)/data_io.v $(MM)/mist_video.v $(MM)/osd.v \
	    $(MM)/rgb2ypbpr.v $(MM)/video_cleaner.v $(MM)/cofi.sv $(MM)/i2s.v $(SD) \
	    2>&1 | grep -viE "warning|infinite loop|always process|Elaboration failed|^\s*:"); \
	 if echo "$$out" | grep -qi error; then echo "$$out"; echo "integration Poseidon: FALLO"; exit 1; \
	 else echo "integration Poseidon: OK (sin errores de conexion)"; fi
	@out=$$(iverilog -g2012 -o build_top_ext.vvp -s newbrain_top \
	    -DNB_SERIE=1 -DNB_REMOTE=1 -DNB_LCD=1 \
	    -DNO_DIRECT_UPLOAD=1 -DBIG_OSD=1 -DI2S_AUDIO=1 -DUSE_AUDIO_IN=1 -I. \
	    t80pa_stub.v pll_stub.v u765_stub.v $(RTL)/*.v $(RTL)/*.sv \
	    $(MM)/user_io.v $(MM)/data_io.v $(MM)/mist_video.v $(MM)/osd.v \
	    $(MM)/rgb2ypbpr.v $(MM)/video_cleaner.v $(MM)/cofi.sv $(MM)/i2s.v $(SD) \
	    2>&1 | grep -viE "warning|infinite loop|always process|Elaboration failed|^\s*:"); \
	 if echo "$$out" | grep -qi error; then echo "$$out"; echo "integration extras: FALLO"; exit 1; \
	 else echo "integration extras (serie, remote, LCD): OK (sin errores de conexion)"; fi
	@python3 ../tools/nbpines.py ../rtl/newbrain_top.sv ../sidi/newbrain_sidi.qsf
	@python3 ../tools/nbpines.py ../rtl/newbrain_top.sv ../poseidon/newbrain_poseidon.qsf
	@out=$$(iverilog -g2012 -o build_top_mist.vvp -s newbrain_top \
	    -DMIST=1 -DNO_DIRECT_UPLOAD=1 -DBIG_OSD=1 -DDELTASIGMA_AUDIO=1 -I. \
	    t80pa_stub.v pll_stub.v dac_stub.v u765_stub.v $(RTL)/*.v $(RTL)/*.sv \
	    $(MM)/user_io.v $(MM)/data_io.v $(MM)/mist_video.v $(MM)/osd.v \
	    $(MM)/rgb2ypbpr.v $(MM)/video_cleaner.v $(MM)/cofi.sv $(SD) \
	    2>&1 | grep -viE "warning|infinite loop|always process|Elaboration failed|^\s*:"); \
	 if echo "$$out" | grep -qi error; then echo "$$out"; echo "integration MiST: FALLO"; exit 1; \
	 else echo "integration MiST: OK (sin errores de conexion)"; fi
	@python3 ../tools/nbpines.py ../rtl/newbrain_top.sv ../mist/newbrain_mist.qsf

.PHONY: integration

sdram:
	@$(IV) -o build_sdram.vvp tb_newbrain_sdram.v sdram_model.v $(RTL)/newbrain_sdram.v $(RTL)/newbrain_pager.v && vvp -n build_sdram.vvp

pager:
	@$(IV) -o build_pager.vvp tb_newbrain_pager.v $(RTL)/newbrain_pager.v && vvp -n build_pager.vvp

# Caza registros excitados desde dos bloques always. Icarus lo simula sin
# quejarse, Quartus lo rechaza, y cada hallazgo cuesta una sintesis entera.
drivers:
	@python3 ../tools/nbdrivers.py $(RTL)/*.v

load:
	@$(IV) -g2012 -o build_load.vvp -s tb_newbrain_load tb_newbrain_load.v \
	    t80pa_stub.v sdram_model.v \
	    $(RTL)/newbrain.v $(RTL)/newbrain_mem.v $(RTL)/newbrain_io.v \
	    $(RTL)/newbrain_powerup.v $(RTL)/newbrain_chargen.v $(RTL)/newbrain_clkmux.v \
	    $(RTL)/newbrain_sdram.v $(RTL)/newbrain_pager.v $(RTL)/newbrain_video.v \
	    $(RTL)/newbrain_cop_hle.v $(RTL)/newbrain_cop_mux.v $(RTL)/newbrain_vfd_espia.v $(RTL)/newbrain_kbd.v $(RTL)/newbrain_tape.v $(RTL)/newbrain_fdc.v u765_stub.v $(RTL)/newbrain_cop_mem.v $(RTL)/newbrain_cop_real.v $(RTL)/t400_core.v && vvp -n build_load.vvp

cpumem:
	@$(IV) -g2012 -o build_cpumem.vvp -s tb_newbrain_cpumem tb_newbrain_cpumem.v \
	    t80pa_bus.v sdram_model.v \
	    $(RTL)/newbrain.v $(RTL)/newbrain_mem.v $(RTL)/newbrain_io.v \
	    $(RTL)/newbrain_powerup.v $(RTL)/newbrain_chargen.v $(RTL)/newbrain_clkmux.v \
	    $(RTL)/newbrain_sdram.v $(RTL)/newbrain_pager.v $(RTL)/newbrain_video.v \
	    $(RTL)/newbrain_cop_hle.v $(RTL)/newbrain_cop_mux.v $(RTL)/newbrain_vfd_espia.v $(RTL)/newbrain_kbd.v $(RTL)/newbrain_tape.v $(RTL)/newbrain_fdc.v u765_stub.v $(RTL)/newbrain_cop_mem.v $(RTL)/newbrain_cop_real.v $(RTL)/t400_core.v && vvp -n build_cpumem.vvp

copreal:
	@$(IV) -g2012 -o build_copreal.vvp -s tb_newbrain_cop_real \
	    tb_newbrain_cop_real.v $(RTL)/newbrain_cop_real.v \
	    $(RTL)/newbrain_cop_mem.v $(RTL)/t400_core.v && vvp -n build_copreal.vvp

# Desmodulador contra la forma de onda de beepgenerator.py (gylles38), que
# carga en maquinas reales, y bucle cerrado modulador -> desmodulador.
cinta_prueba.txt: cinta_prueba.bas ../tools/nbwav.py
	@python3 ../tools/nbwav.py cinta_prueba.bas cinta_prueba.txt --bits --pilotos=200 > /dev/null

cinta: cinta_prueba.txt
	@$(IV) -o build_tape.vvp tb_newbrain_tape.v $(RTL)/newbrain_tape.v && vvp -n build_tape.vvp

vfd:
	@$(IV) -o build_vfd.vvp tb_newbrain_vfd_espia.v $(RTL)/newbrain_vfd_espia.v && vvp -n build_vfd.vvp

lcd:
	@$(IV) -o build_lcd.vvp tb_newbrain_lcd_i2c.v $(RTL)/newbrain_lcd_i2c.v && vvp -n build_lcd.vvp

cintamux:
	@$(IV) -o build_mux.vvp tb_newbrain_cinta_mux.v $(RTL)/newbrain_cop_hle.v $(RTL)/newbrain_cop_mux.v $(RTL)/newbrain_tape.v && vvp -n build_mux.vvp

ps2:
	@$(IV) -o build_ps2.vvp tb_newbrain_ps2.v $(RTL)/newbrain_ps2.v && vvp -n build_ps2.vvp
	@# el serializador PS/2 de verdad, sacado de user_io.v, contra el receptor
	@awk '/^module user_io_ps2/{f=1} f{print} f&&/^endmodule/{exit}' $(MM)/user_io.v > build_user_io_ps2.v
	@$(IV) -o build_ps2u.vvp tb_newbrain_ps2_uio.v build_user_io_ps2.v $(RTL)/newbrain_ps2.v && vvp -n build_ps2u.vvp

fdc:
	@$(IV) -o build_fdc.vvp tb_newbrain_fdc.v t80pa_guion.v u765_stub.v $(RTL)/newbrain_fdc.v && vvp -n build_fdc.vvp

# Carga y grabacion contra la ROM real (necesita pip install z80 y la ROM)
ROM ?= ../roms/NEWBRAIN.ROM
rom:
	@python3 ../tools/nbcinta.py $(ROM)

# Las dos ROMs de disco de verdad, cada una en su Z80, con un 765 leyendo
# una imagen EDSK. TECLAS= lo que se escribe tras arrancar (cpm, dir...).
DSK    ?= ../roms/disco.dsk
D413   ?= ../roms/d413.bin
D417   ?= ../roms/d417.bin
TECLAS ?= cpm
romdisco:
	@python3 ../tools/nbfdc.py $(ROM) $(D413) $(D417) $(DSK) $(TECLAS)

# El sistema paginado con las ROMs de verdad (fichero de ROM completo, con
# las del modulo de expansion). KB= la RAM: 96, 512 o 768.
KB ?= 512
rompag:
	@python3 ../tools/nbpag.py $(ROM) $(KB)

.PHONY: ps2 cintamux fdc rom romdisco rompag

# Herramientas de disco de punta a punta (no va en la bateria por defecto:
# tarda unos minutos y necesita la ROM completa y un disco de sistema).
#   make disco SISTEMA=SSDD200K.dsk ROM=NB_ISSUE3.ROM
SISTEMA ?= ../../discos/SSDD200K.dsk
ROM     ?= ../../roms/NB_ISSUE3.ROM
disco:
	@sh ../tools/disco/prueba_dir2dsk.sh $(SISTEMA) $(ROM)

.PHONY: disco
