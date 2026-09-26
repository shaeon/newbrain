# NewBrain para Calypso

Core FPGA del Grundy NewBrain A/AD para la placa Calypso (CYC1000 con
Cyclone 10 LP y RP2040 con firmware compatible MiST).

## Estado

**Fase 6 — expansion y disco.** El COP420 de verdad (su ROM en el core
t400) lleva el teclado, la pantalla y el reloj; la cinta la lleva un modulo
aparte que carga `.bas` y audio; la controladora de disco es la de verdad
(segundo Z80 con la ROM d417 y un uPD765), y CP/M arranca sin paginar (32K)
y con el modulo de expansion (96K o mas), todo con las ROMs originales.

**Toda la memoria vive en la SDRAM**, ROM y RAM. El porque, el arbitraje
entre video, CPU, cinta, carga y controladora, y el buffer de linea estan en
`doc/08-sdram.md`; el reparto de bloques M9K, en `doc/05-memoria.md`.

| Fase | Contenido | Estado |
|------|-----------|--------|
| 1 | CPU, memoria, puertos basicos | hecho |
| 2 | COP420 y teclado | el COP real lleva teclado, pantalla y reloj; la cinta, un modulo aparte, ver `doc/12-cop-real.md` |
| 3 | Video: texto 40 y 80 columnas, graficos | hecho, graficos con sus tres errores corregidos, ver `doc/04-video.md` |
| 4 | Cinta y display fluorescente | cinta hecha (fichero y audio), ver `doc/11-cinta.md`; display en una LCD I2C, ver `doc/14-extras.md` |
| 5 | Core COP400 real | funciona: arranca y teclea; su cinta propia, sin terminar, ver `doc/12-cop-real.md` |
| 6 | Bus de expansion, paginacion, FDC, CP/M | CP/M sin paginar y con expansion (en cosimulacion), ver `doc/07-paginacion.md` y `doc/13-disquetera.md` |
| 7 | Extras: puertos serie, remote, LCD | hechos, desactivados en el .qsf, ver `doc/14-extras.md` |

Sin probar en hardware: el sistema paginado con la disquetera, la SiDi y la
Poseidon.

### OSD menu

El menu esta en ingles. Que es cada opcion:

| Opcion | Que hace |
|---|---|
| Reload ROM | Carga otra ROM completa (`.ROM`) |
| Load tape | Monta un `.bas`/`.bin` como cinta (fuente "File") |
| Drive A: / Drive B: | Monta o desmonta una imagen EDSK |
| Scanlines | Lineas de barrido: Off, 25%, 50%, 75% |
| Boot | Real 5.6s (como la maquina) o Fast |
| Disk ROM | Activa la ROM de disco y la controladora |
| RAM | 32K, 96K, 512K o 768K (mas de 32K pone el modulo de expansion) |
| H centre / V centre | Centrado de la imagen |
| Monitor | Color del fosforo: White, Green, Amber, Cyan |
| I2C LCD address | Direccion de la pantalla LCD (27h, 3Fh, 20h, 38h) |
| Tape monitor | Se oye la cinta por el altavoz |
| Test tone | Tono de prueba del audio |
| Tape source | File (el `.bas` montado) o Audio in |
| Rewind tape | Vuelve la cinta al principio |
| Reset | Reinicia el NewBrain |

### Uso rapido

- **Cinta con la ROM de disco puesta:** `LOAD` va al disco. Para la cinta
  (fichero `.bas` del menu o audio): `OPEN IN#1,1` y luego `LOAD #1`
  (`IN#` pegado; con espacio da ERROR 14). O apagar la ROM de disco.
- **CP/M con 32K:** `cpm` desde BASIC.
- **Cambiar de disco en CP/M:** despues de montar otra imagen, pulsar
  `^C` en el indicador `A0>`. Sin eso CP/M sigue usando el directorio del
  disco anterior (lo guarda en memoria), como en la maquina real.
- **CP/M con expansion:** RAM de 96K o mas y `NB_ISSUE3.ROM`; en el menu
  del sistema paginado, dos flechas abajo y nueva linea. Desde el BASIC
  paginado se sale a CP/M con `EXIT`, no con `cpm` (da ERROR 55).
