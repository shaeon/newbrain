#!/bin/sh
# Prueba de punta a punta de las herramientas de disco contra la
# controladora: un disco de 200K hecho con dir2dsk.py (pistas de sistema del
# disco original y dos ficheros de prueba) tiene que arrancar CP/M en la
# cosimulacion (tools/nbfdc.py: Z80 + d413 + d417 + 765) y listar los dos
# ficheros con DIR.
#
#   sh prueba_dir2dsk.sh DISCO_DE_SISTEMA.dsk ROM_COMPLETA
set -e
AQUI=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir "$TMP/PRUEBA"
printf '10 PRINT 1\r\n' > "$TMP/PRUEBA/PRUEBA.BAS"
head -c 40000 /dev/zero | tr '\0' 'A' > "$TMP/PRUEBA/GRANDE.COM"
python3 "$AQUI/../nbdsk2raw.py" "$1" "$TMP/sistema.img"
python3 "$AQUI/dir2dsk.py" "$TMP/PRUEBA" -s "$TMP/sistema.img" -F 200K -o "$TMP/prueba.dsk" > /dev/null
python3 "$AQUI/../nbcpmdir.py" "$2" "$TMP/prueba.dsk" GRANDE PRUEBA
