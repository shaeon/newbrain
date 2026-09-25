#!/usr/bin/env python3
"""
Convierte entre programas BASIC del NewBrain "en crudo" y cintas.

Por ahi circulan dos cosas distintas con la misma extension .BAS:

  * **Cintas** (las de cdesp, y las que hace este core): bloques con
    sincronismo, longitud, tipo y suma de control. Empiezan por 00. El core
    las carga tal cual con "Cargar cinta".

  * **Programas en crudo**: el texto del programa, sin envolver, tal como
    queda en memoria. Empiezan por 0D. Esos NO son una cinta y el core no
    los puede cargar directamente.

El texto va **del reves dentro de cada bloque**: el BASIC del NewBrain
guarda el programa hacia abajo en memoria, asi que cada bloque sale
invertido byte a byte, pero los bloques van en el orden normal del
programa. Comprobado con cintas reales (snake, nimtape, TheCrossing) y con
una grabada por la propia ROM.

El programa termina en la marca 0D 04 0D. Los volcados en crudo suelen
llevar basura detras, restos de lo que hubiera antes en memoria: se corta
ahi.

Uso:
  nbbas.py envuelve programa.bas cinta.bas [NOMBRE]   crudo   -> cinta
  nbbas.py extrae   cinta.bas programa.bas            cinta   -> crudo
  nbbas.py mira     fichero.bas                       dice que es

Con --sin-voltear no invierte el texto, por si aparece un volcado que ya
venga en el orden de la cinta.
"""
import os
import sys

TAM_BLOQUE = 1024


def es_cinta(d):
    """Una cinta empieza por 00 y su primer bloque cuadra con la suma."""
    if len(d) < 7 or d[0] != 0:
        return False
    L = d[1] | d[2] << 8
    if 3 + L + 3 > len(d):
        return False
    suma = (L & 0xFF) + (L >> 8) + sum(d[3:3 + L]) + d[3 + L] + 0x3B
    return (suma & 0xFFFF) == (d[4 + L] | d[5 + L] << 8)


def bloque(datos, tipo):
    L = len(datos)
    suma = (L & 0xFF) + (L >> 8) + sum(datos) + tipo + 0x3B
    return (bytes([0, L & 0xFF, L >> 8]) + bytes(datos) + bytes([tipo])
            + bytes([suma & 0xFF, (suma >> 8) & 0xFF]) + bytes(9))


def recorta(crudo):
    i = crudo.find(b'\r\x04\r')
    return crudo[:i + 3] if i >= 0 else crudo


def envuelve(crudo, nombre, voltear=True):
    texto = recorta(crudo)
    trozos = [texto[i:i + TAM_BLOQUE] for i in range(0, len(texto), TAM_BLOQUE)]
    if voltear:
        trozos = [t[::-1] for t in trozos]
    if not trozos:
        trozos = [b'']
    salida = bloque(nombre.encode('ascii', 'replace'), 0x81)
    for i, t in enumerate(trozos, start=1):
        ultimo = (i == len(trozos))
        salida += bloque(t, (0x40 if ultimo else 0x00) | (i & 0x3F))
    return salida


def desenvuelve(cinta):
    p = 0
    nombre = None
    carga = b''
    while p + 6 <= len(cinta) and cinta[p] == 0:
        L = cinta[p + 1] | cinta[p + 2] << 8
        datos = cinta[p + 3:p + 3 + L]
        tipo = cinta[p + 3 + L]
        if tipo & 0x80:
            nombre = bytes(c & 0x7F for c in datos).strip()
        else:
            carga += datos[::-1] if True else datos
        p += 3 + L + 3
        c = 0
        while p < len(cinta) and cinta[p] == 0 and c < 9:
            p += 1
            c += 1
    return nombre, carga


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    voltear = '--sin-voltear' not in sys.argv
    if not args:
        print(__doc__)
        return 1
    orden = args[0]

    if orden == 'mira':
        d = open(args[1], 'rb').read()
        if es_cinta(d):
            nombre, carga = desenvuelve(d)
            print('%s: cinta, nombre %r, %d bytes de programa'
                  % (args[1], nombre, len(carga)))
        else:
            print('%s: programa en crudo, %d bytes%s'
                  % (args[1], len(d), ', empieza por 0D' if d[:1] == b'\r' else ''))
        return 0

    if orden == 'envuelve':
        d = open(args[1], 'rb').read()
        if es_cinta(d):
            print('ya es una cinta, no hay nada que envolver')
            return 1
        nombre = args[3] if len(args) > 3 else os.path.splitext(
            os.path.basename(args[1]))[0].upper()[:16]
        salida = envuelve(d, nombre, voltear)
        open(args[2], 'wb').write(salida)
        print('%s -> %s: %d bytes, nombre %r, %d bloques de datos'
              % (args[1], args[2], len(salida), nombre,
                 max(1, -(-len(d) // TAM_BLOQUE))))
        return 0

    if orden == 'extrae':
        d = open(args[1], 'rb').read()
        nombre, carga = desenvuelve(d)
        open(args[2], 'wb').write(carga)
        print('%s -> %s: nombre %r, %d bytes' % (args[1], args[2], nombre, len(carga)))
        return 0

    print(__doc__)
    return 1


if __name__ == '__main__':
    sys.exit(main())
