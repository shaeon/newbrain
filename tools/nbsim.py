#!/usr/bin/env python3
"""
Ejecuta una ROM del NewBrain contra un modelo del core, en Python.

No sustituye a la simulacion del RTL: lo que hace es comprobar si la ROM se
comporta como esperamos con NUESTRO mapa de memoria y NUESTRA decodificacion
de puertos. Sirve para saber si un problema esta en el diseño o en como
entendimos la maquina, que sobre hardware es indistinguible.

Uso:  nbsim.py fichero.rom [instrucciones]
"""
import sys
import z80


class NewBrain(z80.Z80Machine):
    def __init__(self, rom, pwrup_after=20_000):
        super().__init__()
        self.rom = rom
        self.ram = bytearray(0x8000)
        self.pwrup = False
        self.pwrup_after = pwrup_after
        self.n = 0
        self.enrg1 = 0
        self.tvtl = 0
        self.tv_addr = 0
        self.tv_writes = 0
        self.clkint = 1          # 0 = pendiente
        self.copint = 1
        self.cop_state = 'idle'
        self.cop_out = 0x80
        self.cop_vec = 0x00
        self.cop_left = 0
        self.vfd = bytearray(18)
        self.int_taken = 0
        self.traza = None
        self.cass_visto = False
        self.cmd_hist = {}
        self.tv_antes = 0
        self.int_antes = 0
        self.cola_teclas = []      # bytes de tecla pendientes de entregar
        self.tecla_entregada = []
        self.log = []
        # La memoria se carga como bloque nativo y solo se marcan para
        # escritura las zonas que no son RAM. Con una retrollamada por acceso
        # esto tardaba minutos; asi va a velocidad de la libreria.
        self.mark_addrs(0x8000, 0x8000, self.WRITE_MARK)
        self.set_write_callback(self.wr_ignore)
        self.set_input_callback(self.inp)
        self.set_output_callback(self.outp)
        self.map_boot()

    def map_boot(self):
        # Mientras PWRUP esta bajo, el banco 2 se ve en todo el espacio
        img = bytearray()
        for _ in range(8):
            img += self.rom[0x4000:0x6000]
        self.set_memory_block(0x0000, bytes(img))

    def map_run(self):
        img = bytearray(0x8000)                 # RAM
        img += b'\xFF' * 0x2000                 # hueco
        img += self.rom[0x0000:0x6000]          # ROM en A000
        self.set_memory_block(0x0000, bytes(img))

    def wr_ignore(self, addr, value):
        pass

    # La memoria de la maquina vive dentro del estado con un desplazamiento
    # fijo; se localizo buscando un patron conocido.
    MEM_OFS = 44

    def ram_peek(self, addr):
        return bytes(self.get_state_view())[self.MEM_OFS + (addr & 0xFFFF)]

    # ---- E/S ---------------------------------------------------------
    def inp(self, port):
        p = port & 0xFF
        grp = (p >> 2) & 7
        if grp == 5:
            if p & 2:                        # UST_B
                return 0x5C | 0x02           # sin CTS, sin cinta
            # UST_A: b0 y b1 multiplexados por ENREG, b2 MAINSP,
            # b5 _CLKINT, b7 _COPINT. El selector se consume al leer.
            sel = getattr(self, 'ust_sel', 0)
            self.ust_sel = 0
            b0 = {0: 1, 1: 1, 2: 0 if getattr(self, 'reproduce', False) else 1,
                  3: 1}[(sel >> 2) & 3]
            b1 = {0: 0 if self.pwrup else 1, 1: 0, 2: 1, 3: 1}[sel & 3]
            v = 0x04 | 0x08 | 0x10 | 0x40 | b0 | (b1 << 1)
            if self.clkint:
                v |= 0x20
            if self.copint:
                v |= 0x80
            return v
        if grp == 1 and (p & 3) == 2:        # COP
            if self.traza is not None and len(self.traza) < 60:
                self.traza.append((self.n, 'IN', self.cop_state, self.cop_out))
            if self.cop_state == 'wait_rd':
                self.copint = 1
                self.cop_state = 'wait_ack'
                return self.cop_vec
            if self.cop_state == 'key1':
                self.cop_state = 'key2'
                return 0x85
            if self.cop_state == 'key2':
                b = self.cop_out
                self.tecla_entregada.append((self.n, b))
                self.cop_out = 0x80
                self.cop_state = 'idle'
                return b
            return self.cop_out
        if grp == 1 and (p & 3) == 0:        # INTCON
            self.clkint = 1
            return 0xFF
        return 0xFF

    # ---- interrupciones ----------------------------------------------
    def int_pending(self):
        return ((self.enrg1 & 1) == 0 and self.clkint == 0) or self.copint == 0

    def take_int(self):
        # IM 1: apila el PC y salta a 0038
        sp = (self.sp - 2) & 0xFFFF
        self.set_memory_block(sp, bytes([self.pc & 0xFF, self.pc >> 8]))
        self.sp = sp
        self.pc = 0x0038
        self.iff1 = 0
        self.iff2 = 0
        self.int_taken += 1

    def outp(self, port, value):
        p = port & 0xFF
        grp = (p >> 2) & 7
        if grp == 1:
            if (p & 3) == 0:
                self.clkint = 1
            elif (p & 3) == 2:               # COP
                if self.traza is not None and len(self.traza) < 60:
                    self.traza.append((self.n, 'OUT', self.cop_state, value))
                self.cmd_hist[value & 0xF0] = self.cmd_hist.get(value & 0xF0, 0) + 1
                if (value & 0xF0) in (0x80, 0x90) and not self.cass_visto:
                    self.cass_visto = True
                    self.log.append((self.n, 'comando de cassette %02X' % value))
                if self.cop_state == 'wait_ack':
                    if (self.cop_vec & 0xF0) == 0x30:    # rama de teclado
                        self.cop_out = self.cola_teclas.pop(0)
                        self.cop_state = 'key1'
                    elif (value & 0xF0) == 0xA0:     # DISPCOM: 18 bytes
                        self.cop_left = 18
                        self.copint = 0
                        self.cop_state = 'data'
                    elif (value & 0xF0) == 0xB0:     # TIMCOM: 6 bytes
                        self.cop_left = 6
                        self.copint = 0
                        self.cop_state = 'data'
                    else:
                        self.cop_state = 'idle'
                elif self.cop_state == 'data':
                    if self.cop_left <= 18:
                        self.vfd[18 - self.cop_left] = value
                    self.cop_left -= 1
                    if self.cop_left == 0:
                        self.copint = 1
                        self.cop_state = 'idle'
            elif (p & 3) == 3:
                self.ust_sel = (value >> 4) & 0xF
                if (value ^ self.enrg1) & 0x04:
                    self.log.append((self.n, 'ENRG1=%02X video %s'
                                     % (value, 'ON' if value & 4 else 'off')))
                self.enrg1 = value
        elif grp == 2:
            if p & 1:
                self.tv_addr = value << 7
                self.tv_writes += 1
            else:
                self.tv_addr |= 0x40
        elif grp == 3:
            self.tvtl = value


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    rom = open(sys.argv[1], 'rb').read()[:0x6000]
    limite = int(sys.argv[2]) if len(sys.argv) > 2 else 3_000_000

    m = NewBrain(rom)
    _a3 = sys.argv[3] if len(sys.argv) > 3 else ''
    m.tecla = int(_a3, 0) if _a3 and _a3 != 'barrido' and not _a3.startswith('teclas=') else None
    m.pulsar_en = int(sys.argv[4]) if len(sys.argv) > 4 else 150_000
    m.barrido = (len(sys.argv) > 3 and sys.argv[3] == 'barrido')
    m.secuencia = None
    if len(sys.argv) > 3 and sys.argv[3].startswith('teclas='):
        m.secuencia = [int(x) for x in sys.argv[3][7:].split(',')]
        m.tecla = None
    m.vec_low = 0
    m.tecla2 = int(sys.argv[5], 0) if len(sys.argv) > 5 else None
    m.tecla3 = int(sys.argv[6], 0) if len(sys.argv) > 6 else None
    if m.barrido:
        m.tecla = None
    hist = {}
    ultimo = None
    for i in range(limite):
        m.n = i
        if i == m.pwrup_after:
            m.pwrup = True
            m.map_run()
            m.log.append((i, 'PWRUP arriba, mapa normal'))
        # 50 Hz de reloj y de REGINT del COP, a escala de instrucciones
        if i % 4000 == 0 and i > m.pwrup_after:
            m.clkint = 0
        if i % 4000 == 2000 and i > m.pwrup_after and m.cop_state == 'idle':
            m.copint = 0
            m.cop_vec = (0x30 | m.vec_low) if m.cola_teclas else 0x00
            m.cop_state = 'wait_rd'

        # La traza arranca en cuanto la ROM manda un comando de cassette
        if m.traza is None and m.cass_visto:
            m.traza = []
            m.tv_antes = m.tv_writes
            m.int_antes = m.int_taken
        if m.secuencia and i >= m.pulsar_en and (i - m.pulsar_en) % 12000 == 0:
            k = (i - m.pulsar_en) // 12000
            if k < len(m.secuencia) and not m.cola_teclas:
                m.cola_teclas.append(m.secuencia[k])
        elif m.barrido and i >= m.pulsar_en and (i - m.pulsar_en) % 8000 == 0:
            k = (i - m.pulsar_en) // 8000
            if k < 64 and not m.cola_teclas:
                m.cola_teclas.append(k)
        elif i == m.pulsar_en and m.tecla is not None:
            m.cola_teclas.append(m.tecla)
        elif i == m.pulsar_en + 20000 and m.tecla2 is not None and not m.cola_teclas:
            m.cola_teclas.append(m.tecla2)
        elif i == m.pulsar_en + 40000 and m.tecla3 is not None and not m.cola_teclas:
            m.cola_teclas.append(m.tecla3)

        if m.iff1 and m.int_pending():
            if m.halted:
                m.pc = (m.pc + 1) & 0xFFFF
            m.take_int()

        try:
            m.run()
        except Exception as e:
            print('parado en PC=%04X: %s' % (m.pc, e))
            break
        pc = m.pc
        hist[pc >> 12] = hist.get(pc >> 12, 0) + 1
        if m.halted:
            print('HALT en PC=%04X tras %d instrucciones' % (pc, i))
            break
        ultimo = pc

    print('instrucciones ejecutadas: %d' % (i + 1))
    print('PC final: %04X' % (ultimo or 0))
    print('video habilitado: %s' % ('SI' if m.enrg1 & 4 else 'NO'))
    print('escrituras de direccion de trama: %d' % m.tv_writes)
    print('interrupciones atendidas: %d' % m.int_taken)
    print('buffer del display: %r' % bytes(m.vfd))
    print('TVTL = %02X, direccion de trama = %04X' % (m.tvtl, m.tv_addr))
    print()
    print('reparto del PC por bloques de 4K:')
    for k in sorted(hist):
        print('  %X000-%Xfff  %8d' % (k, k, hist[k]))
    print()
    if m.tecla is not None:
        print('tecla inyectada: %02X, entregada %d veces' % (m.tecla, len(m.tecla_entregada)))
        print('tramas pintadas: %d antes de la tecla, %d despues'
              % (m.tv_antes, m.tv_writes - m.tv_antes))
        print('interrupciones: %d antes, %d despues'
              % (m.int_antes, m.int_taken - m.int_antes))
    # Volcado de la pantalla: EL bytes por fila desde la direccion de trama
    el = 128 if (m.tvtl & 0x40) else 64
    ll = 80 if (m.tvtl & 0x40) else 40
    base = m.tv_addr + (4 if (m.tvtl & 0x40) else 2)
    print('pantalla (base %04X, EL=%d):' % (base, el))
    for fila in range(6):
        a = base + fila * el
        linea = ''
        for x in range(ll):
            b = m.ram_peek(a + x)
            if b == 0:
                break
            linea += chr(b) if 32 <= b < 127 else '.'
        print('  |%s|' % linea)
    print()
    nombres = {0x80:'CASSCOM', 0x8C:'CASSLOD', 0x90:'PASSCOM', 0xA0:'DISPCOM',
               0xB0:'TIMCOM', 0xC0:'PDNCOM', 0xD0:'NULLCOM', 0xF0:'RESCOM'}
    print('escrituras al COP por nibble alto:')
    for k in sorted(m.cmd_hist):
        print('   %02X %-8s %6d' % (k, nombres.get(k,''), m.cmd_hist[k]))
    print()
    if m.traza:
        print('trafico del COP alrededor de la pulsacion:')
        for n, d, st, v in m.traza[:40]:
            print('  %8d  %-3s estado=%-8s %02X' % (n, d, st, v))
        print()
    print('sucesos:')
    for n, t in m.log[:40]:
        print('  %8d  %s' % (n, t))
    return 0


if __name__ == '__main__':
    sys.exit(main())
