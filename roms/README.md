# ROMs

No se incluyen en el repositorio.

## Como la carga el core

El fichero de ROM va con **indice 0**, que en el firmware de MiST significa
que **se carga solo al arrancar el core**: busca en la tarjeta un fichero que
se llame como el core, o sea **`NEWBRAIN.ROM`**, con esta extension.

Si no aparece nada en pantalla al cargar el core pero desde el menu si
funciona, es que el fichero no se llama asi o no esta donde el firmware lo
busca. La entrada "Recargar ROM" del menu sigue estando para cambiarla en
caliente.

La cinta va con indice 2 y **no** se carga sola, que es lo que se quiere:
cargarla no reinicia la maquina, como cambiar el casete. Los discos van por
"Disco A:" y "Disco B:", que son imagenes montadas por el firmware.

## Contenido del fichero

Todo lo opcional va detras, asi que un fichero mas corto sigue valiendo: con
24576 bytes arranca, y cada trozo siguiente añade una funcion.

| Offset | Tamaño | Contenido | Fichero | Mapeo |
|--------|--------|-----------|---------|-------|
| 0x0000 | 8K | AB | `aben.ic6` | A000 |
| 0x2000 | 8K | CD | `cd iss 1.ic7` | C000 |
| 0x4000 | 8K | EF | `ef iss 1.ic8` | E000 |
| 0x6000 | 4K | generador de caracteres | `char eprom iss 1.ic453` | |
| 0x7000 | 8K | ROM de disco del NewBrain | `d413-2` (CRC 29CAB1E7) | 8000 |
| 0x9000 | 24K | ROMs del modulo de expansion | `e417-2`, `e416-3`, `e415-3` | paginas 123-125 |
| 0xF000 | 1K | ROM del COP420 | `cop420-guw.ic419` | |
| 0xF400 | 8K | ROM del Z80 de la controladora | `d417-1` o `d417-2` | |

De la `d417` solo se guardan en la FPGA los primeros 2K: las dos revisiones
acaban antes de `0421h` y el resto es FF.

Tamaños validos: 24576, 28672, 36864, 61440, 62464 y 70656 bytes.

Para construir el minimo:

    cat aben.ic6 "cd iss 1.ic7" "ef iss 1.ic8" \
        "char eprom iss 1.ic453" > NEWBRAIN.ROM

El generador de caracteres va **antes** que la ROM de disco a proposito: asi
un fichero de 28672 bytes, sin disquetera, sigue siendo valido.

Otras revisiones validas del sistema: issue2 (v1.9), issue3 (v1.91),
series2, v2.0. Ojo con la v2.0, que reparte el espacio distinto
(`cd20tci.rom` ocupa 16K).

## Juegos de ROMs del sistema

Los cinco de MAME, montados completos (con disco, expansion, COP y d417):

| Juego | AB | CD | EF |
|-------|----|----|----|
| issue1 | aben (308F1F72) | cd iss 1 (6B4D9429) | ef iss 1 (20DD0B49) |
| issue2 (v1.9) | aben19 (D0283EB1) | cd iss 1 | ef iss 1 |
| issue3 (v1.91) | aben191 (B7BE8D89) | cd iss 1 | ef iss 1 |
| series2 | abs2 (9A042ACB) | cd iss 1 | efs2 (B222D798) |
| rom20 (v2.0) | aben20 (3D76D0C8) | cd20tci, 16K = cd iss 1 + efs2 | |

**Ojo con el rom20**, que es el que trae MAME por defecto: su tabla de
teclado no cuadra con las teclas. El `;` da una `m`, la flecha arriba no da
nada y el `:` sale en otra tecla. Con issue1 o series2 salen en su sitio.

En el archivo `NB-EPROM-ROM` el fichero `308F1F72.bin` tiene en realidad el
CRC D0283EB1 (es la aben19); la aben de verdad esta en `308F1F72_2.bin`.

## Las ROMs de disco

Hacen falta **las dos**: la `d413` en 0x7000, que es la que ve el NewBrain en
8000, y la `d417` en 0xF400, que es la del Z80 de la controladora. Si falta
alguna, la opcion "ROM de disco" del OSD no hace nada.

- `d413`: la buena es la de CRC **29CAB1E7** (ISSUE 2). El `d413-2.rom` del
  romset de MAME (CRC 097591F1) es un volcado malo, sin codigo.
- `d417`: valen la ISSUE 1 (40FAD31C) o la ISSUE 2 (E8BDA8B9). Las dos usan
  los mismos puertos y las dos arrancan CP/M; por defecto se pone la 2, que
  es la que MAME da por buena.

Ver `doc/13-disquetera.md`.

## La ROM del COP420

Solo hace falta para la opcion "COP420: Real", que todavia se esta
depurando. Sin ella el core usa el COP emulado por protocolo, que es el
modo por defecto y el que esta probado.
