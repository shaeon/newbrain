# Cinta

Todo lo de este documento sale del **fuente original del driver de cinta**,
`TPIO.S` y `OS.S2` de la carpeta `ROM/EFROM` de `cdesp/ModNewbrain`. La ROM
EF que usamos coincide byte a byte con `EMU_EFROM.bin` de ese repositorio,
que es la de Grundy sin tocar (`EFROM.BIN`, en cambio, es la version que
cdesp parcheo para su placa y no vale como referencia).

## ERROR 131 no es un tiempo agotado

`TPIO.S` define los errores de cassette:

| Codigo | Nombre | Cuando |
|--------|--------|--------|
| 131 | `LENGTHERR` | el bloque dice medir mas que el buffer |
| 132 | `CHECKSUMERR` | la suma no cuadra |
| 133 | `ENDDATAERR` | se pide mas despues del ultimo bloque |
| 134 | `SEQUENCERR` | el tipo de bloque no es el que toca |
| 135 | `OUTINERR` | leer de un canal de escritura o al reves |
| 136 | `SYNTAXERR` | nombre de fichero mal formado |

El 131 que daba el core al instante venia de que la ROM recibia una
longitud absurda. El porque esta en como se recibe cada byte.

## Como recibe la ROM un byte

`TCHR` (`EF53`), a la que se llega con `RST 8`:

    TCHR   PUSH HL
           DI
           LD HL,COPBUF
           LD (HL),A        ; deja A en el buffer (para grabar)
           CALL WTRDY       ; espera al bit READY de COPST
           BIT CERR,(HL)
           INC HL
           LD A,(HL)        ; y devuelve lo que haya en el buffer

`READY` lo pone la rutina de interrupcion del COP en las ramas REGINT,
CASSIN, CASSOUT y CASSERR. **Cualquier REGINT** que llegue mientras la ROM
espera un byte hace que `TCHR` devuelva lo que ella misma habia escrito. El
HLE antiguo seguia mandando REGINT cada 20 ms durante la carga; si uno caia
en la longitud, la ROM leia `8C` y contestaba 131.

Por eso el emulador de cdesp, mientras carga, convierte **todas** las
interrupciones en CASSIN. Es la regla principal del HLE nuevo:

- reproduciendo, el COP solo genera CASSIN;
- grabando, solo CASSOUT;
- el teclado espera.

## Secuencia de un bloque

`RDBLCK` (`EF1F`) y `PRETRD` (`EF4D`):

    PRETRD LD A,84h          ; CASSCOM + PLAYBK
           CALL CASSON       ; + motor (8 o 2): 8C u 86
           RST 8             ; primer byte...
    TCHR   ...               ; ...y cae dentro de TCHR: segundo byte

1. **El comando llega dos veces.** `CASSON` llama a `CASRPT` y despues cae
   en ella. `CASRPT` espera un `READY` y deja el comando en `COPCTL`, que
   viaja como **reconocimiento de la siguiente interrupcion**. El segundo
   `8C` se ignora.
2. **El primer byte se tira.** `PRETRD` llama a `TCHR` y luego cae en ella,
   asi que lee dos bytes y se queda con el segundo. El primero es el `00`
   de sincronismo del fichero.
3. Longitud (dos bytes), datos, tipo y suma (dos bytes). `CASRPT` deja en
   `CHKSUM` la direccion de `COPCTL`, `003B`: de ahi sale el `+3B` de la
   suma.
4. **Fin.** `NOEREX` pone `NULLCOM` en `COPCTL` y espera tres `READY` mas.
   Si se siguieran mandando CASSIN, esos bytes se perderian. El HLE para
   tras la suma y **descarta los nueve ceros de cola**, como cdesp.
5. Cada bloque vuelve a empezar con su propio `CASSON`.

### Errores y BREAK

- Si la ROM abandona el bloque (131, 132, BREAK), manda `NULLCOM` en el
  reconocimiento. El HLE lo toma como fin de bloque y **descarta lo que
  faltaba**, para que el siguiente `LOAD` empiece en su sitio.
- El vector `2X` con el bit 0 a uno es **de estado**, no un dato; con el
  bit 1 ademas es BREAK (`SCHBIT` en `OS.S2`). El HLE lo manda al pulsar
  STOP durante una carga. El error de lectura va por el vector `1X`
  (`DROPOUTERR`), no por el bit 0 como deciamos antes.

### Una carrera que hay que evitar

`PUTCS` habilita interrupciones unas instrucciones antes de que `TCHR` las
vuelva a quitar. Un CASSIN que llegue en esa ventana deja el byte en
`COPBUF`, `TCHR` lo pisa con `A` y devuelve basura: ERROR 132. El HLE espera
**5 ms** desde el `CASSCOM` hasta el primer byte y **2 ms** entre bytes. En
cinta real hay casi un segundo de piloto, asi que no cambia nada.

## Validacion contra la ROM

`tools/nbcinta.py` ejecuta la ROM real contra un modelo en Python del HLE,
con las mismas reglas que el RTL:

