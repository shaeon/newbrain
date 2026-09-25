# Fase 5: el COP420 de verdad

## Por que no escribir el core a mano

La primera idea era implementar un COP400 en Verilog. Existiendo **T400**, de
Arnim Laeuger, no tiene sentido: es una implementacion en VHDL ya hecha, con
licencia BSD, y —lo que la hace idonea— trae **soporte MICROBUS**, que es
exactamente el modo en que el NewBrain usa el COP.

Ademas nuestra cadena ya digiere VHDL sin problemas: el T80 lo es.

Se usa `t400_core` directamente y no el envoltorio `t420`, porque el core
expone la memoria de programa y la de datos como puertos externos
(`pm_addr_o`/`pm_data_i`, `dm_*`). Asi podemos alimentarlo con la ROM
`cop420-guw.ic419` cargada desde la SD, en vez de empotrarla en el bitstream.

## Lo que hay hecho

**El core traido al proyecto**, en `common/T400/`, con su aviso de copyright
intacto y los 19 ficheros de `rtl/vhdl`. Registrados en `files.qip` en orden
de dependencias.

**Las memorias** (`newbrain_cop_mem.v`): 1K de ROM cargable y 64 nibbles de
RAM. La RAM es de lectura asincrona, como la del chip real.

**El envoltorio** (`newbrain_cop_real.v`) con la circuiteria que rodea al
microcontrolador en la placa, cableada segun MAME:

| Pata | Conexion |
|------|----------|
| IN0 | K8, salida Q2 del latch CD4076 |
| IN1..IN3 | `_RD`, `_CS`, `_WR` del microbus |
| L0..L7 | bus de datos del microbus |
| G0 (out) | `_COPINT` |
| G1, G3 (out) | motores de los dos cassettes |
| G1..G3 (in) | resto de bits del latch de teclado |
| D0 | reset del contador CD4024 |
| D1 | `TDO`, salida a cinta |
| D2 | reloj del CD4024 y del CD4076, y habilitacion del DS8881 |
| SO / SK | trama de 16 bits al display fluorescente |
| SI | `TDI` = `TPIN` xor `TDO` |

Incluye el **contador CD4024** que recorre las filas del teclado y el **latch
CD4076** que devuelve los cuatro bits, porque son parte del circuito, no del
chip.

**El teclado expone la matriz cruda.** Antes solo daba un byte de tecla ya
codificado, que es lo que necesita el HLE; ahora tambien saca la fila que le
pida el contador, que es lo que necesita el COP real. Hay banco de pruebas
para las dos formas.

**La ROM del COP en el fichero de carga**, 1K al final, en `F000`.

## De VHDL a Verilog

Icarus no simula VHDL, asi que con el core en VHDL la fase 5 se habria
validado solo en la placa, a ciegas comparado con como hemos trabajado hasta
ahora. Por eso se convierte con **GHDL**, que sintetiza VHDL y sabe emitir
Verilog:

    tools/convierte_t400.sh common/T400 > rtl/t400_core.v

Son 6665 lineas. Los genericos se hornean en la conversion, porque GHDL no
los deja parametrizables en la salida: COP420, divisor CKI de 16 y **MICROBUS
activado**, que es como lo usa el NewBrain.

Dos detalles que costaron encontrar:

- Hay dos ficheros con bloques de depuracion entre `pragma translate_off` que
  referencian un paquete del banco de pruebas del autor. GHDL no sintetiza
  señales dentro de paquetes, asi que el script los quita antes.
- El VHDL original se conserva en `common/T400` por la licencia y como
  referencia, pero **lo que se compila es el Verilog generado**, para que
  Quartus e Icarus vean lo mismo.

## En la maquina: el COP real siempre, con la cinta aparte

No hay opcion en el menu: **el COP de verdad va siempre**, con su ROM, y
lleva el teclado, la pantalla y el reloj. La emulacion completa del COP se
quito; su parte de teclado daba caracteres raros y dos caminos para lo mismo
solo daban fallos.

Lo que se conserva de ella es **la cinta**, como modulo aparte
(`newbrain_cop_hle` en modo solo cinta): carga los `.bas` desde fichero y el
audio con el desmodulador de siempre. El reparto del puerto del COP
(`newbrain_cop_mux.v`) funciona asi:

