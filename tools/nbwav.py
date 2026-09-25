#!/usr/bin/env python3
"""
Genera el audio de cinta del NewBrain a partir de un fichero .bas/.bin de
cdesp, con EXACTAMENTE las mismas muestras que beepgenerator.py de
gylles38/newbrain-bin-wav, que carga en maquinas reales. Sin numpy ni tk.

Uso:
  nbwav.py fichero.bas salida.wav        WAV mono de 16 bits a 44100 Hz
  nbwav.py fichero.bas salida.txt --bits una linea 0/1 por muestra, para
                                         $readmemb en los bancos de prueba

Se reproduce tambien su peculiaridad al contar los ceros de cola: si la
suma de un bloque acaba en 00, el bloque siguiente arranca con un cero de
mas. Es lo que genera la herramienta original; ver doc/11-cinta.md.
"""
import sys
import struct
import wave

RATE = 44100
UP_LONG = [0.68, 0.7, 0.69, 0.7, 0.68, 0.7, 0.69, 0.7, 0.69, 0.7, 0.68, 0.7, 0.69, 0.7, 0.68, 0.7, 0.69, 0.5]
UP_SHORT = [0.68, 0.7, 0.69, 0.7, 0.68, 0.7, 0.69, 0.7, 0.68]
DOWN_LONG = [-0.68, -0.7, -0.69, -0.7, -0.68, -0.7, -0.69, -0.7, -0.68, -0.7, -0.69, -0.7, -0.68, -0.7, -0.69, -0.7, -0.68, 0.3]
DOWN_SHORT = [-0.68, -0.7, -0.69, -0.7, -0.68, -0.7, -0.69, -0.7, -0.68]

PILOT = UP_LONG + DOWN_SHORT + UP_SHORT + DOWN_LONG
ONE = UP_SHORT + DOWN_SHORT + UP_SHORT + DOWN_SHORT
ZERO = UP_LONG + DOWN_LONG
BLOCK_END = ZERO + ONE + 9 * ZERO


def silencio(ms):
    n = int(ms * RATE / 1000.0)
    return [0.7] * n + [0.1] * n


def genera(data, binario=False, pilotos=1000):
    audio = []

    def bits(b, fin):
        out = []
        for c in '{:08b}'.format(b):
            out += ONE if c == '1' else ZERO
        if fin:
            out += ZERO + ONE
        return out

    audio += PILOT * pilotos + ONE
    zeros = 0
    leidos = 0
    bloque = 1
    no_title = False
    title_found = False
    lim = 11 if binario else 9
    for b in data:
        leidos += 1
        zeros = zeros + 1 if b == 0 else 0
        audio += bits(b, zeros < lim)
        if not no_title:
            no_title = (not title_found) and leidos == 2 and b == 0
        if zeros == 9:
            if no_title and not title_found:
                audio += ZERO + ONE + 10 * ZERO
            else:
                audio += BLOCK_END
            title_found = True
            zeros = 0
            if len(data) > leidos + 1:
                audio += silencio(700 if bloque == 1 else (5000 if binario else 3500))
                bloque += 1
                audio += PILOT * pilotos + ONE
    audio += silencio(200)
    return audio


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    data = open(sys.argv[1], 'rb').read()
    binario = sys.argv[1].lower().endswith('.bin')
    pil = 1000
    for a in sys.argv[3:]:
        if a.startswith('--pilotos='):
            pil = int(a[10:])
    audio = genera(data, binario, pil)
    if '--bits' in sys.argv:
        with open(sys.argv[2], 'w') as f:
            f.write('\n'.join('1' if s > 0 else '0' for s in audio) + '\n')
    else:
        w = wave.open(sys.argv[2], 'wb')
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(s * 32767)) for s in audio))
        w.close()
    print('%d muestras, %.1f s' % (len(audio), len(audio) / RATE))
    return 0


if __name__ == '__main__':
    sys.exit(main())
