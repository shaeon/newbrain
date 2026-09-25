#!/usr/bin/env python3
"""
Mira ficheros .BAS del NewBrain, dice de que tipo son y arregla los que no
sirven para cargar por cinta, dejando una copia con _fix en el nombre.

Con la misma extension .BAS circulan dos cosas distintas:

  cinta     empieza por 00 y va en bloques con longitud, tipo y suma de
            control. Es lo que lee el core (opcion "Cargar cinta") y lo que
            graba la maquina. No hay nada que arreglar.

  crudo     el texto del programa tal cual, como queda en memoria. Empieza
            por 0D. No es una cinta y el core no lo puede cargar: de estos
            sale un NOMBRE_fix.BAS ya envuelto.

Detalle que importa: el texto va **del reves dentro de cada bloque**, pero
los bloques van en el orden normal del programa. El BASIC del NewBrain
guarda el programa hacia abajo en memoria. Invertir el fichero entero da un
programa rotado, con media linea al principio. El programa acaba en la
marca 0D 04 0D y lo que venga detras es basura de lo que hubiera antes en
memoria: se corta ahi.

Uso:
  nbfix.py fichero.bas [mas ficheros o carpetas...]
  nbfix.py *.BAS
  nbfix.py -n fichero.bas      solo mira, no escribe nada
  nbfix.py -f fichero.bas      arregla aunque no parezca un programa BASIC
"""
import os
import sys

TAM_BLOQUE = 1024
FIN_PROGRAMA = b'\r\x04\r'


# ---------------------------------------------------------------- deteccion
def trocea(d):
    """Recorre los bloques de una cinta. Devuelve (bloques, sobra, error)."""
    bloques = []
    p = 0
    while p < len(d):
        if len(d) - p < 6:
            return bloques, len(d) - p, 'cola de %d bytes suelta' % (len(d) - p)
        if d[p] != 0:
            return bloques, len(d) - p, 'se esperaba sincronismo 00 y hay %02X' % d[p]
        largo = d[p + 1] | d[p + 2] << 8
        if p + 3 + largo + 3 > len(d):
            return bloques, len(d) - p, 'bloque cortado'
        datos = d[p + 3:p + 3 + largo]
        tipo = d[p + 3 + largo]
        suma = d[p + 4 + largo] | d[p + 5 + largo] << 8
        calc = (largo & 0xFF) + (largo >> 8) + sum(datos) + tipo + 0x3B
        if (calc & 0xFFFF) != suma:
            return bloques, len(d) - p, 'suma mal: %04X en vez de %04X' % (suma, calc & 0xFFFF)
        bloques.append((tipo, datos))
        p += 3 + largo + 3
        ceros = 0
        while p < len(d) and d[p] == 0 and ceros < 9:
            p += 1
            ceros += 1
    return bloques, 0, None


def mira(d):
    """Devuelve (tipo, detalle). tipo: cinta, crudo, cinta-rota, desconocido."""
    if not d:
        return 'desconocido', 'fichero vacio'
    if d[0] == 0:
        bloques, _, error = trocea(d)
        if bloques and not error:
            nombre = b''
            datos = 0
            for tipo, cuerpo in bloques:
                if tipo & 0x80:
                    nombre = bytes(c & 0x7F for c in cuerpo).strip()
                else:
                    datos += len(cuerpo)
            return 'cinta', '%d bloques, nombre %s, %d bytes de programa' % (
                len(bloques), nombre.decode('ascii', 'replace') or '(sin nombre)', datos)
        if bloques:
            return 'cinta-rota', '%d bloques buenos y luego %s' % (len(bloques), error)
        return 'cinta-rota', error
    if d[0] == 0x0D:
        fin = d.find(FIN_PROGRAMA)
        if fin >= 0:
            return 'crudo', '%d bytes de programa y %d de basura detras' % (
                fin + 3, len(d) - fin - 3)
        return 'crudo', '%d bytes, sin la marca de fin 0D 04 0D' % len(d)
    return 'desconocido', 'empieza por %02X, ni cinta ni programa en crudo' % d[0]


# ----------------------------------------------------------------- arreglo
def bloque(datos, tipo):
    largo = len(datos)
    suma = (largo & 0xFF) + (largo >> 8) + sum(datos) + tipo + 0x3B
    return (bytes([0, largo & 0xFF, largo >> 8]) + bytes(datos) + bytes([tipo])
            + bytes([suma & 0xFF, (suma >> 8) & 0xFF]) + bytes(9))


def envuelve(crudo, nombre):
    fin = crudo.find(FIN_PROGRAMA)
    texto = crudo[:fin + 3] if fin >= 0 else crudo
    trozos = [texto[i:i + TAM_BLOQUE][::-1]
              for i in range(0, len(texto), TAM_BLOQUE)] or [b'']
    salida = bloque(nombre.encode('ascii', 'replace'), 0x81)
    for i, t in enumerate(trozos, start=1):
        ultimo = 0x40 if i == len(trozos) else 0x00
        salida += bloque(t, ultimo | (i & 0x3F))
    return salida, len(trozos)


def ruta_fix(ruta):
    raiz, ext = os.path.splitext(ruta)
    return raiz + '_fix' + (ext or '.BAS')


def procesa(ruta, escribir=True, forzar=False):
    d = open(ruta, 'rb').read()
    tipo, detalle = mira(d)
    print('%s: %s (%s)' % (os.path.basename(ruta), tipo, detalle))

    if tipo == 'cinta':
        print('   ya vale para cargar, no se toca')
        return 0
    if tipo == 'cinta-rota':
        print('   parece una cinta estropeada; no la toco para no empeorarla')
        return 1
    if tipo == 'desconocido' and not forzar:
        print('   no se que es; con -f se envuelve igualmente')
        return 1

    nombre = os.path.splitext(os.path.basename(ruta))[0].upper()[:16]
    salida, n = envuelve(d, nombre)
    destino = ruta_fix(ruta)
    if not escribir:
        print('   se generarian %d bytes en %s (%d bloques, nombre %s)'
              % (len(salida), os.path.basename(destino), n, nombre))
        return 0
    open(destino, 'wb').write(salida)
    print('   arreglado -> %s (%d bytes, %d bloques de datos, nombre %s)'
          % (os.path.basename(destino), len(salida), n, nombre))
    return 0


def expande(args):
    for a in args:
        if os.path.isdir(a):
            for f in sorted(os.listdir(a)):
                if f.lower().endswith(('.bas', '.bin')) and '_fix' not in f.lower():
                    yield os.path.join(a, f)
        else:
            yield a


def main():
    escribir = '-n' not in sys.argv
    forzar = '-f' in sys.argv
    rutas = list(expande([a for a in sys.argv[1:] if not a.startswith('-')]))
    if not rutas:
        print(__doc__)
        return 1
    fallos = 0
    for r in rutas:
        try:
            fallos += procesa(r, escribir, forzar)
        except OSError as e:
            print('%s: no se puede leer (%s)' % (r, e))
            fallos += 1
    return 1 if fallos else 0


if __name__ == '__main__':
    sys.exit(main())
