# Herramientas de disco para el core FPGA del Grundy NewBrain

Conjunto de utilidades en Python para preparar imágenes de disquete que monta
el core NewBrain (Calypso / SiDi / Poseidon) a través de `u765.sv`, el
controlador NEC uPD765 de los cores MiST.

El core usa **EDSK** (`EXTENDED CPC DSK File`). Es un contenedor a nivel de
sector, no de flujo MFM, que conserva el orden físico de los sectores, sus IDs
reales, sus tamaños y los indicadores de error. Es el formato que `u765.sv`
sabe leer, y evita tener que decodificar MFM en HDL.

## En este proyecto

Los scripts estan en `tools/disco/` (tienen que ir juntos, se importan entre
si) y el banco de Verilator en `test/verilator/`. Ademas, `tools/nbdsk2raw.py`
saca un raw de un `.dsk` para usarlo con `dir2dsk.py -s`, y `make disco` en
`test/` hace la prueba de punta a punta contra la controladora en la
cosimulacion.

## Contenido

| Fichero | Para qué sirve |
|---|---|
| `td0conv.py` | Convierte imágenes Teledisk `.TD0` a EDSK (`.dsk`) o a raw (`.img`) |
| `dir2dsk.py` | Crea disquetes CP/M del NewBrain a partir de directorios del PC |
| `raw2dsk.py` | Convierte volcados raw (emulador Delphi, dumps varios) a EDSK |
| `tb_u765_edsk.cpp` | Banco de pruebas Verilator: monta un EDSK en `u765.sv` y verifica pista a pista |

`dir2dsk.py` y `raw2dsk.py` importan el escritor EDSK de `td0conv.py`, así que
los tres ficheros deben estar en la misma carpeta. Solo necesitan Python 3.8 o
posterior, sin dependencias externas.

## Uso rápido

```bash
# Teledisk -> EDSK
python3 td0conv.py DSDD800K.TD0                 # -> DSDD800K.dsk
python3 td0conv.py SSDD200K.TD0 --cyls 40 -v    # recorta pistas leídas de más
python3 td0conv.py DSDD800K.TD0 -f raw          # -> DSDD800K.img

# Directorio del PC -> disquete CP/M
python3 dir2dsk.py MIDISCO                      # -> MIDISCO.dsk
python3 dir2dsk.py "*"                          # un disquete por directorio
python3 dir2dsk.py TOOLS -F 800K                # fuerza formato
python3 dir2dsk.py TOOLS -s SSDD200K.img        # copia pistas de sistema

# Raw -> EDSK
python3 raw2dsk.py cpmmaster.dsk -v             # -> cpmmaster.edsk.dsk
python3 raw2dsk.py *.dsk -d out/
```

## Formato físico del disquete NewBrain

Común a todos los formatos conocidos:

- MFM, 250 kbps, 300 rpm
- 10 sectores por pista, IDs 1 a 10, 512 bytes por sector
- Entrelazado físico `1, 6, 2, 7, 3, 8, 4, 9, 5, 10` (skew 5)
- 2 pistas reservadas (sistema)
- GAP3 de formato 0x33 (calculado para que 10 sectores llenen una pista real
  de unos 6250 bytes; `u765.sv` solo lo usa para la temporización rotacional)

**Orden de pistas en las imágenes raw: `C0H0, C0H1, C1H0, C1H1, ...`**, y
dentro de cada pista los sectores por ID. Está verificado, no supuesto: los
ficheros PIP.COM, ED.COM, STAT.COM, SYSGEN.COM y CONFIGUR.COM extraídos del
disco de 200K (una cara, sin ambigüedad) coinciden byte a byte con los mismos
ficheros de los discos de 400K y 800K bajo este orden, y quedan destrozados
bajo el orden por caras.

La dirección de un sector en una imagen raw es:

```
LBA = (cilindro * caras + cara) * 10 + (sector - 1)
```

## Bloque de especificación de disco (64 bytes, pista 0 sector 1)

