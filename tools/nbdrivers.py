#!/usr/bin/env python3
"""
Busca registros excitados desde mas de un bloque always dentro del mismo
modulo.

Icarus lo simula sin rechistar, porque resuelve el ultimo que escribe, pero
Quartus lo rechaza con "Can't resolve multiple constant drivers" y cada
hallazgo cuesta una vuelta completa de sintesis. Esto lo caza antes.

No es un parser de Verilog: atribuye cada asignacion no bloqueante al ultimo
always visto. Basta porque las asignaciones continuas usan "assign" con "=" y
no encajan con el patron. Puede dar algun falso positivo; los falsos
negativos son raros.

Uso:  nbdrivers.py fichero.v [fichero.v ...]
"""
import re
import sys

ALWAYS = re.compile(r"^\s*always\b")
# Acepta tanto "x <= ..." como "if (cond) x <= ..." o "else x <= ...", que es
# como queda la mitad del codigo. Exigir que la asignacion empiece la
# sentencia evita confundirla con el "<=" de una comparacion.
ASSIGN = re.compile(
    r"^\s*(?:(?:if|else\s+if)\s*\([^)]*\)\s*|else\s+)*"
    r"([A-Za-z_]\w*)\s*(?:\[[^\]]*\])?\s*<=")
MODULE = re.compile(r"^\s*module\s+(\w+)")


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*", "", text)


def check(path):
    lines = strip_comments(open(path).read()).splitlines()
    module = path
    blocks = []          # (linea_del_always, {reg: primera_linea})
    cur = None

    for n, line in enumerate(lines, 1):
        m = MODULE.match(line)
        if m:
            # cada modulo tiene sus propios registros: dos modulos del mismo
            # fichero pueden llamar igual a los suyos sin que sea un error
            module = m.group(1)
            cur = None
        if ALWAYS.match(line):
            cur = {}
            blocks.append((n, module, cur))
            continue
        a = ASSIGN.match(line)
        if a and cur is not None:
            cur.setdefault(a.group(1), n)

    owners = {}
    for start, mod, regs in blocks:
        for r, ln in regs.items():
            owners.setdefault((mod, r), []).append((start, ln))

    bad = {r: v for r, v in owners.items() if len(v) > 1}
    if bad:
        for (mod, r), v in sorted(bad.items()):
            sitios = ", ".join("always en linea %d, asigna en %d" % (a, b)
                               for a, b in v)
            print("%s (%s):  %-16s %s" % (path, mod, r, sitios))
    return len(bad)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    total = sum(check(p) for p in sys.argv[1:])
    if total == 0:
        print("nbdrivers: sin excitadores duplicados")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