- **Juegos de ROM:** `NB_ISSUE1` tiene el teclado bien; `NB_ROM20` tiene la
  tabla de teclado mal (`;` da `m`). Con expansion, `NB_ISSUE3`: con la
  series2 el cursor del menu paginado empieza sobre BASIC y la flecha abajo
  no lo mueve.

## Placas

| Placa | FPGA | Reloj | Proyecto | Macros |
|---|---|---|---|---|
| MiST | Cyclone III EP3C25E144C8 | 27 MHz | `mist/` | MIST, DELTASIGMA_AUDIO (sin entrada de audio) |
| Calypso | Cyclone 10 LP 10CL025 | 12 MHz | `calypso/` | I2S_AUDIO, USE_AUDIO_IN |
| SiDi | Cyclone IV EP4CE22 | 27 MHz | `sidi/` | SIDI, DELTASIGMA_AUDIO, USE_AUDIO_IN |
| Poseidon | Cyclone IV GX EP4CGX150 | 50 MHz | `poseidon/` | POSEIDON, I2S_AUDIO, USE_AUDIO_IN |

Todas llevan NO_DIRECT_UPLOAD y BIG_OSD. MIST y SIDI definen dentro del
top `RELOJ_27` (entrada CLOCK_27, VGA de 6 bits) y `UN_SOLO_LED`. Los pines
del MiST salen de Amstrad_MiST.qsf de gyurco; su PLL es el de la SiDi
(misma entrada de 27 MHz) para Cyclone III. En el MiST, los pines del
puerto V24 del bloque de extras ya apuntan a su UART (PIN_46 TX, PIN_31 RX),
comentados. El MiST se compila con **Quartus 13.1** (el ultimo con Cyclone III), asi que
su `pll.qip` va en el formato de esa version (sin `IP_GENERATED_DEVICE_FAMILY`,
que Quartus 13 no conoce), como el `cyc3/pll.qip` del Amstrad de gyurco.
El EP3C25 tiene los mismos recursos que el 10CL025 de la
Calypso (24.624 celdas, 66 M9K), asi que el core cabe igual.

`make integration` elabora el top con las macros de cada placa y comprueba
con `tools/nbpines.py` que cada puerto tiene pin y cada pin su puerto
(siguiendo tambien los `define` que el top hace segun la placa).

## Estructura

    rtl/      fuentes del core (newbrain_top.sv es el top de todas las placas)
    calypso/  proyecto de la Calypso: .qsf, .sdc, PLL de 12 MHz
    sidi/     proyecto de la SiDi: .qsf, .sdc, PLL de 27 MHz
    poseidon/ proyecto de la Poseidon: .qsf, .sdc, PLL de 50 MHz
    common/  submodulos: T80 y mist-modules, mas build_id.tcl
    doc/     referencia de hardware y decisiones de diseño
    test/    bancos de pruebas (Icarus Verilog)
    roms/    donde va la ROM (no se incluye)
    tools/   utilidades de analisis de ROMs

## Compilar

Los submodulos ya vienen incluidos en `common/`. Si prefieres gestionarlos
con git:

    git submodule update --init

(las URLs estan en `.gitmodules`, apuntan a los forks de teiram que usa
calypso-ports).

Hay un proyecto por placa, y los dos compilan el mismo core:

| Placa | Proyecto | Salida |
|-------|----------|--------|
| Calypso | `calypso/newbrain_calypso.qpf` | `calypso/output_files/newbrain_calypso.rbf` |
| SiDi | `sidi/newbrain_sidi.qpf` | `sidi/output_files/newbrain_sidi.rbf` |
| Poseidon | `poseidon/newbrain_poseidon.qpf` | `poseidon/output_files/newbrain_poseidon.rbf` |

Abrir el que toque en Quartus 22.1 Lite y compilar. Lo comun esta en
`files.qip`, con rutas relativas a ese fichero, asi que vale igual desde
cualquiera de las tres carpetas. Cada proyecto pone lo suyo: el PLL, el `.sdc`, los
pines y las macros.

### SiDi

Cyclone IV EP4CE22 con reloj de 27 MHz. El pinout y los ajustes vienen del
core de Oric de rampa069 (`Oric_Mist_48K/sidi`), pero sin DeMiSTify: la
SiDi lleva su propio microcontrolador con el firmware de MiST, asi que el
OSD, la carga de ROM y cinta y el montaje de discos funcionan igual que en
la Calypso. El top es `rtl/newbrain_top.sv` con la macro `SIDI`, que cambia
solo lo que es de la placa:

