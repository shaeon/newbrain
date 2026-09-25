#!/usr/bin/env python3
"""
Carga y grabacion de cinta contra la ROM real, en Python.

Modelo del COP420 HLE **tal como queda en el RTL** (newbrain_cop_hle.v y
newbrain_tape.v): mismas reglas de cuando se genera cada vector, mismo
analizador de bloque y mismos retardos. Si esto no carga, el RTL tampoco.

Lo que hace:

  1. arranca la ROM y teclea un programa BASIC;
  2. SAVE: recoge los bytes que la ROM entrega por CASSOUT y los guarda en
     formato de fichero de cdesp (00 + bloque + nueve ceros por bloque);
  3. NEW, y LOAD de ese mismo fichero;
  4. LIST, y comprueba que el programa ha vuelto.

Uso:  nbcinta.py NEWBRAIN.ROM [fichero.bas]

Con un fichero .bas externo se salta el SAVE y se carga ese.

Unidad de tiempo: una instruccion del Z80, ~2,5 us. 400 instrucciones = 1 ms.
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nbsim import NewBrain   # noqa: E402

MS = 400                     # instrucciones por milisegundo

# Politica del HLE, igual que en el RTL
REGINT_PERIODO = 20 * MS
CLK_PERIODO = 20 * MS
CASS_ARRANQUE = 5 * MS       # del CASSCOM al primer byte de cada bloque
CASS_ENTRE = 2 * MS          # entre bytes, contado desde la lectura anterior
COLA_CEROS = 9


class Maquina(NewBrain):
    def __init__(self, rom, cinta=b''):
        super().__init__(rom)
        self.t = 0
        self.cinta = bytearray(cinta)
        self.pos = 0
        self.grabado = bytearray()
        self.cop_state = 'idle'
        self.regint_prox = REGINT_PERIODO
        self.reproduce = False
        self.graba = False
        self.cass_cmd = 0
        self.espera = 0
        self.fase = 'sync'       # analizador de bloque
        self.resto = 0
        self.errores = []
        self.vectores = []
        self.brk = False
        self.descarta_dato = False
        self.aborta_pend = False
        self.descarta = 0
        self.cola = 0
        self.aborta_pend = False
        self.descarta = 0
        self.cola = 0

    # ------------------------------------------------------------------
    # Analizador de bloque. Sabe donde acaba cada bloque para parar la
    # reproduccion justo despues de la suma, como el emulador de cdesp.
    # ------------------------------------------------------------------
    def avanza_analizador(self, b):
        f = self.fase
        if f == 'sync':
            self.fase = 'lenl'
        elif f == 'lenl':
            self.resto = b
            self.fase = 'lenh'
        elif f == 'lenh':
            self.resto |= b << 8
            self.fase = 'datos' if self.resto else 'tipo'
        elif f == 'datos':
            self.resto -= 1
            if self.resto == 0:
                self.fase = 'tipo'
        elif f == 'tipo':
            self.fase = 'chkl'
        elif f == 'chkl':
            self.fase = 'chkh'
        elif f == 'chkh':
            self.fase = 'sync'
            return True           # fin de bloque
        return False

    def restante_bloque(self):
        """Bytes que faltan para acabar el bloque en curso, sin la cola."""
        f = self.fase
        if f == 'sync':
            return 0
        if f in ('lenl', 'lenh'):
            return 0              # longitud desconocida: no se puede
        if f == 'datos':
            return self.resto + 3
        return {'tipo': 3, 'chkl': 2, 'chkh': 1}[f]

    def aplica_descartes(self):
        # como newbrain_tape.v: primero N bytes, luego hasta 9 ceros
        while self.descarta and self.pos < len(self.cinta):
            self.pos += 1
            self.descarta -= 1
        while (not self.descarta and self.cola and self.pos < len(self.cinta)
               and self.cinta[self.pos] == 0):
            self.pos += 1
            self.cola -= 1
        if self.pos < len(self.cinta) and self.cinta[self.pos] != 0:
            self.cola = 0

    # ------------------------------------------------------------------
    def lanza(self, vec):
        self.cop_vec = vec
        self.copint = 0
        self.cop_state = 'wait_rd'
        self.vectores.append((self.t, vec))

    def cop_tick(self):
        if self.cop_state != 'idle':
            return
        if self.espera > 0:
            self.espera -= 1
        regint_due = self.t >= self.regint_prox
        self.aplica_descartes()
        if self.reproduce:
            # Durante la reproduccion SOLO hay CASSIN. Un REGINT pondria
            # READY sin dato y TCHR devolveria basura: ERROR 131.
            if self.brk:
                self.brk = False
                self.lanza(0x23 | (self.cass_cmd & 0x0C))
            elif self.espera == 0 and self.pos < len(self.cinta) and not self.descarta and not self.cola:
                self.lanza(0x20 | (self.cass_cmd & 0x0C))
            if regint_due:
                self.regint_prox = self.t + REGINT_PERIODO
            return
        if self.graba:
            if self.espera == 0:
                self.lanza(0x40 | (self.cass_cmd & 0x0C))
            if regint_due:
                self.regint_prox = self.t + REGINT_PERIODO
            return
        if self.cola_teclas:
            self.lanza(0x30)
        elif regint_due:
            self.regint_prox = self.t + REGINT_PERIODO
            self.lanza(0x00)

    # ------------------------------------------------------------------
    def inp(self, port):
        p = port & 0xFF
        grp = (p >> 2) & 7
        if grp == 1 and (p & 3) == 2:
            st = self.cop_state
            if st == 'wait_rd':
                self.copint = 1
                self.cop_state = 'wait_ack'
                return self.cop_vec
            if st == 'key1':
                self.cop_state = 'key2'
                return 0x85
            if st == 'key2':
                self.cop_state = 'idle'
                return self.cola_teclas.pop(0)
            if st == 'cassin':
                b = self.cinta[self.pos]
                self.pos += 1
                self.cop_state = 'idle'
                self.espera = CASS_ENTRE
                if self.aborta_pend:
                    self.aborta_pend = False
                    r = self.restante_bloque() or 0
                    self.fase = 'sync'
                    if r > 1:
                        self.descarta = r - 1
                    if r:
                        self.cola = COLA_CEROS
                elif self.reproduce and self.avanza_analizador(b):
                    self.reproduce = False
                    self.cola = COLA_CEROS
                return b
            return 0x80
        return super().inp(port)

    def outp(self, port, value):
        p = port & 0xFF
        grp = (p >> 2) & 7
        if not (grp == 1 and (p & 3) == 2):
            return super().outp(port, value)
        st = self.cop_state
        if st == 'wait_ack':
            vec = self.cop_vec
            ack = value
            hi = vec & 0xF0
            # 1) el comando que viaja en el reconocimiento
            if (ack & 0xF0) == 0x80 and (ack & 0x0A):
                if ack & 0x04:
                    if not self.reproduce:
                        self.reproduce = True
                        self.graba = False
                        self.cass_cmd = ack & 0x0F
                        self.espera = CASS_ARRANQUE
                        self.fase = 'sync'
                else:
                    if not self.graba:
                        self.graba = True
                        self.reproduce = False
                        self.cass_cmd = ack & 0x0F
                        self.espera = CASS_ARRANQUE
                        # el byte de sincronismo lo pone el COP
                        self.grabado.append(0)
            elif (ack & 0xF0) == 0xD0:
                # NULLCOM: la ROM ha acabado (o abortado) el bloque
                if self.reproduce:
                    self.errores.append((self.t, 'bloque abortado, fase %s' % self.fase))
                    self.reproduce = False
                    if hi == 0x20 and not (vec & 1):
                        self.aborta_pend = True
                    else:
                        r = self.restante_bloque() or 0
                        self.fase = 'sync'
                        if r:
                            self.descarta = r
                            self.cola = COLA_CEROS
                if self.graba:
                    self.graba = False
                    self.descarta_dato = hi == 0x40
            # 2) la rama que toma la rutina segun el vector
            if hi == 0x30:
                self.cop_state = 'key1'
            elif hi == 0x20 and not (vec & 1):
                self.cop_state = 'cassin'
            elif hi == 0x20 and (vec & 2) and self.reproduce:
                self.reproduce = False
                r = self.restante_bloque() or 0
                self.fase = 'sync'
                if r:
                    self.descarta = r
                    self.cola = COLA_CEROS
                self.cop_state = 'idle'
            elif hi == 0x40:
                self.cop_state = 'cassout'
            elif hi == 0x00 and (ack & 0xF0) in (0xA0, 0xB0):
                self.cop_left = 18 if (ack & 0xF0) == 0xA0 else 6
                self.copint = 0
                self.cop_state = 'data'
            else:
                self.cop_state = 'idle'
            return
        if st == 'cassout':
            if self.descarta_dato:
                self.descarta_dato = False
            else:
                self.grabado.append(value)
            self.cop_state = 'idle'
            self.espera = CASS_ENTRE
            return
        if st == 'data':
            self.cop_left -= 1
            if self.cop_left == 0:
                self.copint = 1
                self.cop_state = 'idle'
            return


def teclado(rom):
    kt = rom[0x1A7:0x1E7]
    m = {}
    for code, ch in enumerate(kt):
        if 32 <= ch < 127 and chr(ch) not in m:
            m[chr(ch)] = code
    m['\r'] = 30
    return m


def pantalla(m, filas=12):
    el = 128 if (m.tvtl & 0x40) else 64
    ll = 80 if (m.tvtl & 0x40) else 40
    base = m.tv_addr + (4 if (m.tvtl & 0x40) else 2)
    out = []
    for fila in range(filas):
        a = base + fila * el
        s = ''
        for x in range(ll):
            b = m.ram_peek(a + x)
            if b == 0:
                break
            s += chr(b) if 32 <= b < 127 else '.'
        out.append(s)
    return out


def ejecuta(m, n, teclas=None):
    """Corre n instrucciones. teclas: cadena a teclear, una cada 30 ms."""
    km = teclado(m.rom)
    cola = list(teclas or '')
    prox = m.t
    for _ in range(n):
        m.t += 1
        if m.t == m.pwrup_after:
            m.pwrup = True
            m.map_run()
        if m.t > m.pwrup_after and m.t % CLK_PERIODO == 0:
            m.clkint = 0
        if cola and m.t >= prox and not m.cola_teclas and not m.reproduce and not m.graba:
            ch = cola.pop(0)
            m.cola_teclas.append(km[ch])
            prox = m.t + (600 if ch == '\r' else 80) * MS
        if m.t > m.pwrup_after:
            m.cop_tick()
        if m.iff1 and not m.int_disabled and m.int_pending():
            if m.halted:
                m.pc = (m.pc + 1) & 0xFFFF
            m.take_int()
        m.ticks_to_stop = 1
        m.run()
    return m


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    rom = open(sys.argv[1], 'rb').read()[:0x6000]

    if len(sys.argv) > 2:
        cinta = open(sys.argv[2], 'rb').read()
        print('cinta externa: %d bytes' % len(cinta))
    else:
        m = Maquina(rom)
        ejecuta(m, 3_000_000)
        prog = '10 print 12345\r20 goto 10\r'
        ejecuta(m, 6000 * MS, prog + 'save\r')
        ejecuta(m, 3000 * MS)
        print('--- SAVE ---')
        for s in pantalla(m, 8):
            print('  |%s|' % s)
        cinta = bytes(m.grabado)
        print('bytes grabados: %d' % len(cinta))
        print('  ' + cinta.hex())
        open('/tmp/nbcinta.bas', 'wb').write(cinta)
        cinta = bytes(cinta)

    # Escenario de error: una copia con la suma mal y detras la buena. El
    # primer LOAD tiene que dar ERROR 132 y el segundo cargar la buena, lo
    # que prueba que el descarte del bloque abandonado deja la cinta en su
    # sitio.
    if len(sys.argv) <= 2:
        mala = bytearray(cinta)
        mala[len(mala) - 11] ^= 0x01      # suma baja del bloque de datos
        m = Maquina(rom, bytes(mala) + cinta)
        ejecuta(m, 3_000_000)
        ejecuta(m, 6000 * MS, 'load\r')
        print('--- LOAD de la copia corrupta ---')
        for s_ in pantalla(m, 6):
            print('  |%s|' % s_)
        ok1 = '132' in '\n'.join(pantalla(m, 10))
        p1 = m.pos
        ejecuta(m, 6000 * MS, 'load\r')
        ejecuta(m, 1500 * MS, 'list\r')
        ejecuta(m, 500 * MS)
        print('--- segundo LOAD + LIST ---')
        for s_ in pantalla(m, 12):
            print('  |%s|' % s_)
        ok2 = '12345' in '\n'.join(pantalla(m, 12))
        print('posicion tras el error: %d (la buena empieza en %d)' % (p1, len(mala)))
        print('error 132 en la mala: %s, carga la buena despues: %s' % (ok1, ok2))
        for t, e in m.errores:
            print('  %8d  %s' % (t, e))
        if not (ok1 and ok2):
            print('RESULTADO: FALLO')
            return 2

    m = Maquina(rom, cinta)
    ejecuta(m, 3_000_000)
    ejecuta(m, 6000 * MS, 'load\r')
    ejecuta(m, 1500 * MS, 'list\r')
    ejecuta(m, 500 * MS)
    print('--- LOAD + LIST ---')
    for s in pantalla(m, 10):
        print('  |%s|' % s)
    print('bytes servidos: %d de %d' % (m.pos, len(m.cinta)))
    tipos = {}
    for _, v in m.vectores:
        tipos[v & 0xF0] = tipos.get(v & 0xF0, 0) + 1
    print('vectores: %s' % ', '.join('%02X x%d' % kv for kv in sorted(tipos.items())))
    for t, e in m.errores:
        print('  %8d  %s' % (t, e))
    texto = '\n'.join(pantalla(m, 10))
    ok = '12345' in texto and 'ERROR' not in texto.upper()
    print('RESULTADO:', 'OK' if ok else 'FALLO')
    return 0 if ok else 2


if __name__ == '__main__':
    sys.exit(main())
