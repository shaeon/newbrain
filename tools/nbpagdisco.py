import sys
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import nbpag, nbfdc as f, nbcinta as c

class M(nbpag.Maquina):
    """Sistema paginado + controladora de disco de verdad. La ventana de la
    controladora (sus direcciones 8000-FFFF) sale al bus del NewBrain con
    {PA15, A14..A0} y pasa por la paginacion, como la CPU."""
    def __init__(self, rom, imagenes, ram_kb=512):
        super().__init__(rom, ram_kb)
        self.d413 = rom[0x7000:0x9000]
        self.roms[3] = self.d413                      # banco 3: ROM de disco
        nbpag.ROM_PAG[119] = 3                        # en la pagina 119
        self.att = 0; self.paging = 0; self.fdc_log = []
        self.fdc = f.Upd765(imagenes, lambda s: self.fdc_log.append((self.t, s)))
        self.ctl = f.Controladora(rom[0xF400:0xF400 + 0x800], self,
                                  lambda s: self.fdc_log.append((self.t, s)))
        m = self
        def rd(a):
            if a < 0x8000:
                return m.ctl.rom[a & 0x1FFF]
            return m.memory[(m.ctl.pa15 << 15) | (a & 0x7FFF)]
        def wr(a, v):
            if a < 0x8000:
                return
            h = (m.ctl.pa15 << 15) | (a & 0x7FFF)
            cosa = m.ranuras[h >> 13]
            if cosa and cosa[0] == 'ram':
                m.memory[h] = v
        self.ctl.rd = rd
        self.ctl.wr = wr
        self.ctl.cpu.set_read_callback(rd)
        self.ctl.cpu.set_write_callback(wr)

    def outp(self, port, value):
        if (port & 0xFF) == 0xFF and (port & 0x0200):
            self.att = (value >> 7) & 1
            # el bit PAGING del registro de control: la d417 lo lee en su
            # puerto 40 para elegir el camino paginado (puntero en 8079)
            self.paging = value & 1
            reset = not (value & 0x20)
            if reset and not self.ctl.en_reset:
                self.fdc.reset(); self.ctl.reinicia()
            self.ctl.en_reset = reset
            self.ctl_paging = value & 1
            # Como cdesp: el mismo byte lleva tambien los bits de paginacion
            # y se aplican (b0 encendida, b2 juego alternativo)
            antes = (self.paginando, self.a16)
            self.paginando = bool(value & 1)
            self.a16 = (value >> 2) & 1
            if (self.paginando, self.a16) != antes:
                self.log.append((self.t, 'paginacion %s, juego %d (desde disco)' % (
                    'SI' if self.paginando else 'no', self.a16)))
                self.remapea()
            return
        return super().outp(port, value)

def ejecuta(m, n, teclas=None):
    km = c.teclado(m.rom)
    cola = list(teclas or '')
    prox = m.t
    for _ in range(n):
        m.t += 1
        if m.t == m.pwrup_after:
            m.pwrup = True; m.map_run()
        if m.t > m.pwrup_after and m.t % c.CLK_PERIODO == 0:
            m.clkint = 0
        if cola and m.t >= prox and not m.cola_teclas:
            ch = cola.pop(0)
            m.cola_teclas.append(ch if isinstance(ch, int) else km[ch])
            prox = m.t + (600 if ch == '\r' else 80) * c.MS
        if m.t > m.pwrup_after:
            m.cop_tick()
        if m.iff1 and not m.int_disabled and m.int_pending():
            if m.halted: m.pc = (m.pc + 1) & 0xFFFF
            m.take_int()
        m.ticks_to_stop = 1
        m.run()
        m.ctl.paso()