El NewBrain guarda los parámetros del disco en el propio disco. Es lo que lee
`CONFIGUR`/`XDPB`, y por eso un disco de datos también debe llevarlo.

| Offset | Tamaño | Contenido |
|---|---|---|
| 0x00 | 1 | Identificador de formato (1 = discos Grundy, 2 = variante del emulador) |
| 0x01 | 2 | 0 |
| 0x03 | 2 | Tamaño del vector de checksum de directorio, `(DRM+1)/4` |
| 0x05 | 2 | Tamaño del vector de asignación, `DSM/8 + 1` |
| 0x07 | 15 | DPB estándar de CP/M: SPT, BSH, BLM, EXM, DSM, DRM, AL0, AL1, CKS, OFF |
| 0x16 | 2 | Cilindros |
| 0x18 | 1 | 0 = una cara, 2 = dos caras |
| 0x19 | 1 | 3 |
| 0x1A | 1 | Código de tamaño de sector (2 = 512) |
| 0x1B | 1 | Sectores por pista |
| 0x1C | 4 | 0 |
| 0x20 | 32 | Parámetros de GAP y formato para el FDC (idénticos en todos los formatos) |

El resto del sector está a cero. `dir2dsk.py` genera este bloque y sale
idéntico byte a byte a los tres discos originales.

### Formatos conocidos

Tipo 1, discos Grundy originales (bloques de 2 KB):

| Formato | Cil × caras | SPT | BSH/BLM | EXM | DSM | DRM | AL0 | CKS | OFF | Libre |
|---|---|---|---|---|---|---|---|---|---|---|
| 200K | 40 × 1 | 40 | 4 / 15 | 1 | 94 | 63 | 0x80 | 16 | 2 | 190 KB |
| 400K | 40 × 2 | 40 | 4 / 15 | 1 | 194 | 63 | 0x80 | 16 | 2 | 390 KB |
| 800K | 80 × 2 | 40 | 4 / 15 | 0 | 394 | 127 | 0xC0 | 32 | 2 | 790 KB |

SPT está en registros de 128 bytes, no en sectores físicos. En el formato de
800K, DSM pasa de 255, así que los punteros del directorio son de 16 bits y el
directorio ocupa dos bloques.

Tipo 2, el que escribe el emulador NewBrain de Delphi (bloques de 4 KB):

| Formato | Cil × caras | BSH/BLM | EXM | DSM | DRM | AL0 | CKS | OFF |
|---|---|---|---|---|---|---|---|---|
| 800K | 80 × 2 | 5 / 31 | 3 | 196 | 127 | 0x80 | 32 | 2 |

La geometría física es la misma; solo cambia la asignación del sistema de
ficheros. Al core le es indiferente, porque eso lo interpreta el BIOS de CP/M.

## `td0conv.py`

Descompresor LZHUF (Okumura/Yoshizaki) propio para las imágenes Teledisk
"advanced" (firma `td` en minúsculas), más el parser de pistas y sectores, con
verificación de CRC de cabecera, pista y sector. Soporta las tres
codificaciones de sector: raw, patrón de 2 bytes repetido y bloques RLE.

Opciones útiles:

- `--cyls N` fija el número de cilindros. Sin ella, recorta automáticamente las
  pistas leídas de más al final del disco, esas cuyos IDs de sector no
  coinciden con el cilindro físico (típico de leer un disco de 40 pistas en una
  unidad de 80).
- `--gap3`, `--fill`, `--side-order`, `-v` para el mapa de pistas.

Las seis imágenes del juego de arranque original (`SSDD200K`, `SSDD2002`,
`DSDD400K`, `DSDD4002`, `DSDD800K`, `DSDD8002`) se convierten sin un solo error
de CRC. Las de 200K y 400K traen tres cilindros de más: el 40 formateado pero
vacío, y el 41 y 42 con IDs del cilindro 79, restos de un formateo anterior a
80 pistas. Con `--cyls 40` salen los tamaños nominales exactos.

## `dir2dsk.py`

