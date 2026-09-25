# NewBrain A/AD — referencia de hardware

Todo lo de aqui esta contrastado contra al menos dos fuentes. La columna
*fuente* indica de donde sale cada dato; ver `04-fuentes.md`.

## CPU y relojes

| Dato | Valor | Fuente |
|------|-------|--------|
| CPU | Z80A | placa, MAME |
| Cristal maestro | 16 MHz | MAME |
| Reloj de CPU | 16 MHz / 4 = 4 MHz | MAME |
| COP420 | 16 MHz / 4, divisor CKI 16 | MAME |
| Modo de interrupcion | una sola linea INT | MAME |

## Mapa de memoria

El decodificado usa solo A15..A13:

| Rango | Contenido |
|-------|-----------|
| `0000-7FFF` | RAM 32K |
| `8000-9FFF` | sin mapear |
| `A000-BFFF` | ROM banco 0 (AB) |
| `C000-DFFF` | ROM banco 1 (CD) |
| `E000-FFFF` | ROM banco 2 (EF) |

**Arranque.** Mientras `PWRUP` esta bajo, el bloque seleccionado se fuerza a
7, es decir, el banco 2 se ve en todo el espacio de direcciones y el Z80
arranca en `0000` ejecutando la ROM alta. `PWRUP` se libera con una red RC de
5,6 s (R129/C127) y es legible en `UST_A` bit 1. Antes, un segundo RC de
2,2 s (R128/C125) mantiene a ambas CPUs en HALT.

Con el modulo de expansion, `ROMOV`, `EXRM` y `RAMINH` permiten sustituir el
decodificado interno; el puerto `80` es el registro de paginacion.

## Mapa de E/S

El decodificado usa **solo A4..A2**, asi que cada puerto se repite cada 32
direcciones. Los nombres son los de los listados simbolicos de la ROM.

| Puerto | Nombre | Acceso | Funcion |
|--------|--------|--------|---------|
| `04` | INTCON | rd/wr | borra la interrupcion de reloj (CLCLK) |
| `06` | — | rd/wr | microbus del COP420 |
| `07` | ENREG | wr | registro de habilitacion (ENRG1) |
| `08` | TVLATCH | wr | suma 64 al contador de direccion de video |
| `09` | TVLL | wr | carga la base de video e inicia la trama |
| `0C` | TVTL | wr | registro de modo de video |
| `14` | UST_A | rd | estado A |
| `16` | UST_B | rd | estado B |
| `80` | — | wr | registro de paginacion (solo con expansion) |

### ENREG (`07`)

| Bit | Señal | Nota |
|-----|-------|------|
| 0 | `_CLK` | 0 = interrupcion de reloj habilitada |
| 2 | `TVP` | 1 = video habilitado |
| 4 | `_RTSD` | RTS del puerto V24 |
| 5 | `DO` | TXD del puerto V24 |
| 7 | `PO` | TXD de impresora |

### UST_A (`14`)

**MAME describe este puerto mal.** Los bits de abajo se dedujeron de los usos
reales en los listados de ROM y estan **confirmados por el Apendice F** del
Manual Tecnico de Software, que lo llama registro de estado 1.

| Bit | Señal | Sitio donde la ROM lo usa |
|-----|-------|---------------------------|
| 0 | `EXTEST` | fijo a uno, indica exceso de 24 o 48. Obsoleto |
| 1 | `POWTEST` | **uno indica arranque en frio**, 0 = asentado |
| 2 | — | uno indica interrupcion de analogica o indicador de llamada |
| 3 | — | cero indica interrupcion del puerto Centronics |
| 4 | — | cero indica interrupcion del bus de datos paralelo |
| 5 | `_CLKINT` | cero indica interrupcion de reloj de trama |
| 6 | — | cero indica interrupcion de la ACIA |
| 7 | `_COPINT` | cero indica interrupcion del COP420M |

Los bits 2, 3, 4 y 6 son fuentes de interrupcion del modulo de expansion; en
una maquina pelada se leen a uno, que es lo que hace el core.

La polaridad de `POWTEST` queda confirmada por el fabricante: **uno mientras
la maquina arranca en frio**, tal y como dedujimos del bucle `PWAIT`.

El puerto 21 es un segundo registro de estado, solo con expansion, con la
configuracion de arranque: D2 video normal o inverso, D3 alimentacion de red,
D4 video de 40 u 80 columnas, D6 si se quiere pantalla. Sin expansion se lee
igual que el 20.

**POWTEST va al reves que en MAME.** MAME pone el bit a 1 cuando la maquina
ya ha arrancado; la ROM espera justo lo contrario:

    E009 PWAIT: IN A,(STREG)
    E00B        BIT 1,A
    E00D        JR NZ,PWAIT     ; repite MIENTRAS el bit valga 1

O sea, el bit vale 1 mientras el mapa esta forzado a ROM2 y pasa a 0 cuando
la RAM ya es visible. Tiene sentido: justo despues, en `E00F`, la ROM hace un
test destructivo de toda la RAM de `0000` a `8000`, y no podria hacerlo si la
RAM no estuviera mapeada.

**La ROM no mide el intervalo.** `POWTEST` se consulta en un unico sitio de
las tres ROMs, ese bucle, y es un sondeo puro. Acortar las constantes RC es
por tanto seguro.