| | Calypso | SiDi | Poseidon |
|---|---|---|---|
| FPGA | Cyclone 10 LP | Cyclone IV E EP4CE22 | Cyclone IV GX EP4CGX150 |
| Reloj de entrada | 12 MHz | 27 MHz | 50 MHz |
| PLL | x 8 / 3 | x 32 / 27 | x 16 / 25 |
| VGA | 4 bits por color | 6 bits | 6 bits |
| Audio | I2S | sigma-delta | I2S |
| LEDs | ocho de diagnostico | uno de actividad | uno de actividad |
| Macro | (ninguna) | `SIDI` | `POSEIDON` |

La Poseidon viene del `.qsf` del Amstrad de gyurco
(`Amstrad_Poseidon_GX150.qsf`): mismo pinout, ajustes y restricciones.

Los dos PLL dan lo mismo, 32 MHz para el sistema y 32 MHz desfasados para
la SDRAM, asi que todo lo que va por dentro es identico. La SDRAM de la SiDi
es de 32 MB y la de la Calypso de 8: el controlador usa el trozo comun, y
refresca al ritmo del chip grande (8192 filas en 64 ms), que tambien vale
para el pequeño.

El LED de la SiDi se enciende mientras se carga algo por el menu, mientras
la cinta lee o graba y mientras trabaja la controladora de disco.

**Sin probar en la placa.** `make integration` elabora el top con la
configuracion de la SiDi y comprueba que cada puerto tiene su pin, pero la
compilacion en Quartus y la prueba en hardware estan por hacer. Si TimeQuest
se queja de la SDRAM, los retardos de `sidi/newbrain_sidi.sdc` son los de la
Calypso y es lo primero que hay que ajustar.

El PLL (`pll.v`) da **dos salidas de 32 MHz** (12 x 8 / 3): `c0` desfasada
-7800 ps para el reloj de la SDRAM y `c1` sin desfase para el sistema. El
orden importa: el `.sdc` referencia `clk[0]` como reloj de la memoria.

**No abras el PLL en el asistente de megafunciones.** El bloque de
"Retrieval info" del final de `pll.v` es lo que lee esa ventana, y al pulsar
Finish regenera el fichero a partir de el. Esta puesto al dia para que
coincida con los factores reales, pero si algo se descuadra los valores
buenos son los de las lineas `altpll_component.clk*`, no los comentarios.

Para meter el core en calypso-ports basta con copiar la carpeta y cambiar en
el `.qsf` la ruta de `common/build_id.tcl` por `../common/`, que es la
convencion de ese repositorio; `files.qip` ya no depende de donde este.

## Tests

    cd test && make

Catorce bancos de pruebas: mapa de memoria (incluido el forzado a ROM2
durante el arranque), temporizadores RC de RESET y PWRUP, decodificado de
E/S con registros de video y palabra de estado, codificacion de teclas
contrastada contra `KTABLE` de la ROM, la secuencia completa de interrupcion
del COP con las ramas de cassette, la cinta de audio contra la forma de onda
de `beepgenerator.py` y en bucle cerrado con el modulador, la controladora de
disco contra un modelo del protocolo de imagenes de `user_io`, el recorrido
de pantalla del generador de imagen, el controlador de SDRAM contra un
modelo de comportamiento del chip, la paginacion, y dos pruebas de maquina
entera.

`make rom` va mas alla y ejecuta **la ROM real** contra un modelo en Python
del HLE: teclea un programa, lo graba, lo vuelve a cargar y comprueba que
sale entero, ademas del camino de error. Necesita `pip install z80` y la ROM
en `roms/NEWBRAIN.ROM`, o `make rom ROM=ruta`.

`make romdisco` hace lo propio con la disquetera, y ahi hay **dos Z80 a la
vez**: el del NewBrain con su ROM de disco y el de la controladora con la
suya, mas un uPD765 en Python leyendo un EDSK. Con `TECLAS=` se le dice que
escribir despues de arrancar:

    make romdisco DSK=cpm.dsk D413=d413.bin D417=d417.bin TECLAS=cpm