- normalmente, el puerto y la interrupcion son del COP de verdad;
- cuando el Z80 contesta a una interrupcion con un `CASSCOM` (8x con b3 o
  b1), el modulo de cinta se queda el comando y el puerto hasta que acaba la
  operacion, y al COP de verdad le llega un `NULLCOM` (D0) en su lugar;
- al acabar, el puerto vuelve al COP de verdad.

`tb_newbrain_cinta_mux.v` lo prueba con un COP de verdad de mentira que pide
REGINT: el CASSCOM se lo queda el modulo, al COP le llega D0, los bytes del
fichero llegan al Z80 y al final el puerto vuelve. Con un multiplexor roto a
proposito (dejando pasar el CASSCOM) la prueba falla, como debe.

**Por que la cinta no la lleva el COP de verdad todavia.** Lee la cinta
contando flancos de la entrada en ventanas de tiempo (su registro serie en
modo contador, rutina de `3F8`). En la cosimulacion reconoce la señal pero
no llega a cargar, y grabando, el Z80 acaba en la rutina del puerto serie
V24 con las interrupciones cortadas. Hasta resolver eso, y la duda del reloj
(la cinta apunta a 4 MHz, los 20 ms del libro a 2,565 MHz), la cinta va por
el modulo.

## Estado del COP de verdad

La ROM original del COP arranca la maquina con la ROM del Z80 y entrega
teclas. Comprobado de dos maneras:

- `tools/nbcopreal.py` pone **las dos ROMs de verdad frente a frente**: la del
  Z80 en su modelo de siempre y la del COP en `tools/nbcop420.py`, un COP420
  portado del nucleo de MAME. Arranca a "NEWBRAIN BASIC / READY" y lo que se
  teclea sale en pantalla.
- `tb_newbrain_cop_real.v` ejecuta la ROM del COP en el `t400` del RTL
  contra un Z80 de mentira que hace lo mismo que la ROM de verdad (medido con
  la cosimulacion). Interrumpe cada 20,0 ms, recorre las 16 filas del
  teclado y con la 'A' pulsada entrega el vector 30 y el codigo 2E.

Ademas, con una tecla pulsada, el `t400` y el nucleo de MAME hacen **las
mismas 1284 escrituras en la RAM del COP**, en el mismo orden.

## Lo que estaba mal

Cinco cosas, todas en el envoltorio, no en el `t400`:

1. **_COPINT invertida.** En MICROBUS el COP pide atencion poniendo G0 a
   uno y la escritura del Z80 lo devuelve a cero. MAME: `copint = !G0`. El
   Z80 veia una interrupcion permanente: la pantalla negra.
2. **El teclado no llegaba donde el COP lo busca.** Faltaba el biestable
   CD4076 (con K6 bajo sus salidas leen todo unos), los bits estaban
   cambiados de sitio y el contador avanzaba en el flanco equivocado. Ahora:
   G1 = Q1, G2 = Q0, G3 = Q3, IN0 = Q2, carga con K6 subiendo, avance con
   K6 bajando.
3. **La RAM de datos era asincrona.** El `t400` espera la `generic_ram_ena`
   de su sistema original: sincrona y actualizada solo en los ciclos de
   `ck_en`. Con la asincrona, `LDD 1,15` leia otra posicion y el COP nunca
   mandaba una tecla.
4. **TDI sin cinta.** Mientras el COP saca por la linea serie los datos del
   display, por SI le entra la cinta (`TDI = TPIN xor TDO`), y eso acaba en
   la RAM que usa el teclado. Sin motor en marcha depende de como repose la
   entrada de audio de cada placa: con TDI a uno el COP deja de ver teclas.
   Ahora TDI solo pasa con algun motor en marcha.
5. **El reloj.** El COP iba a 4 MHz, como en MAME, y salian 78
   interrupciones por segundo. The NewBrain Dissected dice que el contador
   que avanza con ellas lo hace 50 veces por segundo, y entre interrupcion e
   interrupcion el programa del COP gasta 3206 ciclos. Eso da **2,565 MHz**
   en CKI. Se genera con un acumulador de fase.

