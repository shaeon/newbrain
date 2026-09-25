#!/usr/bin/env python3
"""
Desensamblador de COP400 / COP420.

El mapa de opcodes esta tomado de t400_mnemonic_pack-p.vhd y t400_decoder.vhd
del core T400 de devsaurus, que es una implementacion en VHDL del
microcontrolador. Es preferible a transcribir una hoja de datos a mano: es
codigo que se sintetiza y funciona.

Particularidades del COP400 que conviene tener presentes al leer la salida:

  - La memoria de programa se organiza en **paginas de 64 palabras**. JP salta
    dentro de la pagina actual y JSRP llama siempre a la pagina 2.
  - Varias instrucciones **saltan la siguiente** si se cumple una condicion
    (SKC, SKE, SKMBZ, AISC cuando hay acarreo, XIS/XDS al desbordar Bd...).
    Por eso el flujo no se lee como en un Z80.
  - LQID y JID usan la propia ROM como tabla de datos.

Uso:  copdasm.py fichero.bin [inicio_hex] [fin_hex]
"""
import sys

# --- instrucciones de un byte, valor exacto -------------------------------
EXACTAS = {
    0x00: 'CLRA',   0x02: 'XOR',    0x10: 'CASC',  0x12: 'XABR',
    0x20: 'SKC',    0x21: 'SKE',    0x22: 'SC',    0x32: 'RC',
    0x40: 'COMP',   0x41: 'SKT',    0x44: 'NOP',   0x48: 'RET',
    0x49: 'RETSK',  0x4A: 'ADT',    0x4E: 'CBA',   0x4F: 'XAS',
    0x50: 'CAB',    0x31: 'ADD',    0xFF: 'JID',   0xBF: 'LQID',
}
# SKMBZ y RMB/SMB, que van por bits sueltos
EXACTAS.update({0x01: 'SKMBZ 0', 0x11: 'SKMBZ 1', 0x03: 'SKMBZ 2', 0x13: 'SKMBZ 3'})
EXACTAS.update({0x4C: 'RMB 0', 0x45: 'RMB 1', 0x42: 'RMB 2', 0x43: 'RMB 3'})
EXACTAS.update({0x4D: 'SMB 0', 0x47: 'SMB 1', 0x46: 'SMB 2', 0x4B: 'SMB 3'})

# --- segundo byte del prefijo 33 (EXT) ------------------------------------
EXT = {
    0x3C: 'CAMQ', 0x2C: 'CQMA', 0x21: 'SKGZ', 0x2A: 'ING', 0x2E: 'INL',
    0x28: 'ININ', 0x29: 'INIL', 0x3E: 'OBD',  0x3A: 'OMG',
    0x01: 'SKGBZ 0', 0x11: 'SKGBZ 1', 0x03: 'SKGBZ 2', 0x13: 'SKGBZ 3',
}


def decodifica(mem, pc):
    """Devuelve (texto, longitud, destino_de_salto_o_None)."""
    b = mem[pc]
    sig = mem[pc + 1] if pc + 1 < len(mem) else 0

    if b == 0x33:                                    # EXT
        if 0x50 <= sig <= 0x5F:
            return 'OGI %d' % (sig & 15), 2, None
        if 0x60 <= sig <= 0x6F:
            return 'LEI %d' % (sig & 15), 2, None
        return EXT.get(sig, 'EXT %02X' % sig), 2, None

    if b in EXACTAS:
        return EXACTAS[b], 1, None

    if 0x51 <= b <= 0x5F:
        return 'AISC %d' % (b & 15), 1, None
    if 0x60 <= b <= 0x63:                            # JMP, 10 bits
        d = ((b & 3) << 8) | sig
        return 'JMP %03Xh' % d, 2, d
    if 0x68 <= b <= 0x6B:                            # JSR, 10 bits
        d = ((b & 3) << 8) | sig
        return 'JSR %03Xh' % d, 2, d
    if b == 0x23:                                    # LDD / XAD
        return 'LDD %d,%d' % ((sig >> 4) & 3, sig & 15), 2, None
    if 0x70 <= b <= 0x7F:
        return 'STII %d' % (b & 15), 1, None
    if b in (0x05, 0x15, 0x25, 0x35):
        return 'LD %d' % ((b >> 4) & 3), 1, None
    if b in (0x06, 0x16, 0x26, 0x36):
        return 'X %d' % ((b >> 4) & 3), 1, None
    if b in (0x07, 0x17, 0x27, 0x37):
        return 'XDS %d' % ((b >> 4) & 3), 1, None
    if b in (0x04, 0x14, 0x24, 0x34):
        return 'XIS %d' % ((b >> 4) & 3), 1, None
    if (b & 0xC0) == 0x00 and (b & 0x0F) >= 0x08:    # LBI
        return 'LBI %d,%d' % ((b >> 4) & 3, (b & 15) ^ 15), 1, None

    if 0x80 <= b <= 0xFE:                            # JP dentro de pagina
        if 0x80 <= b <= 0xBE and (pc >> 6) in (2, 3):
            d = (2 << 6) | (b & 0x3F)                # JSRP, siempre pagina 2
            return 'JSRP %03Xh' % d, 1, d
        d = (pc & 0x3C0) | (b & 0x3F)
        return 'JP %03Xh' % d, 1, d

    return 'DB %02Xh' % b, 1, None


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    mem = open(sys.argv[1], 'rb').read()
    ini = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0
    fin = int(sys.argv[3], 16) if len(sys.argv) > 3 else len(mem)

    # Primera pasada: recoger destinos para poder marcarlos
    destinos = set()
    pc = 0
    while pc < len(mem):
        _, n, d = decodifica(mem, pc)
        if d is not None:
            destinos.add(d)
        pc += n

    pc = ini
    pagina = -1
    while pc < fin:
        if (pc >> 6) != pagina:
            pagina = pc >> 6
            print('\n; ---- pagina %d (%03Xh-%03Xh) ----' % (pagina, pagina << 6, (pagina << 6) | 63))
        texto, n, _ = decodifica(mem, pc)
        crudo = ' '.join('%02X' % x for x in mem[pc:pc + n])
        marca = '>' if pc in destinos else ' '
        print('%s%03X  %-6s %s' % (marca, pc, crudo, texto))
        pc += n
    return 0


if __name__ == '__main__':
    sys.exit(main())