Construye el sistema de ficheros CP/M completo: entradas de directorio,
asignación de bloques, extents múltiples para ficheros grandes, punteros de 8 o
16 bits según el formato, y el bloque de especificación.

- Elige el formato más pequeño que quepa (200K, 400K, 800K), mirando a la vez
  el espacio de datos y las entradas de directorio disponibles. Un fichero de
  más de 32 KB (16 KB en el formato de 800K) consume varias entradas.
- Nombres convertidos a 8.3 en mayúsculas, con desambiguación automática.
- El último registro de 128 bytes se rellena con 0x1A en ficheros de texto y
  con 0x00 en binarios (`--pad` lo cambia).
- `-s IMAGEN` copia las 2 pistas de sistema de una imagen raw existente para
  hacer discos arrancables. El bloque de especificación se reescribe siempre
  después, con los parámetros del formato de destino.
- `-r` aplana subdirectorios, ya que CP/M no los tiene.
- `--raw` escribe también el `.img` equivalente, útil para depurar.

## `raw2dsk.py`

Reempaqueta volcados raw en EDSK. Lee la geometría del bloque de
especificación y, si no lo encuentra, la deduce del tamaño del fichero.
Detecta y salta ficheros que ya son EDSK. Con `-v` lista el catálogo CP/M, que
es la forma rápida de comprobar que la imagen se ha interpretado bien antes de
grabarla. `--side-order`, `--cyls` y `--heads` cubren imágenes con otra
disposición.

## Verificación con `u765.sv`

`tb_u765_edsk.cpp` es un banco de pruebas Verilator que monta un EDSK en
`u765.sv` por la misma interfaz `sd_lba` / `sd_buff` que usa el firmware ARM de
MiST, y para cada cilindro y cara hace SEEK, READ ID y una lectura multisector
de R=1 a 10, comparando con la imagen raw equivalente.

```bash
# u765.sv y u765_test.sv salen de gyurco/Amstrad_MiST, carpeta u765/
verilator -Wno-fatal -Wno-lint -Wno-style --top-module u765_test --cc --exe \
          --build -O2 u765_test.sv u765.sv tb_u765_edsk.cpp -o tb
./obj_dir/tb DISCO.dsk DISCO.img <caras> <cilindros>
```

Resultados actuales, todos sin discrepancias: los seis discos originales
convertidos desde TD0, los discos generados con `dir2dsk.py` en los tres
formatos, y las imágenes del emulador convertidas con `raw2dsk.py`.

READ ID devuelve sectores como R=8 o R=4 al principio de la pista en lugar de
R=1 siempre. Eso indica que la rotación simulada respeta el entrelazado real,
que es justo lo que aporta EDSK frente a raw.

### Notas sobre `u765.sv` para la integración en el core

- **Solo dos unidades** (`ready[1:0]`, `motor[1:0]`). El controlador de disco
  del NewBrain admite hasta cuatro, así que habrá que ensanchar esas señales
  más adelante.
- **Parámetro `CYCLES`**: ciclos por milisegundo del reloj que se le dé al 765,
  que en el NewBrain es el de la placa controladora, no el de la CPU
  principal. La entrada `fast` va bien durante la puesta en marcha.
- **Máximo 29 sectores por pista** en EDSK, por el tamaño del bloque
  Track-Info. Sobra para 10.
- **Bug de Verilator 5.020**: revienta con el `reg` inicializado en su
  declaración dentro de la función `SECTOR_SIZE`. Para simular hay que separar
  declaración y asignación. Quartus lo compila sin problema, así que el fuente
  del core no necesita el parche.

## Contexto del controlador de disco

El interfaz de disco del NewBrain es una placa aparte con su propio Z80, dos
EPROM, 2 KB de RAM (dos 2114) y un NEC D765. En el core hay que emular ese
subsistema completo: el Z80 ejecutando las EPROM originales y hablando con el
765. Como el 765 trabaja a nivel de sector, el contenedor EDSK es suficiente y
no hace falta nada a nivel de flujo MFM (HFE, flux, etc.).