1. teclea `10 print 12345` / `20 goto 10` y `save`, y recoge lo grabado;
2. `load` de una copia con la suma estropeada: tiene que dar **ERROR 132**
   y dejar la cinta al principio de la copia buena;
3. `load` y `list` de la copia buena: el programa vuelve entero;
4. `load` y `list` de la cinta sola.

Se lanza con `make rom` en `test/` (necesita `pip install z80` y la ROM en
`roms/NEWBRAIN.ROM`, o `make rom ROM=ruta`). Lo que graba la ROM es:

    00 0000 81 bc00 000000000000000000        bloque de nombre, vacio
    00 1600 0d040d3031208520... 41 7504 00..  programa, ultimo bloque

## Dos cosas distintas con extension .BAS

Por ahi circulan dos formatos con el mismo nombre, y solo uno es una cinta:

| | Empieza por | Que es |
|---|---|---|
| Cinta | `00` | bloques con sincronismo, longitud, tipo y suma: lo que lee el core |
| Programa en crudo | `0D` | el texto del programa tal cual, sin envolver |

Ejemplos de los que corren por la red: `snake.bas`, `nimtape.bas` y
`TheCrossing.bas` son cintas; `WORD.BAS`, `BOMB.BAS`, `GALOAD.BAS` y
`STARTREK.BAS` son programas en crudo, probablemente sacados de un disco.

**El texto va del reves dentro de cada bloque.** El BASIC del NewBrain
guarda el programa hacia abajo en memoria, asi que cada bloque sale
invertido byte a byte, pero los bloques van en el orden normal del
programa. No es una inversion del fichero entero: eso da un programa
rotado, con la mitad de una linea al principio.

El programa acaba en la marca `0D 04 0D`. Los volcados en crudo suelen
llevar basura detras, restos de lo que hubiera antes en memoria.

`tools/nbfix.py` es la version practica: se le echan ficheros o una carpeta,
dice que es cada uno y deja un `NOMBRE_fix.BAS` ya envuelto por cada
programa en crudo. Las cintas que ya estan bien no las toca, y una cinta con
la suma rota la deja en paz avisando, para no empeorarla.

`tools/nbbas.py` convierte en los dos sentidos:

    python3 tools/nbbas.py mira     WORD.BAS
    python3 tools/nbbas.py envuelve WORD.BAS WORD-cinta.bas WORD
    python3 tools/nbbas.py extrae   snake.bas snake-crudo.bas

La ida y vuelta de `snake.bas` devuelve el fichero original byte a byte, y
lo convertido carga y lista bien en el simulador con la ROM real.

## Formato de fichero

El de cdesp (`.bas` y `.bin`), un fichero por programa, con uno o mas
bloques seguidos:

| Offset | Campo | Tamaño |
|--------|-------|--------|
| 0 | sincronismo, `00` | 1 |
| 1 | longitud, little endian | 2 |
| 3 | datos | longitud |
| 3+L | tipo: b7 primero, b6 ultimo, b5-b0 secuencia | 1 |
| 4+L | suma: longitud + datos + tipo + `3B` | 2 |
| 6+L | cola de ceros | 9 |

Los tipos que usa el driver: `81` nombre, `82` cierre, `83` binario, y los
de datos con su numero de secuencia.

La cola se descarta **solo mientras sean ceros**: un fichero con la cola mas
corta no pierde el sincronismo del bloque siguiente.

## Fuente de fichero

"Cargar cinta" trae el fichero a la SDRAM, banco 3 (`600000`), sin
reiniciar la maquina. Mientras dura la carga la cinta se ve vacia, y una
cinta recien metida empieza por el principio, como un casete nuevo.

A partir de ahi la cinta **solo se mueve leyendo**, como un casete de
verdad: ni reiniciar la maquina ni acabar un programa la devuelven al
principio. Asi, tras un `LOAD`, el siguiente carga el programa que viene
detras en la cinta. Para volver atras esta "Rebobinar cinta" en el OSD.
Antes el reset de la maquina la rebobinaba, y despues de reiniciar se volvia
a cargar el primer programa.

La peticion de byte a la SDRAM **se retiene hasta el ack**. Antes era un
pulso de un ciclo y se perdia si la CPU ganaba el puerto en ese ciclo; como
`pendiente` quedaba a uno no se reintentaba nunca. Este arreglo es el que
propuso DeepSeek, y es correcto.

## Fuente de audio

El formato sale de `beepgenerator.py` de **gylles38/newbrain-bin-wav**, que
segun el foro de newbrainemu.eu carga en NewBrain reales (quien lo probo
dice que lo retoco un poco, sin detallar que):

| Simbolo | Forma |
|---------|-------|
| bit 0 | un ciclo largo, semiperiodos de ~408 us |
| bit 1 | dos ciclos cortos, semiperiodos de ~204 us |
| piloto | largo, corto, corto, largo; ~1000 veces |
| inicio | un bit 1 |
| byte | 8 bits, el mas significativo primero, y despues `0` `1` |

