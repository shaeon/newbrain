#!/usr/bin/env python3
"""
El NewBrain con el modulo de expansion y la paginacion, en Python, con el
mismo decodificado que el RTL (newbrain_mem.v y newbrain_pager.v):

  sin paginar   0000-7FFF RAM interna, 8000 la ROM del sistema paginado (POS),
                A000/C000/E000 las ROMs AB/CD/EF
  paginado      ocho ranuras de 8K, cada una con su pagina:
                RAM: indice fisico = 107 - pagina (107..104 la interna)
                ROM: 122 AB, 121 CD, 120 EF, 123 POS, 124 MTV, 125 ACI

  puerto 2      registros de pagina: indice {A12,A15,A14,A13},
                pagina = D6..D0 tal cual
  puerto 255    con A8: b0 paginacion, b2 juego alternativo (A16)
  puerto 15     UST2 (configuracion de arranque)

Sirve para ver si el sistema paginado arranca con las ROMs de verdad y
cuanta memoria ve.

Uso:  nbpag.py FICHERO.ROM [KB de RAM]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nbcinta as c                             # noqa: E402

ROM_PAG = {122: 0, 121: 1, 120: 2, 123: 4, 124: 5, 125: 6}


class Maquina(c.Maquina):
    def __init__(self, rom_completa, ram_kb=512):
        super().__init__(rom_completa[:0x6000])
        self.roms = [rom_completa[i * 0x2000:(i + 1) * 0x2000] for i in range(3)]
        self.roms += [b'\xFF' * 0x2000]                       # 3: disco (no se usa)
        eim = rom_completa[0x9000:0xF000]
        self.roms += [eim[0:0x2000], eim[0x2000:0x4000], eim[0x4000:0x6000]]
        self.ram_paginas = ram_kb // 8
        self.fisica = bytearray(0x200000)                     # 2 MB
        # Como en la maquina (y en el emulador de cdesp, que arranca con las
        # ROMs originales): el juego principal con el mapa natural y el
        # segundo vacio (lee FF). La ROM del sistema paginado solo escribe
        # las ranuras que cambia y da por hecho lo demas.
        self.pagreg = [107, 106, 105, 104, 123, 122, 121, 120] + [None] * 8
        self.paginando = False
        self.a16 = 0
        self.ranuras = [None] * 8                            # lo mapeado ahora
        self.map_boot()
        self.cambios_pagina = 0
        self.log = []

    # ---- mapa -----------------------------------------------------------
    def pagina_de(self, ranura):
        return self.pagreg[(self.a16 << 3) | ranura]

    def que_hay(self, ranura):
        """('ram', indice) o ('rom', banco) o ('nada', 0)"""
        if not self.pwrup:
            return ('rom', 2)
        if not self.paginando:
            if ranura < 4:
                return ('ram', ranura)
            if ranura == 4:
                return ('rom', 4)                            # POS
            return ('rom', ranura - 5)
        p = self.pagina_de(ranura)
        if p is None:
            return ('nada', 0)
        if p in ROM_PAG:
            return ('rom', ROM_PAG[p])
        idx = (107 - p) & 0x7F
        if idx < self.ram_paginas:
            return ('ram', idx)
        return ('nada', 0)

    def vuelca(self):
        """Devuelve a la RAM fisica lo que se ha escrito en las ranuras RAM."""
        mem = self.memory
        for r, cosa in enumerate(self.ranuras):
            if cosa and cosa[0] == 'ram':
                i = cosa[1] * 0x2000
                self.fisica[i:i + 0x2000] = mem[r * 0x2000:(r + 1) * 0x2000]

    def remapea(self):
        self.vuelca()
        mem = self.memory
        for r in range(8):
            cosa = self.que_hay(r)
            self.ranuras[r] = cosa
            base = r * 0x2000
            if cosa[0] == 'ram':
                i = cosa[1] * 0x2000
                mem[base:base + 0x2000] = self.fisica[i:i + 0x2000]
                self.unmark_addrs(base, 0x2000, self.WRITE_MARK)
            else:
                datos = self.roms[cosa[1]] if cosa[0] == 'rom' else b'\xFF' * 0x2000
                mem[base:base + 0x2000] = datos
                self.mark_addrs(base, 0x2000, self.WRITE_MARK)

    def map_boot(self):
        if not hasattr(self, 'roms'):          # aun dentro del constructor base
            return super().map_boot()
        self.ranuras = [None] * 8
        self.remapea()

    def map_run(self):
        if self.ranuras == [None] * 8:
            self.ranuras = [('rom', 2)] * 8
        self.remapea()

    def ram_peek(self, a):
        # El video lee la RAM interna directamente, este paginada o no
        if a < 0x8000 and hasattr(self, 'fisica') and self.paginando:
            self.vuelca()
            return self.fisica[a]
        return self.memory[a & 0xFFFF]

    # ---- E/S del modulo -------------------------------------------------
    def outp(self, port, value):
        p = port & 0xFF
        if p == 2:
            idx = (((port >> 12) & 1) << 3) | ((port >> 13) & 7)
            pag = value & 0x7F           # el byte tal cual, 7 bits, como cdesp
            self.pagreg[idx] = pag
            self.cambios_pagina += 1
            if self.paginando:
                self.remapea()
            return
        if p == 0xFF and (port & 0x100):
            antes = (self.paginando, self.a16)
            self.paginando = bool(value & 1)
            self.a16 = (value >> 2) & 1
            if (self.paginando, self.a16) != antes:
                self.log.append((self.t, 'paginacion %s, juego %d' % (
                    'SI' if self.paginando else 'no', self.a16)))
                self.remapea()
            return
        if p == 0x01:                                       # ENREG2
            return
        return super().outp(port, value)

    def inp(self, port):
        p = port & 0xFF
        if p == 0x15:                                       # UST2
            # b2 video normal, b3 red, b4 40 columnas, b6 pantalla
            return 0x04 | 0x08 | 0x10 | 0x40
        return super().inp(port)


def main():
    rom = open(sys.argv[1], 'rb').read()
    kb = int(sys.argv[2]) if len(sys.argv) > 2 else 512
    m = Maquina(rom, kb)
    c.ejecuta(m, 6_000_000)
    print('RAM %dK, cambios de pagina %d' % (kb, m.cambios_pagina))
    for t, s in m.log[:10]:
        print('  %9d  %s' % (t, s))
    print('  registros: %s' % ' '.join('-' if x is None else '%d' % x for x in m.pagreg))
    for s in c.pantalla(m, 6):
        print('  |%s|' % s)
    print('PC %04X' % m.pc)
    return m


if __name__ == '__main__':
    main()
