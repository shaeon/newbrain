#!/usr/bin/env python3
"""
El NewBrain con su COP420 DE VERDAD: la ROM del Z80 contra la ROM del COP
(cop420-guw.ic419), ejecutada por nbcop420.py, con el teclado cableado como
en MAME (contador CD4024, biestable CD4076).

Sirve para ver que hace falta para que el COP real arranque la maquina y
entregue teclas, cosa que un banco de pruebas con un Z80 de mentira no puede
decir: el COP se comporta segun lo que le vaya mandando la ROM del Z80.

Uso:  nbcopreal.py NEWBRAIN.ROM [MHz del COP]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nbsim                                   # noqa: E402
import nbcop420                                # noqa: E402

US_POR_INSTR = 2.5                             # el Z80 del modelo, de media


class Maquina(nbsim.NewBrain):
    def __init__(self, rom, cop_rom, cop_mhz=4.0):
        super().__init__(rom)
        self.t = 0
        self.teclas = {}                       # fila -> bits pulsados
        self.cd4024 = 0
        self.d403 = 0
        self.k6 = 0
        self.escrituras_cop = []
        self.lecturas_cop = []
        self.cop = nbcop420.Cop420(
            cop_rom,
            lee_in=self.cop_in, lee_g=self.cop_g_in,
            escribe_g=self.cop_g_out, escribe_d=self.cop_d_out)
        self.copint = 1
        # ciclos de instruccion del COP por instruccion del Z80
        self.cop_por_z80 = US_POR_INSTR * cop_mhz / 16.0
        self.cop_acum = 0.0

    # ---- cableado del COP, como MAME (newbrain.cpp) -------------------
    def latch(self):
        return self.d403 if self.k6 else 0xF

    def cop_in(self):
        return 0xE | ((self.latch() >> 2) & 1)          # IN0 = K8 = Q2

    def cop_g_in(self):
        q = self.latch()
        return (((q >> 1) & 1) << 1) | ((q & 1) << 2) | (((q >> 3) & 1) << 3)

    def cop_g_out(self, g):
        self.copint = 0 if (g & 1) else 1              # _COPINT = NOT G0

    def cop_d_out(self, d):
        k4 = not (d & 1)
        k6 = 0 if (d & 4) else 1
        if k4:
            self.cd4024 = 0
        elif self.k6 and not k6:
            self.cd4024 = (self.cd4024 + 1) & 0x7F
        if not self.k6 and k6:
            self.d403 = self.teclas.get(self.cd4024 & 0xF, 0) & 0xF
        self.k6 = k6

    # ---- el puerto 06 va al microbus ---------------------------------
    def inp(self, port):
        p = port & 0xFF
        if (p >> 2) & 7 == 1 and (p & 3) == 2:
            v = self.cop.microbus_r()
            if len(self.lecturas_cop) < 400:
                self.lecturas_cop.append((self.t, v))
            return v
        return super().inp(port)

    def outp(self, port, value):
        p = port & 0xFF
        if (p >> 2) & 7 == 1 and (p & 3) == 2:
            self.cop.microbus_w(value)
            if len(self.escrituras_cop) < 400:
                self.escrituras_cop.append((self.t, value))
            return
        return super().outp(port, value)

    # ---- tiempo --------------------------------------------------------
    def corre(self, n, pulsaciones=()):
        """pulsaciones: [(desde_instr, hasta_instr, fila, bit)]"""
        for _ in range(n):
            self.t += 1
            if self.t == self.pwrup_after:
                self.pwrup = True
                self.map_run()
            if self.t > self.pwrup_after and self.t % 8000 == 0:
                self.clkint = 0
            self.teclas = {}
            for desde, hasta, fila, bit in pulsaciones:
                if desde <= self.t < hasta:
                    self.teclas[fila] = self.teclas.get(fila, 0) | (1 << bit)
            self.cop_acum += self.cop_por_z80
            while self.cop_acum >= 1.0:
                self.cop_acum -= 1.0
                self.cop.paso()
            if self.iff1 and not self.int_disabled and self.int_pending():
                if self.halted:
                    self.pc = (self.pc + 1) & 0xFFFF
                self.take_int()
            self.ticks_to_stop = 1
            self.run()


def pantalla(m, filas=6):
    el = 128 if (m.tvtl & 0x40) else 64
    ll = 80 if (m.tvtl & 0x40) else 40
    base = m.tv_addr + (4 if (m.tvtl & 0x40) else 2)
    out = []
    for f in range(filas):
        s = ''
        for x in range(ll):
            b = m.ram_peek(base + f * el + x)
            if b == 0:
                break
            s += chr(b) if 32 <= b < 127 else '.'
        out.append(s)
    return out


def main():
    rom = open(sys.argv[1], 'rb').read()
    mhz = float(sys.argv[2]) if len(sys.argv) > 2 else 4.0
    m = Maquina(rom[:0x6000], rom[0xF000:0xF400], mhz)
    m.corre(3_000_000)
    print('tras arrancar: video %s' % ('SI' if m.enrg1 & 4 else 'NO'))
    for s in pantalla(m):
        print('  |%s|' % s)
    return m


if __name__ == '__main__':
    main()