`make lint` elabora la maquina entera con un stub del T80, sin necesidad de
los submodulos. `make integration` va mas alla: elabora el top completo
contra los modulos reales de mist-modules, sustituyendo por stubs solo el T80
(VHDL, que Icarus no lee), el PLL (IP de Altera) y el `dac.vhd`. Detecta
nombres de puerto y anchos mal conectados, que es justo lo que no ve ninguna
simulacion de modulo suelto. Lo hace tres veces: Calypso con I2S, Calypso
con sigma-delta y SiDi. Y con `tools/nbpines.py` comprueba que cada puerto
del top tiene su pin en el `.qsf` de cada placa, resolviendo los `ifdef` con
las macros del propio `.qsf`: un puerto sin pin Quartus lo coloca donde
quiere, y en una placa real eso puede ser un cortocircuito.

## Herramientas

`tools/nbsim.py` ejecuta una ROM contra un modelo del core escrito en Python,
con el mismo mapa de memoria, la misma decodificacion de puertos y el mismo
protocolo del COP:

    python3 tools/nbsim.py roms/newbrain-v20.rom

No sustituye a la simulacion del RTL: lo que responde es si la ROM se
comporta como esperamos con **nuestra** interpretacion de la maquina. Sobre
hardware, un error de diseño y un error de comprension son indistinguibles;
esto los separa.

`tools/copdasm.py` desensambla COP400 y COP420, con el mapa de opcodes
tomado del core T400 en VHDL:

    python3 tools/copdasm.py cop420.bin

El resultado de la ROM del NewBrain esta en `doc/desensamblados/cop420.asm`.

`tools/nbdrivers.py` busca registros excitados desde dos bloques `always`.
Icarus los simula sin quejarse, resolviendo el ultimo que escribe, pero
Quartus los rechaza con "Can't resolve multiple constant drivers" y cada
hallazgo cuesta una sintesis entera. Se ejecuta con `make` junto al resto.

`tools/nbwav.py` genera el audio de cinta a partir de un fichero `.bas` o
`.bin`, con las mismas muestras que `beepgenerator.py` de gylles38 pero sin
sus dependencias:

    python3 tools/nbwav.py programa.bas programa.wav

Con `--bits` saca una muestra por linea, que es lo que come el banco de
pruebas del desmodulador.

`tools/nbfix.py` mira ficheros `.BAS`, dice de que tipo son y arregla los
que no valen para cargar, dejando una copia con `_fix` en el nombre. Acepta
varios ficheros o una carpeta entera:

    python3 tools/nbfix.py descargas/

`tools/nbbas.py` hace lo mismo pieza a pieza, y ademas en sentido contrario
(de cinta a programa en crudo):

    python3 tools/nbbas.py envuelve WORD.BAS WORD-cinta.bas WORD
    python3 tools/nbbas.py extrae   snake.bas snake-crudo.bas

`tools/nbdemod.py` hace el camino inverso: desmodula un fichero de audio con
el mismo algoritmo que el RTL y dice si sale lo que tiene que salir. Sirve
para saber si un WAV (o un MP3, o lo que sea que abra ffmpeg) va a cargar
antes de llevarlo a la placa:

    python3 tools/nbdemod.py cinta.wav cinta.bas

`tools/nbpag.py` arranca el sistema paginado con las ROMs originales y el
mismo decodificado de memoria que el RTL (`make rompag KB=512`).

`tools/nbcopreal.py` pone frente a frente la ROM del Z80 y la del COP420,
ejecutada por `tools/nbcop420.py` (un COP420 portado de MAME), y
`tools/nbcop420dasm.py` desensambla la ROM del COP.

`tools/nbcinta.py` es la prueba de cinta contra la ROM real, la que lanza
`make rom`, y `tools/nbdisco.py` la de la controladora de disco.

`tools/nbports.py` extrae y clasifica los accesos de E/S de una ROM,
apoyandose en z80dasm:

    python3 tools/nbports.py ROM.bin E000

Sirve para atacar ROMs que aun no entendemos buscando primero por donde
hablan con el hardware. Contrastado contra la EFROM, cuyo listado simbolico
tenemos: encuentra los mismos puertos en las mismas direcciones.

El rastreo de B y C para las formas `(c)` es lineal, asi que solo vale dentro
de un bloque basico; lo que queda lejos se descarta en vez de inventar un
valor.

### Herramientas de disco (`tools/disco/`)

