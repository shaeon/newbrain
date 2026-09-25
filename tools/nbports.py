#!/usr/bin/env python3
"""
Extrae y clasifica los accesos de E/S de una ROM del NewBrain.

Pensado para atacar ROMs que todavia no entendemos -- la POS del sistema
paginado, la d413 de la controladora de disco -- buscando primero por donde
hablan con el hardware, que es mucho mas rapido que leer 8K de arriba abajo.

No lleva decodificador propio: se apoya en z80dasm, que decodifica bien los
limites de instruccion. Eso importa porque para las formas con (C) hay que
rastrear hacia atras el ultimo LD BC,nnnn / LD B,nn / LD C,nn, y un barrido
byte a byte se traga constantes que no son opcodes.

En el bus de expansion del NewBrain, C es el registro y **B selecciona el
dispositivo**: 1 EXPANSION, 2 DISCCONTROLLER, 4 NETWORKCONTROL, FF todos.

Uso:  nbports.py fichero.rom [direccion_base_hex]
"""
import re
import subprocess
import sys
from collections import defaultdict

PORTS = {
    0x04: "INTCON  borra la interrupcion de reloj",
    0x06: "COP     microbus del COP420",
    0x07: "ENREG   registro de habilitacion",
    0x08: "TVLATCH bit 6 de la direccion de video",
    0x09: "TVLL    base de video, arranca la trama",
    0x0C: "TVTL    registro de modo de video",
    0x14: "UST_A   estado A",
    0x16: "UST_B   estado B",
    0x0F: "control de paginacion / disco",
    0xFF: "control de paginacion / estado",
    0x80: "paginacion de cartucho (MicroPage / DataPack)",
}
DEVICES = {1: "EXPANSION", 2: "DISCCONTROLLER", 4: "NETWORKCONTROL",
           0xFF: "ALLPERIPHERALS"}

# z80dasm pone la direccion en el comentario:  \tout (007h),a\t\t;e007\td3 07
LINE = re.compile(r"^\s*(.+?)\s*;\s*([0-9a-fA-F]{4})\b")
# Ojo: z80dasm escribe los inmediatos como (0NNh). Exigir el sufijo h no es
# cosmetico: sin el, "in a,(c)" encaja tambien, porque c es un digito hex
# valido, y todos los accesos indirectos acaban clasificados como puerto 0C.
IMM  = re.compile(r"\b(in|out)\s+(?:a\s*,\s*)?\(\s*0([0-9a-fA-F]+)h\s*\)", re.I)
VIAC = re.compile(r"\b(in|out|ini|outi|ind|outd|inir|otir|indr|otdr)\b.*\(\s*c\s*\)", re.I)
BLK  = re.compile(r"^\s*(ini|outi|ind|outd|inir|otir|indr|otdr)\b", re.I)
LDBC = re.compile(r"^\s*ld\s+bc\s*,\s*0?([0-9a-fA-F]+)h?\s*$", re.I)
LDB  = re.compile(r"^\s*ld\s+b\s*,\s*0?([0-9a-fA-F]+)h?\s*$", re.I)
LDC  = re.compile(r"^\s*ld\s+c\s*,\s*0?([0-9a-fA-F]+)h?\s*$", re.I)


def disassemble(path, base):
    out = subprocess.run(["z80dasm", "-a", "-t", "-g", "0x%X" % base, path],
                         capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit("z80dasm fallo: " + out.stderr.strip())
    return out.stdout.splitlines()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    path = sys.argv[1]
    base = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0

    # El rastreo de B y C es lineal, asi que solo vale dentro del mismo bloque
    # basico. Se descarta lo que quede demasiado lejos: mas alla de ahi es
    # casi seguro un valor de otra rutina.
    NEAR = 12

    hits = []
    b = c = None
    b_age = c_age = 10**9
    n = 0
    for raw in disassemble(path, base):
        m = LINE.match(raw)
        if not m:
            continue
        text, addr = m.group(1), int(m.group(2), 16)
        if not text:
            continue
        n += 1
        b_age += 1
        c_age += 1

        g = LDBC.match(text)
        if g:
            v = int(g.group(1), 16)
            b, c = (v >> 8) & 0xFF, v & 0xFF
            b_age = c_age = 0
            continue
        g = LDB.match(text)
        if g:
            b, b_age = int(g.group(1), 16), 0; continue
        g = LDC.match(text)
        if g:
            c, c_age = int(g.group(1), 16), 0; continue

        g = IMM.search(text)
        if g:
            hits.append((addr, text, int(g.group(2), 16), None))
            continue
        if VIAC.search(text) or BLK.match(text):
            hits.append((addr, text,
                         c if c_age <= NEAR else None,
                         b if b_age <= NEAR else None))

    by_port = defaultdict(list)
    for addr, text, port, dev in hits:
        by_port[port].append((addr, text, dev))

    print("%d accesos de E/S en %d puertos distintos\n" % (len(hits), len(by_port)))
    for port in sorted(by_port, key=lambda p: (p is None, p)):
        label = "puerto %02X" % port if port is not None else "puerto indeterminado"
        print("%-12s %s" % (label, PORTS.get(port, "")))
        for addr, text, dev in by_port[port]:
            d = "  [B=%02X %s]" % (dev, DEVICES.get(dev, "?")) if dev is not None else ""
            print("    %04X  %-16s%s" % (addr, text, d))
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
