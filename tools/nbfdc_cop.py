"""Cosimulacion: Z80 con las ROMs del NewBrain, COP420 de verdad y la
controladora de disco de verdad (d413 + d417 + 765 sobre EDSK)."""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nbcopreal as r, nbfdc as f

class M(r.Maquina):
    def __init__(self, rom, cop_rom, d413, d417, imagenes, mhz=2.565):
        super().__init__(rom, cop_rom, mhz)
        self.d413 = d413; self.att = 0; self.paging = 0; self.fdc_log = []
        self.fdc = f.Upd765(imagenes, lambda s: self.fdc_log.append((self.t, s)))
        self.ctl = f.Controladora(d417, self, lambda s: self.fdc_log.append((self.t, s)))
    def map_run(self):
        img = bytearray(0x8000) + bytearray(self.d413[:0x1C00]) + bytearray(0x400) + self.rom[0:0x6000]
        self.set_memory_block(0, bytes(img))
        self.mark_addrs(0x8000, 0x8000, self.WRITE_MARK)
        self.unmark_addrs(0x9C00, 0x400, self.WRITE_MARK)
    def outp(self, port, value):
        if (port & 0xFF) == 0xFF and (port & 0x0200):
            self.att = (value >> 7) & 1; self.paging = value & 1
            reset = not (value & 0x20)
            if reset and not self.ctl.en_reset:
                self.fdc.reset(); self.ctl.reinicia()
            self.ctl.en_reset = reset
            return
        return super().outp(port, value)
    def corre(self, n, pulsaciones=()):
        for _ in range(n):
            super().corre(1, pulsaciones)
            self.ctl.paso()

mapa = {k: tuple(v) for k, v in json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'nb_mapa_teclas.json'))).items()}
def teclas(m, texto, desde, ms_tecla=60, ms_nl=400):
    p = []; t = desde
    for ch in texto:
        fl, b = mapa[ch]; p.append((t, t + 12000, fl, b))
        t += int((ms_nl if ch == '\r' else ms_tecla) * 400)
    return p, t
