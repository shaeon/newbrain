#!/usr/bin/env python3
"""
Desensamblador del COP420, fiel al de MAME (cop420ds.cpp).

El anterior (copdasm.py) confundia JSRP con JP: los codigos 80-BE son
JSRP (llamada a la pagina 2) fuera de las paginas 2 y 3, y JP dentro de
ellas. Con eso mal, el flujo del programa no se podia seguir.

Uso:  nbcop420dasm.py cop420.bin [desde hasta]
"""
import sys

SIMPLES = {
    0x00: 'CLRA', 0x01: 'SKMBZ 0', 0x02: 'XOR', 0x03: 'SKMBZ 2',
    0x04: 'XIS 0', 0x05: 'LD 0', 0x06: 'X 0', 0x07: 'XDS 0',
    0x10: 'CASC', 0x11: 'SKMBZ 1', 0x12: 'XABR', 0x13: 'SKMBZ 3',
    0x14: 'XIS 1', 0x15: 'LD 1', 0x16: 'X 1', 0x17: 'XDS 1',
    0x20: 'SKC', 0x21: 'SKE', 0x22: 'SC',
    0x24: 'XIS 2', 0x25: 'LD 2', 0x26: 'X 2', 0x27: 'XDS 2',
    0x30: 'ASC', 0x31: 'ADD', 0x32: 'RC',
    0x34: 'XIS 3', 0x35: 'LD 3', 0x36: 'X 3', 0x37: 'XDS 3',
    0x40: 'COMP', 0x41: 'SKT', 0x42: 'RMB 2', 0x43: 'RMB 3', 0x44: 'NOP',
    0x45: 'RMB 1', 0x46: 'SMB 2', 0x47: 'SMB 1', 0x48: 'RET',
    0x49: 'RETSK', 0x4A: 'ADT', 0x4B: 'SMB 3', 0x4C: 'RMB 0',
    0x4D: 'SMB 0', 0x4E: 'CBA', 0x4F: 'XAS', 0x50: 'CAB',
    0xBF: 'LQID', 0xFF: 'JID',
}
PREF33 = {0x01: 'SKGBZ 0', 0x03: 'SKGBZ 2', 0x11: 'SKGBZ 1', 0x13: 'SKGBZ 3',
          0x21: 'SKGZ', 0x28: 'ININ', 0x29: 'INIL', 0x2A: 'ING',
          0x2C: 'CQMA', 0x2E: 'INL', 0x3A: 'OMG', 0x3C: 'CAMQ', 0x3E: 'OBD'}


def uno(rom, pc):
    op = rom[pc]
    sig = rom[(pc + 1) & 0x3FF]
    if (0x80 <= op <= 0xBE) or (0xC0 <= op <= 0xFE):
        if 0x80 <= pc < 0x100:              # paginas 2 y 3
            return 1, 'JP %03X' % ((pc & 0x380) | (op & 0x7F))
        if (op & 0xC0) == 0xC0:
            return 1, 'JP %03X' % ((pc & 0x3C0) | (op & 0x3F))
        return 1, 'JSRP %03X' % (0x80 | (op & 0x3F))
    if 0x08 <= op <= 0x0F:
        return 1, 'LBI 0,%d' % (((op & 0xF) + 1) & 0xF)
    if 0x18 <= op <= 0x1F:
        return 1, 'LBI 1,%d' % (((op & 0xF) + 1) & 0xF)
    if 0x28 <= op <= 0x2F:
        return 1, 'LBI 2,%d' % (((op & 0xF) + 1) & 0xF)
    if 0x38 <= op <= 0x3F:
        return 1, 'LBI 3,%d' % (((op & 0xF) + 1) & 0xF)
    if 0x51 <= op <= 0x5F:
        return 1, 'AISC %d' % (op & 0xF)
    if 0x60 <= op <= 0x63:
        return 2, 'JMP %03X' % (((op & 3) << 8) | sig)
    if 0x68 <= op <= 0x6B:
        return 2, 'JSR %03X' % (((op & 3) << 8) | sig)
    if 0x70 <= op <= 0x7F:
        return 1, 'STII %d' % (op & 0xF)
    if op == 0x23:
        if sig <= 0x3F:
            return 2, 'LDD %d,%d' % ((sig >> 4) & 3, sig & 0xF)
        if 0x80 <= sig <= 0xBF:
            return 2, 'XAD %d,%d' % ((sig >> 4) & 3, sig & 0xF)
        return 2, 'db 23 %02X' % sig
    if op == 0x33:
        if 0x50 <= sig <= 0x5F:
            return 2, 'OGI %d' % (sig & 0xF)
        if 0x60 <= sig <= 0x6F:
            return 2, 'LEI %d' % (sig & 0xF)
        if 0x80 <= sig <= 0xBF:
            return 2, 'LBI %d,%d' % ((sig >> 4) & 3, sig & 0xF)
        return 2, PREF33.get(sig, 'db 33 %02X' % sig)
    return 1, SIMPLES.get(op, 'db %02X' % op)


def main():
    rom = open(sys.argv[1], 'rb').read()[:1024]
    desde = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0
    hasta = int(sys.argv[3], 16) if len(sys.argv) > 3 else 0x3FF
    pc = desde
    while pc <= hasta:
        n, t = uno(rom, pc)
        print('%03X  %-6s %s' % (pc, rom[pc:pc + n].hex(), t))
        pc += n


if __name__ == '__main__':
    main()