El desmodulador solo mide semiperiodos, asi que la polaridad del comparador
da igual. Necesita al menos 64 parejas de piloto antes del bit de inicio y
abandona el bloque tras 1,5 ms sin flancos.

La frontera corto/largo esta fija en **330 us**, no en el punto medio
teorico de 306. Con 330 cargan las cintas en la Calypso: su entrada de oreja
pasa por un transistor que hace de comparador y alarga el semiperiodo en que
conduce, asi que el reparto real no queda centrado. Era una opcion del menu
y se ha quitado. El umbral antiguo estaba en unidades de 0,5 us y quedaba
unas cuarenta veces por debajo, que es harina de otro costal.

La entrada pide **bastante volumen**: con la salida floja el transistor no
conmuta. Si no carga, antes de tocar nada hay que mirar el LED 1.

`tools/nbwav.py` genera la misma forma de onda que la herramienta original,
sin sus dependencias, en WAV o como muestras para los bancos de pruebas.
`tb_newbrain_tape.v` la desmodula y comprueba byte a byte. Y
`tools/nbdemod.py` desmodula un fichero de audio cualquiera con el mismo
algoritmo del RTL, asi que se puede saber de antemano si un WAV, un FLAC o
un MP3 va a cargar. Los formatos con perdida sobreviven porque el core solo
mira cruces por cero, no la forma de la onda.

**Ojo con una rareza de esa herramienta**: cuenta los ceros de cola
incluyendo la suma, asi que si el byte alto de la suma es `00` el noveno
cero sale despues del piloto del bloque siguiente. Una maquina real (y el
core) lo tomaria por el sincronismo. Afecta a uno de cada 256 bloques y
puede ser el origen de los ERROR 132 ocasionales de los que se habla en el
foro.

## Si no se oye nada, o no carga por audio

La entrada de cinta de la Calypso (la "oreja") pasa por un BC846 que hace
de comparador, y necesita nivel: con el volumen bajo o una salida de linea
floja el transistor no conmuta y al core no le llega nada. Para no tener
que adivinar donde esta el corte hay dos ayudas:

- **LED 1**: se enciende con cualquier flanco en la entrada de cinta. Si al
  reproducir la cinta no se mueve, el problema esta antes del core: cable,
  volumen o la propia entrada. No depende del menu ni del sonido.
- **"Tono de prueba" en el OSD**: saca una onda cuadrada de 1 kHz por el
  audio, sin tocar nada de la maquina. Si no se oye, lo que falla es la
  salida de audio, no la cinta.

Con los dos se separan las tres averias que se parecen: no entra señal, no
sale sonido, o entra y sale pero el umbral no cuadra.

## Grabacion

SAVE sigue el protocolo: CASSOUT al ritmo del modulador, que emite el
mismo formato por la salida de audio (piloto al empezar cada bloque). El
sonido sale siempre que la maquina graba, sin tocar "Escuchar cinta", y se
puede llevar a un grabador o al PC. Los bytes no se guardan todavia en la
SD: eso pide escritura por `data_io`.

## Otros cambios alrededor

- **`UST_A` multiplexado** por `ENREG`. Ver `01-hardware.md`. En el banco
  `10` el bit 0 es la entrada de cinta; se da como cdesp: 0 mientras se lee.
- **Arbitro de la SDRAM** con un unico dueño. Cargar una cinta con la
  maquina en marcha podia perder escrituras de `data_io` o dejar la CPU
  parada.
- **Carga de cinta separada de la de ROM**: antes una cinta desactivaba la
  ROM de disco y el COP real, y una de mas de 24K pisaba el generador de
  caracteres.
- **LEDs 6 y 7**: parpadean mientras se lee o se graba.

## Con la ROM de disco puesta

`LOAD` va al disco, como en la maquina real. Para cargar de cinta (fichero
o audio):

    OPEN IN#1,1
    LOAD #1

(`IN#` pegado; con espacio da ERROR 14.) Vale tambien con el sistema
paginado. O apagar la ROM de disco en el menu.

## Quien lleva la cinta ahora

El COP de verdad lleva teclado, pantalla y reloj, y la cinta la lleva este
modulo (`newbrain_cop_hle` en modo solo cinta) a traves de
`newbrain_cop_mux`: cuando el Z80 contesta a una interrupcion con un
CASSCOM, el modulo se queda el puerto hasta acabar y al COP de verdad le
llega un NULLCOM. El remote de las cintas sale de aqui (`cass_motor`). Ver
`doc/12-cop-real.md` y `doc/14-extras.md`.

## Estado

| | |
|---|---|
| Protocolo CASSIN / CASSOUT | hecho, contrastado con la ROM real |
| Fuente de fichero | hecha |
| Fuente de audio | hecha, validada contra la forma de onda de gylles38; falta probarla con una cinta de verdad |
| Grabacion a audio | hecha |
| Grabacion a fichero | pendiente |