Para preparar las imagenes EDSK que monta la disquetera. Documentacion
completa en `doc/15-herramientas-disco.md`.

| Herramienta | Para que sirve |
|---|---|
| `disco/td0conv.py` | Teledisk `.TD0` a EDSK (`.dsk`) o raw (`.img`) |
| `disco/dir2dsk.py` | Un directorio del PC a un disquete CP/M del NewBrain (200K/400K/800K); con `-s` copia las pistas de sistema para hacerlo arrancable |
| `disco/raw2dsk.py` | Volcados raw (emulador de cdesp, dumps) a EDSK; `-v` lista el catalogo |
| `nbdsk2raw.py` | EDSK a raw, en el mismo orden (para sacar las pistas de sistema de un `.dsk` y darselas a `dir2dsk.py -s`) |
| `nbcpmdir.py` | Arranca CP/M en la cosimulacion con un disco y comprueba lo que lista `DIR` |
| `../test/verilator/tb_u765_edsk.cpp` | Banco Verilator: monta un EDSK en `u765.sv` y lo verifica pista a pista |

Los tres de `disco/` se importan entre si: tienen que ir juntos. Ejemplo de
un disco arrancable con tus ficheros:

    python3 tools/nbdsk2raw.py SSDD200K.dsk sistema.img
    python3 tools/disco/dir2dsk.py MISCOSAS -s sistema.img -F 200K

Prueba de punta a punta (`make disco` en `test/`): un disco hecho asi
arranca CP/M en la cosimulacion y `DIR` lista sus ficheros.

## Diagnostico

### Patron de prueba

La opcion "Patron de prueba" del OSD dibuja un marco con rejilla sin depender
de nada de la maquina: ni ROM, ni SDRAM, ni CPU. Sirve para partir el
problema en dos de un vistazo.

- **Se ve el patron** -> el camino de imagen, `mist_video` y el scandoubler
  estan bien. El fallo esta aguas arriba: memoria, ROM o CPU.
- **No se ve** -> el problema esta en el generador de imagen o en la
  temporizacion, no en la maquina.

### LEDs

Esto es de la Calypso, que tiene ocho. La SiDi tiene uno solo, de actividad.

Van **sin invertir**. Los dos primeros son referencias fijas para averiguar
la polaridad de la placa y por que extremo empieza la fila:

| LED | Significado |
|-----|-------------|
| 0 | constante 1 |
| 1 | hay señal en la entrada de cinta (cualquier flanco lo enciende medio segundo) |
| 2 | latido de ~1 Hz: si late, el PLL engancho y `clk_sys` corre |
| 3 | PWRUP: a 1 cuando el mapa de memoria ya esta asentado |
| 4 | la SDRAM acabo su secuencia de arranque |
| 5 | la ROM habilito el video (ENRG1 bit 2); parpadea si la controladora de disco trabaja |
| 6 | INT solicitada por la maquina; parpadea mientras se lee cinta |
| 7 | INT aceptada por el Z80; parpadea mientras se graba cinta |

Un patron util para diagnosticar: si el 3 parpadea (PLL viva), el 4 se
enciende (PWRUP hecho) y el 5 tambien (SDRAM lista), pero el 6 sigue apagado
con el 7 encendido y el 8 apagado, la CPU esta dando vueltas con las
interrupciones todavia deshabilitadas. Eso solo pasa en el bucle `PWAIT` de
`E009`, o sea que la maquina no llega ni a encender el video y hay que mirar
la palabra de estado `UST_A`, no el video.

En la Calypso los LEDs son **activos a nivel alto**: encendido es 1.

Sobre los dos ultimos: simulando la ROM se ve que **es la interrupcion de
reloj la que habilita el video**, sin necesidad del COP. Si el 6 destella y el
7 no, el Z80 no esta aceptando la peticion; si no destella ninguno, la
peticion no se esta generando.

### Cinta

Dos fuentes, elegibles en el OSD. **"Cargar cinta"** trae una imagen `.bas`
o `.bin` desde la SD, que es el camino fiable, y cargarla no reinicia la
maquina. **"Fuente de cinta: Audio"** desmodula la entrada con el formato
de `beepgenerator.py` (gylles38), que carga en maquinas reales. El umbral
entre semiperiodo corto y largo esta fijo en 330 us, que es con el que carga
en la Calypso; la entrada pide bastante volumen. `TQ,Rebobinar cinta` vuelve al principio.

