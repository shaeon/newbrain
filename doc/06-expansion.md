# Bus de expansion, paginacion, CP/M y disquetera

Revision de lo que haria falta, con las fuentes contrastadas y, sobre todo,
con lo que **no** esta documentado en ninguna de ellas.

## 1. El bus de expansion

Conector de 50 patas. Es el bus del Z80 casi en crudo (A0-A15, D0-D7, `_MREQ`,
`_IORQ`, `_RD`, `_WR`, `_M1`, `_RFRSH`, `_INT`, `_NMI`, `_WAIT`, `_HALT`,
`_BUSRQ`, `_BUSAK`, `_RST`) mas seis señales propias:

| Pata | Señal | Funcion |
|------|-------|---------|
| 28-30 | `EXRM2..0` | el bloque de 8K que la expansion impone en lugar del interno |
| 31 | `_ROMOV` | la expansion toma el control del decodificado |
| 48 | `RAMINH` | inhibe la peticion del Z80 a la RAM interna |
| 27 | `RAMENB` | habilitacion de RAM |
| 6 | `RMSL` | seleccion de RAM: a masa conmuta los 16K bajos por los altos |
| 47 | `PRTOV` | inhibe el decodificado interno de puertos de E/S |
| 23 | `FCTR` | señal interna sacada al conector en las maquinas tempranas |
| 2 | `1/8C` | reloj dividido |

Tres avisos de nomenclatura y fiabilidad:

- El **Manual Tecnico de Software** de Grundy llama `RAMINB` a la pata 48;
  los esquemas la llaman `RAMINH`, que es el nombre que usa MAME y el que
  usamos aqui. Es la misma funcion.
- `FCTR` (pata 23) es un nombre real de los esquemas, pero **nadie ha
  encontrado un documento de Grundy que lo desarrolle**. El Apendice E la da
  por no usada y avisa de que las maquinas tempranas llevan señal ahi,
  recomienda un pull-up de 10K a +5V y desaconseja excitarla. Va al circuito
  de video: ponerla a nivel bajo desplaza la imagen dos posiciones.
- La tabla de pinout publicada en newbrainemu.eu es util, pero su autor
  **reconoce que las descripciones las genero parcialmente con una IA**
  mientras sustituia las DRAM por SRAM. Los nombres de señal vienen de los
  esquemas y son fiables; las descripciones no son documentacion. En
  concreto, describir `PRTOV` como "selector del puerto 0xFF" es engañoso: lo
  que hace es inhibir el decodificado interno de E/S en general, y el
  mecanismo del puerto 255 es cosa aparte.

`ROMOV`, `EXRM` y `RAMINH` ya estan como entradas en `newbrain_mem.v` desde la
fase 1; hasta ahora estaban atadas al decodificado interno.

### Direccionamiento de dispositivos

El Z80 pone A8-A15 en el bus durante `OUT (C),A`, y el NewBrain lo aprovecha:
**A8-A15 seleccionan el dispositivo y A0-A7 el registro**. Las constantes
salen de los simbolos del propio codigo:

    EXPANSION       EQU 00000001B
    DISCCONTROLLER  EQU 00000010B
    NETWORKCONTROL  EQU 00000100B
    ALLPERIPHERALS  EQU 11111111B

Por eso MAME decodifica el registro de la controladora como
`(offset & 0x20f) == 0x20f`: el bit 9 es `DISCCONTROLLER` en la parte alta y
`0F` es el registro.

## 2. El registro de control de paginacion

Registro `0F` con el dispositivo seleccionado en la parte alta. Los bits estan
**contrastados entre dos fuentes independientes**, MAME (que lo ve desde el
lado de la controladora) y el emulador de cdesp (que lo ve desde el lado del
NewBrain), y encajan:

| Bit | MAME (`io_dec_w`) | Emulador | Lectura |
|-----|-------------------|----------|---------|
| 0 | PAGING | `PageEnabled` | habilita la paginacion |
| 2 | MA16 | `AltSet` | elige el juego de paginas alternativo |
| 3 | MPM | — | modo de paginacion de memoria |
| 5 | `_FDC RESET` | E/S de disco | reset de la controladora |
| 7 | FDC ATT | "listo para comando" | atencion a la controladora |

Que MAME llame al bit 2 `MA16` y el emulador `AltSet` es la misma cosa vista
desde los dos lados: es el bit 16 de direccion, o sea cual de los dos bloques
de 64K esta activo.

