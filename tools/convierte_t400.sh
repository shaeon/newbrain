#!/bin/sh
# Convierte el core COP400 de VHDL a Verilog con GHDL.
#
# El objetivo no es cosmetico: con el core en Verilog, Icarus puede
# simularlo, y eso mete la fase 5 dentro del mismo banco de pruebas que todo
# lo demas en vez de dejarla a merced de Quartus y la placa.
#
# Los genericos se fijan aqui porque GHDL los hornea en la salida:
#   opt_type_g      = 0  -> COP420
#   opt_ck_div_g    = 2  -> divisor CKI de 16
#   opt_microbus_g  = 1  -> MICROBUS, que es como lo usa el NewBrain
#
# Los dos bloques de depuracion que referencian tb_pack se quitan antes: son
# del banco de pruebas del autor y GHDL no los sintetiza.
set -e
T400=${1:-common/T400}
TMP=$(mktemp -d)
cp "$T400"/*.vhd "$TMP/"
python3 - "$TMP" <<'PY'
import glob, re, sys
for f in glob.glob(sys.argv[1] + '/*.vhd'):
    s = open(f).read()
    n = re.sub(r"--\s*pragma translate_off\s*\n(?:.*?tb_pack.*?\n)+?--\s*pragma translate_on\s*\n", "", s)
    n = re.sub(r"--\s*pragma translate_off\s*\n((?:(?!pragma translate_on).)*?tb_[a-z_]+_s\s*<=.*?\n)*?\s*--\s*pragma translate_on\s*\n", "", n, flags=re.S)
    if n != s: open(f, 'w').write(n)
PY
cd "$TMP"
for f in t400_pack-p t400_opt_pack-p t400_io_pack-p t400_mnemonic_pack-p \
         t400_alu t400_clkgen t400_decoder t400_dmem_ctrl t400_io_d t400_io_g \
         t400_io_in t400_io_l t400_pmem_ctrl t400_reset t400_sio t400_skip \
         t400_stack t400_timer t400_core; do
    ghdl -a --std=93 "$f.vhd"
done
ghdl synth --std=93 --out=verilog \
    -gopt_type_g=0 -gopt_ck_div_g=2 -gopt_microbus_g=1 t400_core
