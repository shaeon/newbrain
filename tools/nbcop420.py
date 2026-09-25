#!/usr/bin/env python3
"""
COP420 en Python, portado del nucleo de MAME (cop400.cpp y cop400op.hxx).

Lo justo para ejecutar la ROM del COP del NewBrain (cop420-guw.ic419) con
MICROBUS: el Z80 escribe en Q y baja G0 (microbus_w) y lee Q (microbus_r),
como en MAME. Las patas se conectan con funciones:

    lee_in()  -> 4 bits       lee_g()  -> 4 bits
    escribe_g(v)              escribe_d(v)
    lee_si() -> 0/1           escribe_so(v), escribe_sk(v)

paso() ejecuta un ciclo de instruccion (un byte, como MAME).
"""


class Cop420:
    def __init__(self, rom, lee_in=None, lee_g=None, escribe_g=None,
                 escribe_d=None, lee_si=None, escribe_so=None, escribe_sk=None):
        self.rom = bytes(rom[:1024]).ljust(1024, b'\x00')
        self.lee_in = lee_in or (lambda: 0xF)
        self.lee_g = lee_g or (lambda: 0)
        self.escribe_g = escribe_g or (lambda v: None)
        self.escribe_d = escribe_d or (lambda v: None)
        self.lee_si = lee_si or (lambda: 0)
        self.escribe_so = escribe_so or (lambda v: None)
        self.escribe_sk = escribe_sk or (lambda v: None)
        self.ram = [0] * 64
        self.reset()

    # ------------------------------------------------------------------
    def reset(self):
        self.pc = 0
        self.a = 0
        self.b = 0
        self.c = 0
        self.q = 0
        self.en = 0
        self.g = 0
        self.escribe_g(0)
        self.escribe_d(0)
        self.sa = self.sb = self.sc = 0
        self.sio = 0
        self.si_hist = 0
        self.skl = 1
        self.t = 0
        self.skt_latch = 1
        self.il = 0
        self.in_hist = [0, 0, 0, 0]
        self.skip = False
        self.last_skip = False
        self.second = False
        self.opcode = 0
        self.skip_lbi = 0
        self.ciclos = 0

    # ---- microbus ----------------------------------------------------
    def microbus_r(self):
        return self.q

    def microbus_w(self, v):
        self.wg(self.g & 0xE)
        self.q = v & 0xFF

    # ---- ayudas ------------------------------------------------------
    def M(self):
        return self.ram[self.b & 0x3F]

    def setM(self, v):
        self.ram[self.b & 0x3F] = v & 0xF

    def wg(self, v):
        self.g = v & 0xF
        self.escribe_g(self.g)

    def push(self, v):
        self.sc = self.sb
        self.sb = self.sa
        self.sa = v & 0x3FF

    def pop(self):
        self.pc = self.sa
        self.sa = self.sb
        self.sb = self.sc

    @staticmethod
    def largo(op):
        if op in (0x23, 0x33) or 0x60 <= op <= 0x6F:
            return 2
        return 1

    @staticmethod
    def transfiere(op):
        return (op & 0x80) == 0x80 or (op & 0xF0) == 0x60 or (op & 0xFE) == 0x48

    # ---- un ciclo de instruccion -------------------------------------
    def paso(self):
        operand = self.rom[self.pc]
        self.pc = (self.pc + 1) & 0x3FF
        if not self.second:
            self.opcode = operand
        op = self.opcode

        if (not self.second and (self.en & 2) and (self.il & 2)
                and not self.transfiere(op) and not self.skip_lbi):
            self.il &= ~2
            self.last_skip = self.skip
            self.skip = False
            self.push(self.pc)
            self.pc = 0x0FF
            self.en &= ~2
        elif not self.second and self.largo(op) > 1:
            self.second = True
        elif self.skip:
            self.skip = False
            self.second = False
        else:
            if not self.second and op in (0xFF, 0xBF):        # JID, LQID
                if op == 0xBF:
                    self.push(self.pc)
                self.pc = (self.pc & 0x300) | (self.a << 4) | self.M()
                self.second = True
            else:
                self.ejecuta(op, operand)
                if self.skip_lbi > 0:
                    self.skip_lbi -= 1
                self.second = False

        self.serie()
        self.inil()
        # temporizador: T avanza cada 4 ciclos y se desborda cada 1024
        self.ciclos += 1
        if self.ciclos % 4 == 0:
            self.t = (self.t + 1) & 0xFF
            if self.t == 0:
                self.skt_latch = 1

    def serie(self):
        if self.en & 1:
            # Modo contador: SIO baja uno por cada flanco de bajada de SI que
            # haya pasado al menos dos ciclos en cada nivel (patron 1100).
            # Es como el COP mide la cinta: cuenta flancos en una ventana.
            self.escribe_so((self.en >> 3) & 1)
            self.si_hist = ((self.si_hist << 1) | (self.lee_si() & 1)) & 0xF
            if self.si_hist == 0xC:
                self.sio = (self.sio - 1) & 0xF
        else:
            self.escribe_so((self.sio >> 3) & 1 if self.en & 8 else 0)
            self.sio = ((self.sio << 1) | (self.lee_si() & 1)) & 0xF

    def inil(self):
        v = self.lee_in()
        for i in range(4):
            self.in_hist[i] = ((self.in_hist[i] << 1) | ((v >> i) & 1)) & 0xFF
            if (self.in_hist[i] & 7) == 4:
                self.il |= (1 << i)

    def sk_update(self):
        self.escribe_sk(self.skl if self.en & 1 else 0)

    # ---- instrucciones -------------------------------------------------
    def ejecuta(self, op, operand):
        a, M = self.a, self.M
        if op == 0x00:                                 # CLRA
            self.a = 0
        elif op in (0x01, 0x11, 0x03, 0x13):           # SKMBZ
            bit = {0x01: 0, 0x11: 1, 0x03: 2, 0x13: 3}[op]
            if not (M() >> bit) & 1:
                self.skip = True
        elif op == 0x02:                               # XOR
            self.a = a ^ M()
        elif op & 0xCF in (0x04, 0x05, 0x06, 0x07) and op < 0x40:
            r = op & 0x30
            k = op & 0x0F
            if k == 0x05:                              # LD
                self.a = M()
                self.b ^= r
            elif k == 0x06:                            # X
                t = M(); self.setM(a); self.a = t
                self.b ^= r
            elif k == 0x04:                            # XIS
                t = M(); self.setM(a); self.a = t
                bd = ((self.b & 0xF) + 1) & 0xF
                self.b = ((self.b & 0x70) | bd) ^ r
                if bd == 0:
                    self.skip = True
            else:                                      # XDS
                t = M(); self.setM(a); self.a = t
                bd = ((self.b & 0xF) - 1) & 0xF
                self.b = ((self.b & 0x70) | bd) ^ r
                if bd == 0xF:
                    self.skip = True
        elif 0x08 <= op <= 0x0F or 0x18 <= op <= 0x1F or 0x28 <= op <= 0x2F or 0x38 <= op <= 0x3F:
            self.lbi(op)                               # LBI corta
        elif op == 0x10:                               # CASC
            v = (a ^ 0xF) + M() + self.c
            if v > 0xF:
                self.c = 1; self.skip = True; v &= 0xF
            else:
                self.c = 0
            self.a = v
        elif op == 0x12:                               # XABR
            br = a & 3
            self.a = (self.b >> 4) & 0xF
            self.b = (br << 4) | (self.b & 0xF)
        elif op == 0x20:                               # SKC
            if self.c:
                self.skip = True
        elif op == 0x21:                               # SKE
            if a == M():
                self.skip = True
        elif op == 0x22:                               # SC
            self.c = 1
        elif op == 0x23:
            rd = operand & 0x7F
            if operand <= 0x3F:                        # LDD
                self.a = self.ram[rd & 0x3F]
            elif 0x80 <= operand <= 0xBF:              # XAD
                t = self.a
                self.a = self.ram[rd & 0x3F]
                self.ram[rd & 0x3F] = t
        elif op == 0x30:                               # ASC
            v = a + self.c + M()
            if v > 0xF:
                self.c = 1; self.skip = True; v &= 0xF
            else:
                self.c = 0
            self.a = v
        elif op == 0x31:                               # ADD
            self.a = (a + M()) & 0xF
        elif op == 0x32:                               # RC
            self.c = 0
        elif op == 0x33:
            self.op33(operand)
        elif op == 0x40:                               # COMP
            self.a = a ^ 0xF
        elif op == 0x41:                               # SKT
            if self.skt_latch:
                self.skt_latch = 0
                self.skip = True
        elif op in (0x42, 0x43, 0x45, 0x4C):           # RMB
            bit = {0x4C: 0, 0x45: 1, 0x42: 2, 0x43: 3}[op]
            self.setM(M() & ~(1 << bit))
        elif op in (0x4D, 0x47, 0x46, 0x4B):           # SMB
            bit = {0x4D: 0, 0x47: 1, 0x46: 2, 0x4B: 3}[op]
            self.setM(M() | (1 << bit))
        elif op == 0x44:                               # NOP
            pass
        elif op == 0x48:                               # RET (COP420)
            self.pop()
            self.skip = self.last_skip
        elif op == 0x49:                               # RETSK
            self.pop()
            self.skip = True
        elif op == 0x4A:                               # ADT
            self.a = (a + 10) & 0xF
        elif op == 0x4E:                               # CBA
            self.a = self.b & 0xF
        elif op == 0x4F:                               # XAS
            t = self.sio
            self.sio = a
            self.a = t
            if self.skl != self.c:
                self.skl = self.c
                self.sk_update()
        elif op == 0x50:                               # CAB
            self.b = (self.b & 0x70) | a
        elif 0x51 <= op <= 0x5F:                       # AISC
            v = a + (op & 0xF)
            if v > 0xF:
                self.skip = True
                v &= 0xF
            self.a = v
        elif 0x60 <= op <= 0x63:                       # JMP
            self.pc = ((op & 3) << 8) | operand
        elif 0x68 <= op <= 0x6B:                       # JSR
            self.push(self.pc)
            self.pc = ((op & 3) << 8) | operand
        elif 0x70 <= op <= 0x7F:                       # STII
            self.setM(op & 0xF)
            bd = ((self.b & 0xF) + 1) & 0xF
            self.b = (self.b & 0x70) | bd
        elif op == 0xBF:                               # LQID (segundo paso)
            self.q = operand
            self.pop()
        elif op == 0xFF:                               # JID (segundo paso)
            self.pc = (self.pc & 0x300) | operand
        elif op & 0x80:                                # JP / JSRP
            pagina = (self.pc >> 6) & 0xF          # como MAME: PC ya avanzado
            if pagina in (2, 3):
                self.pc = (self.pc & 0x380) | (op & 0x7F)
            elif (op & 0xC0) == 0xC0:
                self.pc = (self.pc & 0x3C0) | (op & 0x3F)
            else:
                self.push(self.pc)
                self.pc = 0x80 | (op & 0x3F)
        else:
            pass                                       # ilegal

    def lbi(self, operand):
        self.skip_lbi += 1
        if self.skip_lbi > 1:
            return
        self.skip_lbi += 1
        if operand & 0x80:
            self.b = operand & 0x7F
        else:
            self.b = (operand & 0x30) | (((operand & 0xF) + 1) & 0xF)

    def op33(self, o):
        if 0x50 <= o <= 0x5F:                          # OGI
            self.wg(o & 0xF)
        elif 0x60 <= o <= 0x6F:                        # LEI
            if self.en != (o & 0xF):
                self.en = o & 0xF
                self.sk_update()
        elif 0x80 <= o <= 0xBF:                        # LBI larga
            self.lbi(o)
        elif o in (0x01, 0x11, 0x03, 0x13):            # SKGBZ
            bit = {0x01: 0, 0x11: 1, 0x03: 2, 0x13: 3}[o]
            if not (self.lee_g() >> bit) & 1:
                self.skip = True
        elif o == 0x21:                                # SKGZ
            if self.lee_g() == 0:
                self.skip = True
        elif o == 0x28:                                # ININ
            self.a = self.lee_in() & 0xF
        elif o == 0x29:                                # INIL
            self.a = (self.il & 9)
            self.il = 0
        elif o == 0x2A:                                # ING
            self.a = self.lee_g() & 0xF
        elif o == 0x2C:                                # CQMA
            self.setM(self.q >> 4)
            self.a = self.q & 0xF
        elif o == 0x2E:                                # INL (sin uso aqui)
            self.setM(0xF)
            self.a = 0xF
        elif o == 0x3A:                                # OMG
            self.wg(self.M())
        elif o == 0x3C:                                # CAMQ
            self.q = ((self.a << 4) | self.M()) & 0xFF
        elif o == 0x3E:                                # OBD
            self.escribe_d(self.b & 0xF)
