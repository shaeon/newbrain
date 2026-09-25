#!/usr/bin/env python3
"""
Comprueba que todos los puertos del top tienen pin asignado en un .qsf. Los
pines que sobran solo se avisan.

Resuelve los `ifdef/`ifndef/`else/`elsif/`endif de la lista de puertos con
las macros VERILOG_MACRO del propio .qsf, que son las que usara Quartus.

Uso:  nbpines.py rtl/newbrain_top.sv proyecto.qsf
"""
import re
import sys


def macros_de(qsf):
    m = set()
    for linea in open(qsf):
        linea = linea.strip()
        if linea.startswith('#'):
            continue
        r = re.search(r'VERILOG_MACRO\s+"([A-Za-z_0-9]+)', linea)
        if r:
            m.add(r.group(1))
    return m


def puertos(top, macros):
    texto = open(top).read()
    ini = texto.index('module newbrain_top(')
    fin = texto.index(');', ini)
    macros = set(macros)
    # pila de (rama activa, ya se tomo alguna rama en este nivel)
    pila = [(True, True)]
    salida = {}
    # Se recorre desde el principio del fichero: antes del module hay
    # `define que dependen de otras macros (UN_SOLO_LED, RELOJ_27...)
    pos = 0
    for linea in texto[:fin].split('\n'):
        en_puertos = pos >= ini
        pos += len(linea) + 1
        l = linea.strip()
        rd = re.match(r'`define\s+(\w+)', l)
        if rd:
            if all(a for a, _ in pila):
                macros.add(rd.group(1))
            continue
        r = re.match(r'`(ifdef|ifndef|elsif)\s+(\w+)', l)
        if r:
            d, nombre = r.groups()
            si = nombre in macros
            if d == 'ifdef':
                pila.append((si, si))
            elif d == 'ifndef':
                pila.append((not si, not si))
            else:  # elsif: solo si ninguna rama anterior se tomo
                _, tomada = pila[-1]
                act = (not tomada) and si
                pila[-1] = (act, tomada or act)
            continue
        if l.startswith('`else'):
            _, tomada = pila[-1]
            pila[-1] = (not tomada, True)
            continue
        if l.startswith('`endif'):
            pila.pop()
            continue
        activos = [a for a, _ in pila]
        if not all(activos):
            continue
        if not en_puertos:
            continue
        l = l.split('//')[0]
        r = re.match(r'(input|output|inout)\s+(\[[^\]]+\])?\s*(\w+)', l)
        if r:
            ancho = r.group(2)
            nombre = r.group(3)
            if ancho:
                a = ancho.strip('[]').split(':')[0]
                a = {'VGA_BITS-1': None}.get(a, a)
                salida[nombre] = ancho
            else:
                salida[nombre] = None
    return salida


def pines(qsf):
    asignados = set()
    for linea in open(qsf):
        if linea.strip().startswith('#'):
            continue
        r = re.search(r'set_location_assignment\s+PIN_\w+\s+-to\s+"?(\w+)', linea)
        if r:
            asignados.add(r.group(1))
    return asignados


def main():
    top, qsf = sys.argv[1], sys.argv[2]
    macros = macros_de(qsf)
    ps = puertos(top, macros)
    asig = pines(qsf)
    faltan = sorted(p for p in ps if p not in asig)
    sobran = sorted(p for p in asig if p not in ps)
    nombre = qsf.split('/')[-1]
    # Un pin de mas es inofensivo (Quartus avisa y lo ignora: suelen ser
    # restos de la plantilla de la placa). Un puerto sin pin no: Quartus lo
    # coloca donde quiere y en una placa real eso puede ser un cortocircuito.
    if sobran:
        print('%s: aviso, pines sin puerto (restos de la plantilla): %s'
              % (nombre, ', '.join(sobran)))
    if faltan:
        print('%s: puertos sin pin: %s' % (nombre, ', '.join(faltan)))
        print('pines %s: FALLO' % nombre)
        return 1
    print('pines %s: OK (%d puertos, macros %s)' % (nombre, len(ps), ' '.join(sorted(macros))))
    return 0


if __name__ == '__main__':
    sys.exit(main())