Y dos cosas de simulacion, que en la FPGA no pasan pero escondian lo demas:
la RAM y el biestable del teclado arrancaban con X.

## Como se encontro

MAME marca la NewBrain como `MACHINE_NOT_WORKING` y el emulador de cdesp no
ejecuta la ROM del COP, asi que ninguno servia de referencia directa. Lo que
sirvio:

- un **desensamblador fiel** (`tools/nbcop420dasm.py`, a partir del de MAME).
  El que habia, `copdasm.py`, confunde `JSRP` con `JP` y no deja seguir el
  programa;
- un **COP420 en Python** portado de MAME, para cosimular con la ROM del Z80
  y ver que le manda de verdad al COP (el `DISPCOM` con los 18 bytes del
  display va en la interrupcion SIGUIENTE al reconocimiento, no detras);
- y comparar **escritura a escritura** la RAM del COP entre el `t400` y ese
  nucleo, con las mismas entradas: la primera diferencia señala el fallo.

## La cinta del COP de verdad: lo averiguado

Sigue sin cargar por el COP de verdad (por eso la lleva el modulo aparte),
pero esto ya esta medido:

- **Como lee:** pone su registro serie en modo contador (`LEI 1`): SIO
  baja uno por cada flanco de bajada de SI que dure al menos dos ciclos en
  cada nivel (patron 1100, como en MAME). La rutina de `3F8` lee y pone a
  cero ese contador con `XAS` en ventanas de tiempo: distingue los bits por
  **frecuencia**, contando flancos. Por eso la polaridad da igual. Mi puerto
  del COP a Python no tenia ese modo; ya lo tiene (`nbcop420.py`).
- **Como graba** (medido con `SAVE` en la cosimulacion): un tono guia de
  mas de 5 s con el patron largo-corto-corto-largo de 138/70 ciclos, luego
  un bit de inicio de cuatro cortos de 52 ciclos, y los datos con cortos de
  52 y largos de 104-112. La misma estructura que `beepgenerator`.
- **El reloj:** a 4 MHz los datos dan 208/416-448 us, casi lo mismo que
  `beepgenerator` (204/408), que carga en maquinas reales; a los 2,565 MHz
  que dan las 50 interrupciones por segundo del libro saldrian 324/673 us.
  Los dos datos no cuadran entre si; el RTL sigue a 2,565 MHz (parametro
  `COP_HZ` de `newbrain_cop_real`), que solo afecta al teclado y al reloj
  mientras la cinta vaya por el modulo.
- **Lo que no cuadra todavia:** ni el COP en Python ni el t400 reconocen el
  WAV de `beepgenerator` a ningun reloj (a 5,6 MHz entrega un byte y luego
  error 130), y grabando, el Z80 acaba en la rutina del puerto serie V24
  (`E504`-`E519` de la EF) con las interrupciones cortadas. Al grabar hay
  que darle al COP TDI = TDO (la entrada de cinta sigue a la salida, como
  en MAME), o aborta antes.
- **Modelo de magnetofono** para la cosimulacion: `tools` (cinta que solo
  avanza con G1 o G3 a cero, entra por TDI = TPIN xor TDO). Y
  `test/tb_newbrain_cop_cinta.v`: el t400 con la ROM leyendo una señal por
  `tape_in`, parametrizado en reloj y polaridad.
- **ModNewbrain (cdesp) no sirve de referencia:** su FPGA sustituye al COP
  con una logica minima que ignora las ordenes de cinta y carga de una SD
  con una ROM propia en 8000.

## Lo que queda

- **Cinta con el COP real.** El COP graba con semiperiodos de unos 437 y
  855 us a 2,565 MHz. No se ha probado aun una carga de principio a fin con
  el COP real.
- **El modelo A** tiene otro teclado (dos CD4051 en vez del CD4076). Esto es
  el del AD, que es el que modela MAME.

## Lo que desbloquea

La **modulacion de cinta**. Con el COP real ejecutando su propia ROM, la
codificacion de bits la hace el microcontrolador exactamente igual que en la
maquina original, y deja de hacer falta adivinar el formato. Es la unica via
que convierte la entrada de audio en algo fiable.
