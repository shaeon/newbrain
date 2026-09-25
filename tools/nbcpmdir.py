#!/usr/bin/env python3
"""Arranca CP/M en la cosimulacion (COP real + controladora de verdad) con
un disco EDSK en A:, hace DIR y comprueba que salen los nombres pedidos.

    python3 nbcpmdir.py ROM_COMPLETA DISCO.dsk NOMBRE [NOMBRE...]
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nbfdc_cop as F, nbcopreal as r
rom=open(sys.argv[1],'rb').read()
m=F.M(rom[:0x6000], rom[0xF000:0xF400], rom[0x7000:0x9000], rom[0xF400:0xF400+0x800],
      [F.f.Edsk(open(sys.argv[2],'rb').read()), None], 2.565)
m.corre(3_000_000)
def teclea(txt, extra):
    p=[]; t=m.t+2000
    for ch in txt:
        fl,b=F.mapa[ch]; p.append((t,t+32000,fl,b)); t+=80000
    m.corre(t-m.t+extra, p)
teclea('cpm\r', 2_800_000)
teclea('dir\r', 1_600_000)
texto=[s.rstrip() for s in r.pantalla(m,8) if s.strip()]
for s in texto: print('  |%s|' % s)
todo=' '.join(texto)
faltan=[n for n in sys.argv[3:] if n not in todo]
if 'CP/M Version 2.2' in todo and not faltan:
    print('nbcpmdir: OK (CP/M arranca y DIR lista %s)' % ', '.join(sys.argv[3:]))
else:
    print('nbcpmdir: FALLO (faltan %s)' % (faltan or 'el aviso de CP/M'))
    sys.exit(1)
