#!/usr/bin/env python3
"""
Modelo de referencia del COP420 en Python.

Se escribe ANTES que el RTL a proposito. Una CPU de 4 bits con logica de
salto implicito es facil de equivocar, y depurarla en Verilog cuesta diez
veces mas que en Python. Este modelo sirve para dos cosas:

  1. comprobar que entendemos el juego de instrucciones, ejecutando la ROM
     real del NewBrain y viendo si hace algo con sentido;
  2. quedarse como referencia contra la que contrastar el core en Verilog,
     instruccion a instruccion.

El mapa de opcodes es el mismo de tools/copdasm.py, sacado del core T400.

Uso:  copsim.py cop420.bin [instrucciones]
"""
import sys


class COP420:
    def __init__(self, rom):
        self.rom = rom
        self.ram = [0] * 64          # 64 nibbles
        self.pc = 0
        self.a = 0                   # acumulador de 4 bits
        self.br = 0                  # banco de RAM, 2 bits
        self.bd = 0                  # digito, 4 bits
        self.c = 0                   # acarreo
        self.skl = 1                 # latch de salto
        self.en = 0                  # registro EN, de LEI
        self.q = 0                   # registro Q, 8 bits
        self.g = 0                   # puerto G, 4 bits
        self.d = 0                   # puerto D, 4 bits
        self.sio = 0
        self.sa = self.sb = self.sc = 0   # pila de 3 niveles
        self.skip = False
        self.t = 0                   # temporizador
        self.ciclos = 0
        self.l_in = 0xFF             # puerto L visto desde fuera
        self.in_port = 0xF           # patas IN
        self.traza = []

    # ---- acceso a memoria de datos -----------------------------------
    @property
    def m(self):
        return self.ram[(self.br << 4) | self.bd]

    @m.setter
    def m(self, v):
        self.ram[(self.br << 4) | self.bd] = v & 0xF

    def paso(self):
        pc = self.pc
        op = self.rom[pc]
        self.pc = (pc + 1) & 0x3FF
        self.ciclos += 1

        if self.skip:                 # la instruccion anterior pidio saltar
            self.skip = False
            if op in (0x33,) or (0x60 <= op <= 0x63) or (0x68 <= op <= 0x6B) or op == 0x23:
                self.pc = (self.pc + 1) & 0x3FF   # era de dos bytes
            return

        sig = self.rom[self.pc] if self.pc < len(self.rom) else 0

        # ---- aritmetica y acumulador ---------------------------------
        if op == 0x00:  self.a = 0
        elif op == 0x02: self.a ^= self.m
        elif op == 0x31:                                   # ADD
            self.a = (self.a + self.m) & 0xF
        elif op == 0x10:                                   # CASC
            r = (~self.a & 0xF) + self.m + self.c
            self.c = 1 if r > 0xF else 0
            self.a = r & 0xF
            self.skip = bool(self.c)
        elif op == 0x30:                                   # ASC
            r = self.a + self.m + self.c
            self.c = 1 if r > 0xF else 0
            self.a = r & 0xF
            self.skip = bool(self.c)
        elif op == 0x40: self.a = (~self.a) & 0xF          # COMP
        elif op == 0x4A:                                   # ADT
            self.a = (self.a + 10) & 0xF
        elif 0x51 <= op <= 0x5F:                           # AISC
            r = self.a + (op & 0xF)
            self.skip = r > 0xF
            self.a = r & 0xF
        elif op == 0x22: self.c = 1; self.skl = 1          # SC
        elif op == 0x32: self.c = 0; self.skl = 0          # RC

        # ---- saltos condicionales ------------------------------------
        elif op == 0x20: self.skip = bool(self.c)          # SKC
        elif op == 0x21: self.skip = (self.a == self.m)    # SKE
        elif op in (0x01, 0x11, 0x03, 0x13):               # SKMBZ
            bit = {0x01: 0, 0x11: 1, 0x03: 2, 0x13: 3}[op]
            self.skip = not (self.m >> bit) & 1
        elif op == 0x41: self.skip = bool(self.t); self.t = 0   # SKT

        # ---- memoria -------------------------------------------------
        elif op in (0x05, 0x15, 0x25, 0x35):               # LD
            self.a = self.m
            self.br ^= (op >> 4) & 3
        elif op in (0x06, 0x16, 0x26, 0x36):               # X
            self.a, self.m = self.m, self.a
            self.br ^= (op >> 4) & 3
        elif op in (0x04, 0x14, 0x24, 0x34):               # XIS
            self.a, self.m = self.m, self.a
            self.br ^= (op >> 4) & 3
            self.bd = (self.bd + 1) & 0xF
            self.skip = self.bd == 0
        elif op in (0x07, 0x17, 0x27, 0x37):               # XDS
            self.a, self.m = self.m, self.a
            self.br ^= (op >> 4) & 3
            self.bd = (self.bd - 1) & 0xF
            self.skip = self.bd == 0xF
        elif 0x70 <= op <= 0x7F:                           # STII
            self.m = op & 0xF
            self.bd = (self.bd + 1) & 0xF
        elif op == 0x23:                                   # LDD
            self.pc = (self.pc + 1) & 0x3FF
            self.a = self.ram[((sig >> 4) & 3) << 4 | (sig & 0xF)]
        elif (op & 0xC0) == 0x00 and (op & 0x0F) >= 0x08:  # LBI
            self.br = (op >> 4) & 3
            self.bd = (op & 0xF) ^ 0xF
        elif op in (0x4C, 0x45, 0x42, 0x43):               # RMB
            bit = {0x4C: 0, 0x45: 1, 0x42: 2, 0x43: 3}[op]
            self.m = self.m & ~(1 << bit)
        elif op in (0x4D, 0x47, 0x46, 0x4B):               # SMB
            bit = {0x4D: 0, 0x47: 1, 0x46: 2, 0x4B: 3}[op]
            self.m = self.m | (1 << bit)
        elif op == 0x4E: self.a = self.bd                  # CBA
        elif op == 0x50: self.bd = self.a                  # CAB
        elif op == 0x12: self.a, self.br = self.br, self.a & 3   # XABR

        # ---- control -------------------------------------------------
        elif op == 0x44: pass                              # NOP
        elif op == 0x48:                                   # RET
            self.pc = self.sa; self.sa = self.sb; self.sb = self.sc
        elif op == 0x49:                                   # RETSK
            self.pc = self.sa; self.sa = self.sb; self.sb = self.sc
            self.skip = True
        elif 0x60 <= op <= 0x63:                           # JMP
            self.pc = ((op & 3) << 8) | sig
        elif 0x68 <= op <= 0x6B:                           # JSR
            self.sc = self.sb; self.sb = self.sa
            self.sa = (self.pc + 1) & 0x3FF
            self.pc = ((op & 3) << 8) | sig
        elif 0x80 <= op <= 0xFE:
            if 0x80 <= op <= 0xBE and (pc >> 6) in (2, 3):
                self.sc = self.sb; self.sb = self.sa; self.sa = self.pc
                self.pc = (2 << 6) | (op & 0x3F)           # JSRP
            else:
                self.pc = (pc & 0x3C0) | (op & 0x3F)       # JP
        elif op == 0xFF:                                   # JID
            tabla = (pc & 0x300) | (self.a << 4) | self.m
            self.pc = (pc & 0x300) | self.rom[tabla]
        elif op == 0xBF:                                   # LQID
            tabla = (pc & 0x300) | (self.a << 4) | self.m
            self.q = self.rom[tabla]

        # ---- entrada y salida ----------------------------------------
        elif op == 0x33:
            self.pc = (self.pc + 1) & 0x3FF
            self.ext(sig)
        elif op == 0x4F:                                   # XAS
            self.a, self.sio = self.sio, self.a

        else:
            self.traza.append((pc, 'opcode desconocido %02X' % op))

    def ext(self, sig):
        if sig == 0x3C:                                    # CAMQ
            self.q = (self.a << 4) | self.m
            self.traza.append((self.pc, 'CAMQ -> %02X' % self.q))
        elif sig == 0x2C:                                  # CQMA
            self.a = (self.q >> 4) & 0xF
            self.m = self.q & 0xF
        elif sig == 0x2E: self.a = (self.l_in >> 4) & 0xF  # INL
        elif sig == 0x28: self.a = self.in_port            # ININ
        elif sig == 0x2A: self.a = self.g                  # ING
        elif sig == 0x3A: self.g = self.a                  # OMG
        elif sig == 0x3E: self.d = self.a                  # OBD
        elif 0x50 <= sig <= 0x5F: self.g = sig & 0xF       # OGI
        elif 0x60 <= sig <= 0x6F: self.en = sig & 0xF      # LEI
        elif sig == 0x21: self.skip = (self.g == 0)        # SKGZ
        elif sig in (0x01, 0x11, 0x03, 0x13):              # SKGBZ
            bit = {0x01: 0, 0x11: 1, 0x03: 2, 0x13: 3}[sig]
            self.skip = not (self.g >> bit) & 1


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    rom = open(sys.argv[1], 'rb').read()
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 200000

    cpu = COP420(rom)
    visitadas = set()
    for _ in range(n):
        visitadas.add(cpu.pc)
        cpu.paso()

    desconocidas = [t for t in cpu.traza if 'desconocido' in t[1]]
    camq = [t for t in cpu.traza if 'CAMQ' in t[1]]

    print('instrucciones ejecutadas : %d' % cpu.ciclos)
    print('direcciones distintas    : %d de 1024' % len(visitadas))
    print('opcodes desconocidos     : %d' % len(desconocidas))
    for pc, t in desconocidas[:10]:
        print('   %03X  %s' % (pc, t))
    print('bytes puestos en Q       : %d' % len(camq))
    for pc, t in camq[:8]:
        print('   %03X  %s' % (pc, t))
    print('PC final %03X  A=%X  B=%d,%02d  C=%d  G=%X  EN=%X'
          % (cpu.pc, cpu.a, cpu.br, cpu.bd, cpu.c, cpu.g, cpu.en))
    return 0


if __name__ == '__main__':
    sys.exit(main())