Lo que la maquina graba sale por el audio ya modulado, mientras graba, sin
tocar nada del menu: se puede llevar a un grabador o al PC.

Si no entra o no se oye, **LED 1** dice si llega señal a la entrada de
cinta y **"Tono de prueba"** saca 1 kHz por el audio sin tocar la maquina.
Entre los dos se sabe de que lado esta el fallo; ver `doc/11-cinta.md`.

La entrada de cinta entra por el pin `AUDIO_IN`, pasa por dos biestables de
sincronizacion y llega al desmodulador y al bit 5 de `UST_B`. La opcion
**"Escuchar cinta"** saca esa misma señal por el audio, ya sincronizada;
viene apagada por defecto.

La cinta solo vuelve al principio con **"Rebobinar cinta"** o al meter una
nueva: reiniciar la maquina no la mueve, igual que un casete.

### Salida de audio

La Calypso saca el audio por **I2S**, que es lo que viene activado
(`I2S_AUDIO` en `newbrain.qsf`). Para placas sin I2S hay una salida
**sigma-delta** de un bit por canal, `AUDIO_L` y `AUDIO_R`, con el modulador
de `common/mist-modules/dac.vhd`: se activa con `DELTASIGMA_AUDIO`, y en el
`.qsf` estan comentadas las lineas a tocar. La placa tiene que llevar el
filtro RC de siempre (3k3 y 4n7). Por los dos caminos sale lo mismo: la
cinta mientras se graba, "Escuchar cinta" y el tono de prueba.

Si `LOAD` da ERROR 131, no es un problema de nivel ni de velocidad: es
`LENGTHERR`, y lo que falla es el protocolo. Todo el asunto esta en
`doc/11-cinta.md`.

### Disco

La disquetera pide **RAM: 32K**: con mas, el core entiende que hay modulo de
expansion y la desactiva.

Con la ROM de disco activada, **`LOAD` va al disco**, igual que en la maquina
real (un `LOAD` sin mas da ERROR 150, "nombre de fichero incorrecto" en un
dispositivo de disco). Para cargar de cinta hay que abrir el dispositivo 1:

    OPEN IN#1,1
    LOAD #1

(`IN#` va pegado; con espacio da ERROR 14.) Comprobado en la cosimulacion
con la ROM de disco puesta.

Los discos de CP/M probados vienen configurados con **una sola unidad**:
`DIR B:` da "Bdos Err On B: Select" sin que la controladora llegue a oir
nada. La unidad B se da de alta desde CP/M con `CONFIGUR` y se guarda con
`SAVECON`, que estan en el propio disco.

**"Disco A:"** y **"Disco B:"** montan imagenes **EDSK** de la SD, y las
escrituras van a la tarjeta. La controladora no esta emulada por encima: es
un **segundo Z80 ejecutando la ROM original de Grundy** (`d417`) con un
uPD765 (`u765.sv` de gyurco) leyendo los EDSK. Con las dos ROMs de disco en
el fichero y un disco de sistema, `cpm` arranca CP/M 2.2. Ver
`doc/13-disquetera.md`.

### Extras

Puertos serie, remote de las cintas y una pantalla LCD 16x2 por I2C con el
texto del display fluorescente. Vienen desactivados; ver `doc/14-extras.md`.

### Display

"Display" en el OSD tine la imagen como los monitores monocromo de la
epoca: **Blanco** (el original), **Verde**, **Ambar** o **Cyan**. La maquina
saca un solo bit de luminancia y aqui solo se le cambia el color; las
proporciones son las del core del Amstrad de gyurco (`color_mix.sv`), con el
ambar llevando el verde a tres cuartos del rojo.

### Centrado

"Centrado H" y "Centrado V" en el OSD mueven la zona activa en pasos de 8
puntos y 2 lineas. Por defecto los porches quedan simetricos: de los 1024
puntos de linea, 640 son imagen, 76 sincronismo y los 308 restantes se
reparten a partes iguales delante y detras.


## Documentacion

Empieza por `doc/01-hardware.md`. Las fuentes y su fiabilidad relativa estan
en `doc/04-fuentes.md` — merece la pena leerlo antes de dar por buena
cualquier referencia externa.