La controladora lee su lado en su propio puerto `40`: bit 5 `FDC INT`, bit 6
`PAGING`, bit 7 `FDC ATT`.

## 3. El modelo de memoria paginada

El emulador de cdesp lo modela asi, y funciona con software real:

- **8 ranuras de 8K** que cubren los 64K del Z80 (`0000`, `2000`, ... `E000`).
- Cada ranura contiene un **numero de pagina de 7 bits**, o sea 128 paginas de
  8K = **1 MB** de espacio fisico.
- El bit 7 del byte de pagina distingue ROM de RAM.
- Hay **dos juegos completos de 8 ranuras**, principal y alternativo, y el bit
  2 del registro de control conmuta entre ellos.

Mapa base de la maquina sin expansion, en numeros de pagina:

| Ranura | Direccion | Pagina | Contenido |
|--------|-----------|--------|-----------|
| 0 | `0000` | 107 | RAM |
| 1 | `2000` | 106 | RAM (aqui vive la pantalla) |
| 2 | `4000` | 105 | RAM |
| 3 | `6000` | 104 | RAM |
| 4 | `8000` | — | vacio, o expansion |
| 5 | `A000` | 122 | ROM AB |
| 6 | `C000` | 121 | ROM CD |
| 7 | `E000` | 120 | ROM EF |

### Resuelto: ver doc/07-paginacion.md

El Apendice F del Manual Tecnico de Software resuelve esta seccion entera.
Los registros de pagina se cargan por el **puerto 2** y el control por el
**puerto 255**. Lo que sigue se deja como registro de por donde se llego.

### Donde esta documentado de verdad

Por que puerto se escribe el numero de pagina de cada ranura no sale de
ninguna de las fuentes que veniamos usando: MAME no implementa el EIM (el
fichero `eim.cpp` dice literalmente `TODO: everything`), el emulador precarga
un mapa fijo y solo conmuta `PageEnabled`/`AltSet`, y *The NewBrain Dissected*
declina explicitamente tratar la paginacion.

Pero **no hace falta ingenieria inversa**: existe documentacion primaria de
Grundy. El **Manual Tecnico de Software**, **Apendice F**, describe el
mecanismo del registro de paginacion y estado del **puerto 255**, y el
**Apendice E** documenta el conector de expansion. Esta en la zona de
descargas de newbrainemu.eu, tras registro gratuito.

Conseguir ese apendice es mucho mejor camino que desensamblar la ROM
`16#8#83.POS`: es la especificacion del fabricante en vez de una deduccion, y
cierra de paso la pregunta de cuanta memoria admite el sistema.

### Cuanta memoria admite: sin resolver

Las cifras que circulan no concuerdan, asi que conviene no dar ninguna por
buena todavia:

| Fuente | Cifra | Desenlace |
|--------|-------|-----------|
| *The NewBrain Dissected*, 2.8 | "hasta medio megabyte o asi" | se quedaba corta |
| Emulador de cdesp | 7 bits de pagina x 8K = 1 MB | simplificacion suya |
| **Apendice F de Grundy** | **8 bits de pagina x 8K = 2 MB** | **la buena** |

Y 12 bits, o sea 32 MB, en modo multiproceso. Ver `doc/07-paginacion.md`.

## 4. La controladora de disco

**No es un puerto con registros de FDC: es otro ordenador.** La placa lleva su
propio Z80 a 4 MHz, 8K de ROM, RAM estatica y un NEC µPD765 a 8 MHz. Se
conecta al bus de expansion y dialoga con el NewBrain por el registro de
control de arriba.

Reparte dos ROMs distintas:

| ROM | Tamaño | Donde vive |
|-----|--------|------------|
| `d413` | 8K | en el espacio del **NewBrain**, en `8000` |
| `d417` | 8K | en el espacio del **Z80 de la controladora** |

El Z80 de la controladora tiene su propio mapa de E/S: `00`-`01` el µPD765,
`20` un registro auxiliar (bit 0 motor, bit 1 reset del 765, bit 2 TC, bit 5
PA15) y `40` el registro de estado hacia el anfitrion.

### El sistema minimo

Esto explica el comportamiento que describe *Dissected*: enchufas la
controladora y la maquina arranca **identica**, con el mismo mensaje y la
misma memoria libre, pero `LOAD "ABC"` va al disco en vez de a la cinta. El
motivo es que la ROM `A000` comprueba al arrancar si hay ROM en `8000` y, si
la encuentra, **salta a `8001` y le cede el control**, que reescribe las
variables de pagina cero.

