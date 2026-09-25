#!/usr/bin/env python3
"""EDSK -> raw, con el orden de las herramientas de disco: C0H0, C0H1,
C1H0, ... y dentro de cada pista los sectores por ID. Sirve para sacar las
pistas de sistema de un disco EDSK y pasarselas a dir2dsk.py -s.

    python3 nbdsk2raw.py DISCO.dsk DISCO.img
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nbfdc

def main():
    e = nbfdc.Edsk(open(sys.argv[1], 'rb').read())
    out = bytearray()
    for c in range(e.pistas):
        for h in range(e.caras):
            for s in sorted(e.sectores.get((c, h), []), key=lambda x: x[2]):
                out += e.d[s[4]:s[4] + s[5]]
    open(sys.argv[2], 'wb').write(out)
    print('%s: %d pistas x %d caras, %d bytes' % (sys.argv[2], e.pistas, e.caras, len(out)))

if __name__ == '__main__':
    main()
