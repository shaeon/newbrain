#!/usr/bin/env python3
"""
Desmodulador de cinta identico al del RTL (`newbrain_tape.v`), para
comprobar que un fichero de audio se lee de verdad antes de llevarlo a la
placa.

Mide semiperiodos, como el core: la polaridad da igual. Acepta WAV, o
cualquier cosa que sepa abrir ffmpeg (FLAC, MP3, OGG...), que se convierte
a 16 bits mono por una tuberia.

Uso:
  nbdemod.py audio.wav                 saca los bytes leidos
  nbdemod.py audio.mp3 fichero.bas     ademas compara con el fichero
  nbdemod.py audio.wav --umbral 306    umbral corto/largo en us
"""
import subprocess
import sys
import wave

RUIDO_US = 60
SILENCIO_US = 1500
PILOTO_MIN = 64


def muestras(ruta):
    """Devuelve (lista de niveles 0/1 comparados a cero, frecuencia)."""
    if ruta.lower().endswith('.wav'):
        with wave.open(ruta, 'rb') as w:
            rate = w.getframerate()
            ch = w.getnchannels()
            anchura = w.getsampwidth()
            crudo = w.readframes(w.getnframes())
        if anchura != 2:
            raise SystemExit('solo 16 bits; usa ffmpeg para convertir')
    else:
        rate = 44100
        crudo = subprocess.run(
            ['ffmpeg', '-v', 'quiet', '-i', ruta, '-f', 's16le',
             '-acodec', 'pcm_s16le', '-ac', '1', '-ar', str(rate), '-'],
            stdout=subprocess.PIPE, check=True).stdout
        ch = 1
    vals = []
    paso = 2 * ch
    for i in range(0, len(crudo) - paso + 1, paso):
        v = int.from_bytes(crudo[i:i + 2], 'little', signed=True)
        vals.append(1 if v > 0 else 0)
    return vals, rate


def desmodula(vals, rate, umbral_us=306):
    us_por_muestra = 1e6 / rate
    salida = bytearray()
    errores = 0

    semi = 0.0
    est = 'busca'
    sim_ant = 0
    racha = 0
    piloto = 0
    cortos = 0
    largo1 = False
    nbit = 0
    sr = 0
    ant = vals[0] if vals else 0

    for v in vals:
        semi += us_por_muestra
        if semi >= SILENCIO_US:
            if est == 'bits' and nbit != 0:
                errores += 1
            est = 'busca'
            piloto = 0
            racha = 0
        if v == ant:
            continue
        ant = v
        if semi < RUIDO_US:
            continue
        corto = 1 if semi < umbral_us else 0
        semi = 0.0
        hecho = False
        bval = 0

        if est == 'busca':
            if racha == 0 or corto != sim_ant:
                if racha == 2:
                    piloto += 1
                elif racha >= 3:
                    piloto = 0
                sim_ant = corto
                racha = 1
            else:
                racha += 1
                if corto and racha == 4:
                    if piloto >= PILOTO_MIN:
                        est = 'bits'
                        nbit = 0
                        cortos = 0
                        largo1 = False
                    piloto = 0
                elif not corto and racha >= 3:
                    piloto = 0
        else:
            if corto:
                if largo1:
                    est = 'busca'
                    errores += 1
                elif cortos == 3:
                    hecho, bval = True, 1
                else:
                    cortos += 1
            else:
                if cortos != 0:
                    est = 'busca'
                    errores += 1
                elif largo1:
                    hecho, bval = True, 0
                else:
                    largo1 = True
            racha = 0

        if hecho:
            cortos = 0
            largo1 = False
            if nbit < 8:
                sr = ((sr << 1) | bval) & 0xFF
                nbit += 1
            elif nbit == 8:
                if bval:
                    est = 'busca'
                    errores += 1
                nbit = 9
            else:
                if not bval:
                    est = 'busca'
                    errores += 1
                else:
                    salida.append(sr)
                nbit = 0
    return bytes(salida), errores


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    umbral = 306
    for a in sys.argv[1:]:
        if a.startswith('--umbral'):
            umbral = int(a.split('=')[1]) if '=' in a else umbral
    if not args:
        print(__doc__)
        return 1
    vals, rate = muestras(args[0])
    datos, err = desmodula(vals, rate, umbral)
    print('%s: %d muestras a %d Hz, %d bytes leidos, %d desencuadres'
          % (args[0], len(vals), rate, len(datos), err))
    if len(args) > 1:
        esperado = open(args[1], 'rb').read()
        if datos[:len(esperado)] == esperado:
            print('  coincide con %s' % args[1])
            return 0
        print('  NO coincide')
        print('  esperado %s' % esperado.hex())
        print('  leido    %s' % datos.hex())
        return 2
    print('  ' + datos.hex())
    return 0


if __name__ == '__main__':
    sys.exit(main())