Ese hueco de `8000`-`9FFF` es el mismo que teniamos como bus abierto desde la
fase 1. **Ya esta implementado**: `newbrain_mem.v` acepta una ROM de disco de
8K ahi, activable desde el OSD.

### El sistema completo

Para CP/M de verdad hacen falta los 64K del modulo de expansion, porque CP/M
quiere la memoria baja entera y el NewBrain tiene ROM desde `A000`. Con la
expansion, el arranque cambia: en vez del mensaje de BASIC sale un menu
("Newbrain paged system main menu") para elegir entre BASIC y CP/M 2.2. La
BIOS de CP/M queda en `F400`, o sea un CP/M de tamaño maximo.

El modulo de expansion, ademas de la RAM paginada, lleva Z80 CTC, ACIA 6850,
ADC0809, DAC0808 y 16K de ROM en cuatro trozos. Los nombres de fichero del
emulador y de MAME coinciden, lo que confirma que hablan del mismo hardware:
`19#8#83.ACI` = `e415-3`, `10#8#83.MTV` = `e416-3`.

## 5. Formatos de disquete

La controladora admite una y dos caras, 40 y 80 pistas, y densidad normal o
alta; la configuracion concreta se elige en un fichero de CP/M, no por
hardware. Los dos formatos que interesan salen de la misma geometria MFM:

| Formato | Pistas | Caras | Cuentas |
|---------|--------|-------|---------|
| 200K | 40 | 1 | 40 × 1 × 10 × 512 = 204800 |
| 800K | 80 | 2 | 80 × 2 × 10 × 512 = 819200 |

Las cuentas cuadran exactas con 10 sectores de 512 bytes por pista, pero
**eso es deduccion mia, no un dato leido**: 5 sectores de 1024 daria los
mismos totales. Hay que confirmarlo contra el DPB de CP/M antes de darlo por
bueno. Lo que si es seguro es que ambos formatos son la misma implementacion
con distinta geometria, asi que no son dos trabajos sino uno.

## 6. Como lo meteriamos

Por orden, cada paso util por si mismo:

**6.1 ROM de disco en `8000` — hecho.** Es el sistema minimo. Con la ROM
`d413` cargada, el NewBrain deberia arrancar igual pero mandando las
operaciones de fichero al disco. No sirve de nada hasta que exista el otro
extremo, pero es el gancho y no costaba nada.

**6.2 Registro de control y seleccion de dispositivo.** Decodificar el
registro `0F` con el dispositivo en A8-A15, con los bits de la tabla de la
seccion 2. Bien fundamentado, barato, y es por donde pasa todo lo demas.

**6.3 HLE de la controladora — hecho.** Ver `doc/13-disquetera.md`: la
conversacion pasa por 1K de RAM compartida en `9C00-9FFF` y un registro de
control en el puerto `255` con A9, y los sectores salen de imagenes montadas
en la SD. Falta la ROM buena de `8000`. Lo que sigue queda como registro de
por donde se llego.

**6.3 bis Desensamblar `d413`.** Aqui estaba la decision de fondo. Con el protocolo
que usa esa ROM para hablar con la controladora podemos hacer **HLE**: una
maquina de estados que atienda los comandos y lea sectores de una imagen en la
SD, igual que hicimos con el COP420. La alternativa fiel es un segundo T80 mas
la ROM `d417` mas un core de µPD765, que es mucho mas caro en logica y ademas
necesita el mismo desensamblado para depurarlo. Yo iria a HLE.

**6.4 Paginacion.** Ocho registros de ranura por juego, dos juegos, 7 bits de
pagina. Un mapa de 1 MB va entero en la SDRAM, que tiene 8. La parte de RTL es
directa; lo que falta es **por que puerto se escriben**, y eso sale de
desensamblar `16#8#83.POS`.

**6.5 CP/M.** Cae solo una vez que 6.3 y 6.4 funcionen.

### Coste en memoria

La paginacion no cabe en block RAM: 1 MB de espacio fisico va a SDRAM. Eso
obliga a lo que ya estaba anotado en `doc/05-memoria.md` como paso 3: mover
tambien la RAM del sistema a la SDRAM y construir un controlador con
arbitraje de tres clientes, con prioridad para el video. Es el trabajo pesado
de esta fase, mas que la logica de paginacion en si.
