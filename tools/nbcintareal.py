import sys, json
sys.path.insert(0,'/home/claude/p/src/newbrain/tools')
import nbcopreal as r, nbwav

mapa={k:tuple(v) for k,v in json.load(open('/tmp/mapa_teclas.json')).items()}

class M(r.Maquina):
    """COP real con un magnetofono: la cinta solo avanza con el motor en
    marcha (G1 o G3 a cero) y entra por TDI = TPIN xor TDO."""
    def __init__(self, rom, cop_rom, mhz, semis_us):
        super().__init__(rom, cop_rom, mhz)
        self.semis = semis_us          # duracion de cada semiperiodo, us
        self.pos_cinta = 0; self.resto = semis_us[0] if semis_us else 0
        self.nivel = 0; self.cop_g = 0; self.cop_dd = 0
        self.cop.lee_si = self.si
        og = self.cop.escribe_g
        def g(v): self.cop_g = v; og(v)
        self.cop.escribe_g = g
        od = self.cop.escribe_d
        def dd(v): self.cop_dd = v; od(v)
        self.cop.escribe_d = dd
    def motor(self):
        return not (self.cop_g & 2) or not (self.cop_g & 8)
    def si(self):
        tdo = (self.cop_dd >> 1) & 1
        return (self.nivel if self.motor() else 0) ^ tdo if self.motor() else 0
    def corre(self, n, pulsaciones=()):
        for _ in range(n):
            if self.motor() and self.pos_cinta < len(self.semis):
                self.resto -= r.US_POR_INSTR
                while self.resto <= 0 and self.pos_cinta < len(self.semis):
                    self.pos_cinta += 1; self.nivel ^= 1
                    if self.pos_cinta < len(self.semis): self.resto += self.semis[self.pos_cinta]
            super().corre(1, pulsaciones)

def semis_de_wav(muestras, rate=44100):
    out=[]; n=1; ant=muestras[0]
    for v in muestras[1:]:
        if (v>0)!=(ant>0): out.append(n*1e6/rate); n=1
        else: n+=1
        ant=v
    return out

def teclas(texto, desde, ms=80, ms_nl=600, dura_ms=40):
    p=[]; t=desde
    for ch in texto:
        f,b=mapa[ch]; p.append((t,t+int(dura_ms*400),f,b)); t+=int((ms_nl if ch=='\r' else ms)*400)
    return p, t
