#!/usr/bin/env python3
"""
La controladora de disco de VERDAD, en Python: dos Z80 y un uPD765.

  * el NewBrain con sus ROMs y la ROM de disco del lado anfitrion
    (31#5#83.CPM, d413) en 8000;
  * el Z80 de la controladora con su propia ROM (d417, issue 1 o 2);
  * un uPD765 que lee y escribe imagenes EDSK.

Es el mismo cableado que el RTL (rtl/newbrain_fdc.v), y sirve para dos
cosas: comprobar que ese cableado es el bueno contra el codigo original de
Grundy, y ver que hace la maquina con un disco concreto.

Cableado, sacado de la propia ROM d417 y de fdc.cpp de MAME:

  Z80 de la controladora
    0000-7FFF  ROM d417 (8K, repetida)
    8000-FFFF  ventana al bus del NewBrain: direccion = {PA15, A14..A0}
               Sin paginacion solo responde la RAM compartida 9C00-9FFF.
    E/S (mascara 71h)
      00/01    uPD765 (estado / datos)
      20       registro auxiliar (escritura): b0 motor, b1 reset del 765,
               b2 TC, b5 PA15
      40       estado (lectura): b7 FDC ATT, b6 PAGING, b5 INT del 765

  NewBrain
    puerto FF con A9 = 1 (OUT (C),A con B = 02):
      b0 PAGING, b2 MA16, b3 MPM, b5 _FDC RESET, b7 FDC ATT

Uso:
  nbfdc.py NEWBRAIN.ROM d413.bin d417.bin imagenA.dsk [teclas...]

Las teclas son lo que se escribe tras el arranque, separadas por espacios;
"\\r" es Enter. Por defecto: load.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import z80                                          # noqa: E402
import nbcinta as c                                 # noqa: E402

RAM_COMP = 0x9C00


# ----------------------------------------------------------------------
# Imagen EDSK
# ----------------------------------------------------------------------
class Edsk:
    def __init__(self, datos):
        self.d = bytearray(datos)
        if not self.d.startswith(b'EXTENDED CPC DSK File'):
            raise ValueError('no es una imagen EDSK')
        self.pistas = self.d[48]
        self.caras = self.d[49]
        tam = self.d[52:52 + self.pistas * self.caras]
        self.sectores = {}          # (pista, cara) -> [(C, H, R, N, offset, largo)]
        p = 256
        for i in range(self.pistas * self.caras):
            if tam[i] == 0:
                continue
            t = self.d[p:p + 256]
            pista, cara, nsec = t[16], t[17], t[21]
            lista = []
            q = p + 256
            for k in range(nsec):
                e = t[24 + 8 * k:24 + 8 * k + 8]
                largo = e[6] | e[7] << 8
                lista.append((e[0], e[1], e[2], e[3], q, largo))
                q += largo
            self.sectores[(pista, cara)] = lista
            p += tam[i] * 256

    def busca(self, pista, cara, C, H, R, N):
        for s in self.sectores.get((pista, cara), []):
            if s[0] == C and s[1] == H and s[2] == R and s[3] == N:
                return s
        return None


# ----------------------------------------------------------------------
# uPD765, lo justo para lo que usa la d417, sin DMA
# ----------------------------------------------------------------------
LARGO_CMD = {0x03: 3, 0x07: 2, 0x08: 1, 0x0F: 3, 0x06: 9, 0x05: 9, 0x0D: 6,
             0x04: 2, 0x0A: 2, 0x11: 9}


class Upd765:
    def __init__(self, unidades, log):
        self.u = unidades           # lista de Edsk o None
        self.log = log
        self.reset()

    def reset(self):
        self.fase = 'cmd'
        self.cmd = []
        self.p = []
        self.res = []
        self.pcn = [0, 0, 0, 0]
        self.int_pend = []          # ST0 pendientes de SENSE INT
        self.buf = b''
        self.idx = 0
        self.wr_sector = None

    @property
    def int_linea(self):
        return bool(self.int_pend)

    def msr(self):
        if self.fase == 'cmd':
            return 0x80
        if self.fase == 'lee':
            return 0x80 | 0x40 | 0x20 | 0x10
        if self.fase == 'escribe':
            return 0x80 | 0x20 | 0x10
        if self.fase == 'res':
            return 0x80 | 0x40 | 0x10
        return 0x10

    def lee_dato(self):
        if self.fase == 'lee':
            v = self.buf[self.idx]
            self.idx += 1
            if self.idx >= len(self.buf):
                self.fin_rw()
            return v
        if self.fase == 'res':
            v = self.res.pop(0)
            if not self.res:
                self.fase = 'cmd'
            return v
        return 0xFF

    def escribe_dato(self, v):
        if self.fase == 'cmd':
            self.cmd.append(v)
            op = self.cmd[0] & 0x1F
            if len(self.cmd) >= LARGO_CMD.get(op, 1):
                self.ejecuta()
        elif self.fase == 'escribe':
            self.buf[self.idx] = v
            self.idx += 1
            if self.idx >= len(self.buf):
                img, off = self.wr_sector
                img.d[off:off + len(self.buf)] = self.buf
                self.fin_rw()

    def fin_rw(self):
        d = self.p[1]
        # EOT = R: sin TC el 765 acaba con "fin de cilindro"; la d417 lo
        # enmascara. Igual que hace u765.sv.
        st0 = 0x40 | (d & 7)
        st1 = 0x80
        C, H, R, N = self.p[2], self.p[3], self.p[4], self.p[5]
        self.res = [st0, st1, 0x00, C, H, R, N]
        self.fase = 'res'

    def error_rw(self, st1):
        d = self.p[1]
        self.res = [0x40 | (d & 7), st1, 0x00] + self.p[2:6]
        self.fase = 'res'

    def ejecuta(self):
        # El comando ya esta completo: se guarda aparte y se vacia la cola,
        # para que el siguiente empiece de cero.
        p = self.p = self.cmd
        self.cmd = []
        c0 = p[0]
        op = c0 & 0x1F
        if op == 0x03:                                  # SPECIFY
            self.fase = 'cmd'
        elif op == 0x07:                                # RECALIBRATE
            u = p[1] & 3
            self.pcn[u] = 0
            self.int_pend.append((0x20 | u, 0))
            self.fase = 'cmd'
        elif op == 0x0F:                                # SEEK
            u = p[1] & 3
            self.pcn[u] = p[2]
            self.int_pend.append((0x20 | (p[1] & 7), p[2]))
            self.fase = 'cmd'
            self.log('SEEK u%d -> %d' % (u, p[2]))
        elif op == 0x08:                                # SENSE INT
            if self.int_pend:
                st0, pcn = self.int_pend.pop(0)
                self.res = [st0, pcn]
            else:
                self.res = [0x80]
            self.fase = 'res'
        elif op in (0x06, 0x05):                        # READ / WRITE DATA
            u = p[1] & 3
            cara = (p[1] >> 2) & 1
            C, H, R, N = p[2], p[3], p[4], p[5]
            img = self.u[u] if u < len(self.u) else None
            que = 'lee' if op == 0x06 else 'ESCRIBE'
            if img is None:
                self.log('%s u%d sin disco' % (que, u))
                self.res = [0x48 | u, 0, 0] + p[2:6]     # not ready
                self.fase = 'res'
                return
            s = img.busca(self.pcn[u], cara, C, H, R, N)
            self.log('%s u%d pista %d cara %d  C%d H%d R%d N%d  %s'
                     % (que, u, self.pcn[u], cara, C, H, R, N,
                        'bien' if s else 'NO ENCONTRADO'))
            if s is None:
                self.error_rw(0x04)                     # no data
                return
            off, largo = s[4], s[5]
            if op == 0x06:
                self.buf = bytes(img.d[off:off + largo])
                self.idx = 0
                self.fase = 'lee'
            else:
                self.buf = bytearray(largo)
                self.idx = 0
                self.wr_sector = (img, off)
                self.fase = 'escribe'
        elif op == 0x0D:                                # FORMAT: no hace nada
            self.log('FORMAT (ignorado)')
            self.res = [p[1] & 7, 0, 0, 0, 0, 0, 0]
            self.fase = 'res'
        else:
            self.log('comando 765 desconocido %02X' % c0)
            self.res = [0x80]
            self.fase = 'res'


# ----------------------------------------------------------------------
# El Z80 de la controladora
# ----------------------------------------------------------------------
class Controladora:
    def __init__(self, d417, anfitrion, log):
        self.rom = bytes(d417[:0x2000]) + bytes(0x2000 - len(d417[:0x2000]))
        self.h = anfitrion
        self.log = log
        self.cpu = z80.Z80Machine()
        img = bytearray(0x10000)
        for base in range(0, 0x8000, 0x2000):
            img[base:base + 0x2000] = self.rom
        self.cpu.set_memory_block(0, bytes(img))
        self.cpu.mark_addrs(0x8000, 0x8000, self.cpu.READ_MARK | self.cpu.WRITE_MARK)
        self.cpu.mark_addrs(0x0000, 0x8000, self.cpu.WRITE_MARK)
        self.cpu.set_read_callback(self.rd)
        self.cpu.set_write_callback(self.wr)
        self.cpu.set_input_callback(self.inp)
        self.cpu.set_output_callback(self.outp)
        self.pa15 = 0
        self.motor = 0
        self.fuera = 0
        self.en_reset = False

    def dir_anfitrion(self, a):
        return (self.pa15 << 15) | (a & 0x7FFF)

    def rd(self, a):
        if a < 0x8000:
            return self.rom[a & 0x1FFF]
        h = self.dir_anfitrion(a)
        if RAM_COMP <= h < RAM_COMP + 0x400 and not self.h.paging:
            return self.h.ram_peek(h)
        self.fuera += 1
        if self.fuera < 5:
            self.log('LECTURA fuera de la RAM compartida: %04X' % h)
        return 0xFF

    def wr(self, a, v):
        if a < 0x8000:
            return
        h = self.dir_anfitrion(a)
        if RAM_COMP <= h < RAM_COMP + 0x400 and not self.h.paging:
            self.h.set_memory_block(h, bytes([v]))
            return
        self.fuera += 1
        if self.fuera < 5:
            self.log('ESCRITURA fuera de la RAM compartida: %04X' % h)

    def inp(self, port):
        p = port & 0x71
        if p in (0x00, 0x10):
            return self.h.fdc.msr()
        if p in (0x01, 0x11):
            return self.h.fdc.lee_dato()
        if p in (0x40, 0x41, 0x50, 0x51):
            return ((self.h.att << 7) | (self.h.paging << 6)
                    | (int(self.h.fdc.int_linea) << 5))
        return 0xFF

    def outp(self, port, v):
        p = port & 0x71
        if p in (0x01, 0x11):
            self.h.fdc.escribe_dato(v)
        elif p in (0x20, 0x21, 0x30, 0x31):
            self.motor = v & 1
            if v & 2:
                self.h.fdc.reset()
            self.pa15 = (v >> 5) & 1

    def reinicia(self):
        self.cpu.pc = 0
        self.cpu.sp = 0xFFFF
        self.cpu.iff1 = 0
        self.pa15 = 0
        self.motor = 0

    def paso(self):
        if self.en_reset:
            return
        self.cpu.ticks_to_stop = 1
        self.cpu.run()


# ----------------------------------------------------------------------
# El NewBrain con la ROM de disco y la RAM compartida
# ----------------------------------------------------------------------
class Maquina(c.Maquina):
    def __init__(self, rom, d413, d417, imagenes):
        super().__init__(rom)
        self.d413 = d413
        self.att = 0
        self.paging = 0
        self.fdc_log = []
        self.fdc = Upd765(imagenes, self.anota)
        self.ctl = Controladora(d417, self, self.anota)

    def anota(self, s):
        self.fdc_log.append((self.t, s))

    def map_run(self):
        img = bytearray(0x8000)
        img += self.d413[:0x1C00]
        img += bytearray(0x400)
        img += self.rom[0x0000:0x6000]
        self.set_memory_block(0x0000, bytes(img))
        self.mark_addrs(0x8000, 0x8000, self.WRITE_MARK)
        self.unmark_addrs(RAM_COMP, 0x400, self.WRITE_MARK)

    def outp(self, port, value):
        if (port & 0xFF) == 0xFF and (port & 0x0200):
            self.att = (value >> 7) & 1
            self.paging = value & 1
            reset = not (value & 0x20)
            if reset and not self.ctl.en_reset:
                self.fdc.reset()
                self.ctl.reinicia()
            self.ctl.en_reset = reset
            return
        return super().outp(port, value)


def ejecuta(m, n, teclas=None):
    """Como nbcinta.ejecuta, pero la controladora da un paso por cada uno
    del NewBrain: los dos Z80 van a 4 MHz."""
    km = c.teclado(m.rom)
    cola = list(teclas or '')
    prox = m.t
    for _ in range(n):
        m.t += 1
        if m.t == m.pwrup_after:
            m.pwrup = True
            m.map_run()
        if m.t > m.pwrup_after and m.t % c.CLK_PERIODO == 0:
            m.clkint = 0
        if cola and m.t >= prox and not m.cola_teclas:
            ch = cola.pop(0)
            m.cola_teclas.append(ch if isinstance(ch, int) else km[ch])
            prox = m.t + (600 if ch == '\r' else 80) * c.MS
        if m.t > m.pwrup_after:
            m.cop_tick()
        if m.iff1 and not m.int_disabled and m.int_pending():
            if m.halted:
                m.pc = (m.pc + 1) & 0xFFFF
            m.take_int()
        m.ticks_to_stop = 1
        m.run()
        m.ctl.paso()
    return m


def main():
    if len(sys.argv) < 5:
        print(__doc__)
        return 1
    rom = open(sys.argv[1], 'rb').read()[:0x6000]
    d413 = open(sys.argv[2], 'rb').read()
    d417 = open(sys.argv[3], 'rb').read()
    img = Edsk(open(sys.argv[4], 'rb').read())
    teclas = ' '.join(sys.argv[5:]) if len(sys.argv) > 5 else 'load'
    teclas = teclas.replace('\\r', '\r')
    if not teclas.endswith('\r'):
        teclas += '\r'

    m = Maquina(rom, d413, d417, [img, None])
    ejecuta(m, 3_000_000)
    ejecuta(m, 30000 * c.MS, teclas)
    for s in c.pantalla(m, 20):
        print('  |%s|' % s)
    print('--- 765 ---')
    for t, s in m.fdc_log[:80]:
        print('  %10d  %s' % (t, s))
    return 0


if __name__ == '__main__':
    sys.exit(main())