Tambien merece la pena fijarse en que la primera instruccion de la ROM es
`JP POWERUP+3`: mueve la ejecucion de `0000` a la zona `E000`, que es valida
en los dos mapeos, para que el cambio de mapa a mitad del bucle no la deje
ejecutando en RAM vacia.

### Bancos de estado conmutables: resuelto

En `E05F` la ROM lee `UST_A` e interpreta el bit 0 como `EXTEST`. Despues
escribe `52H` en `ENREG` ("TO GIVE TS & RS = 1") y en `E06E` vuelve a leer el
mismo puerto, pero ahora los bits bajos son otra cosa. **`ENREG` elige que
señal aparece en los dos bits bajos de `UST_A`**, y la seleccion la hacen
dos parejas de bits, no uno suelto. El reparto sale de `uNBIO.pas` del
emulador de cdesp:

| `ENREG[7:6]` | bit 0 de `UST_A` |
|--------------|------------------|
| 00 | `EXTEST` |
| 01 | `40/80~` |
| 10 | entrada de cinta |
| 11 | indicador de llamada |

| `ENREG[5:4]` | bit 1 de `UST_A` |
|--------------|------------------|
| 00 | `POWTEST` (1 mientras arranca) |
| 01 | `TVC~` (0 = la consola es la TV) |
| 10 | modelo de procesador |
| 11 | indicador de llamada |

**La seleccion se consume al leer**: cada lectura de `UST_A` deja los dos
selectores a cero, o sea otra vez `EXTEST` y `POWTEST`. Es lo que hace el
emulador de cdesp y no es un capricho suyo, es lo unico que deja arrancar a
la maquina. La ROM escribe `A2` en `ENREG` justo antes del bucle `PWAIT` de
`E009`, y `A2` selecciona "modelo de procesador" en el bit 1, que vale
siempre uno: con la seleccion pegada, `PWAIT` no sale nunca y la maquina se
queda colgada antes de encender el video. Comprobado en el modelo de
`tools/nbsim.py`, donde la version pegajosa se queda con el PC en `E009`
para siempre, y cubierto en `test/tb_newbrain_io.v`.

Implementado asi en `newbrain_io.v`. Con `ENREG` a cero, que es el valor de
reset, se lee lo de siempre.

### UST_B (`16`), valor base `5C`

| Bit | Señal |
|-----|-------|
| 0 | `RDDK` — RXD del V24 |
| 1 | `_CTSD` |
| 5 | `TPIN` — entrada de cinta |
| 7 | `_CTSP` — CTS de impresora |

### Interrupciones

    INT = (!_CLK && !_CLKINT) || !_COPINT

Es decir, interrumpe si el reloj esta habilitado y hay tick pendiente, o si
el COP tiene algo que decir. `INTCON` borra la de reloj; la del COP se borra
atendiendola.

## Video

No hay chip de video: es logica TTL discreta que roba ciclos de DRAM
aprovechando el slot de refresco. En el esquema del motherboard se ven
`TVRQP`/`CPRQ`/`CPROG` (arbitraje), `RFRSH`/`RFRSHB`, `RAS16`, `RA532`,
`CAS`, `TVCLK`, `ROW`, y `80L`/`GR`/`FRM` como entradas de modo.

### Protocolo desde la CPU

1. `OUT (09),A` — carga el contador de direccion: `base = A << 7`. Esta
   escritura es la que **dispara la trama**; la ROM la hace en la
   interrupcion vertical.
2. `OUT (08),A` — opcional, pone el bit 6 (offset extra de 64 bytes).
3. `OUT (0C),A` — registro de modo.

La base tiene por tanto granularidad de 64 bytes. En los listados de ROM el
orden es siempre TVLL y despues TVLATCH.

### Registro de modo (`0C`)

| Bit | Funcion |
|-----|---------|
| 0 | video inverso |
| 1 | juego completo: 0 = 128 caracteres + 128 en campo inverso, 1 = 256 |
| 2 | uno: 256 o 512 puntos horizontales. cero: 320 o 640 |
| 3 | uno: matriz de 8x8, hasta 31 lineas. cero: 8x10, hasta 25 lineas |
| 6 | 0 = 40 columnas (EL = 64 bytes), 1 = 80 columnas (EL = 128 bytes) |

`EL` es la separacion en memoria entre lineas consecutivas.

### Estructura de la pantalla

El hardware lee bytes secuencialmente desde la base. **Un byte 0 termina la
linea** y cuatro ceros seguidos marcan el paso de la zona de texto a la de
graficos. De ahi sale la pantalla grafica de tamaño variable con el resto en
texto.

El sistema operativo mantiene ademas una estructura en RAM apuntada por
`5C`/`5D` con los parametros de la ventana (offset, profundidad, lineas del
marco, byte de modo). Eso es **convencion de software, no hardware**: la
implementacion de cdesp la lee directamente de RAM, pero un core fiel debe
limitarse a los puertos.

### Temporizacion propuesta

Deducida del cristal de 16 MHz, pendiente de confirmar contra el esquema:

    reloj de punto 16 MHz, 1024 puntos/linea, 312 lineas
    -> 15,625 kHz horizontal, 50,08 Hz vertical
    -> 640 puntos activos = 80 caracteres de 8
