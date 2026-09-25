# Disquetera

La controladora del NewBrain es otro ordenador, y en el core se hace igual:
un segundo Z80 ejecuta **la ROM original de Grundy** y habla con un uPD765
que lee y escribe imagenes EDSK. No hay emulacion del protocolo a mano: el
codigo de 1983 hace su trabajo.

## La tarjeta

| Pieza | Donde |
|-------|-------|
| Z80 a 4 MHz | en la tarjeta |
| ROM `d417` | espacio del Z80 de la tarjeta |
| ROM `d413` | espacio del **NewBrain**, en 8000 |
| uPD765 a 8 MHz | en la tarjeta |
| 1K de RAM estatica | compartida, en 9C00-9FFF del NewBrain |

La `d413` ocupa 8000-9BFF y los ultimos 1K de esa ventana son la RAM
compartida. **La controladora no tiene RAM propia**: ni siquiera usa pila,
por eso su ROM esta escrita a base de `JP (IY)` en vez de `CALL`.

## Revisiones

De los PDF de `NB-EPROM-ROM`:

| ROM | CRC32 | Etiqueta |
|-----|-------|----------|
| `d413-2` | `29CAB1E7` | D413, ISSUE 2 — **la buena** |
| `d413-2` | `097591F1` | D413, ISSUE 2 — volcado malo, ver abajo |
| `d417-1` | `40FAD31C` | D417, ISSUE 1 |
| `d417-2` | `E8BDA8B9` | D417, ISSUE 2 |

**Los puertos NO cambian entre revisiones.** Se comprobo recorriendo las dos
`d417` instruccion a instruccion: las dos usan exactamente los mismos
puertos (00/01, 20 y 40) con la misma cuenta de accesos. Lo que cambia son
692 bytes de codigo; la issue 1 acaba en `03E2` y la issue 2 en `0420`. Las
dos arrancan CP/M en la cosimulacion. El core no necesita saber cual es: se
carga una u otra y ya.

Del lado del NewBrain solo hay una revision util. El `097591F1` que trae el
romset de MAME **no contiene codigo**: es una rampa de 16 bits
(`palabra[n] = 0x1A29 + n`), el patron de un volcado en el que las lineas de
datos leen la direccion. MAME nunca lo ejecuta (`// TODO: map d413 ROM to
computer space`), por eso nadie se habia dado cuenta.

## Como se hablan

**Del lado del NewBrain**, un registro de control en el puerto `FF` con A9 a
uno (`OUT (C),A` con B = 02):

| Bit | |
|-----|---|
| 0 | PAGING |
| 2 | MA16 |
| 3 | MPM |
| 5 | _FDC RESET |
| 7 | FDC ATT |

**Del lado de la controladora**, tres puertos con la mascara `71h` (A4 es
espejo, A0 elige estado o datos):

| Puerto | |
|--------|---|
| 00 / 01 | uPD765, estado y datos |
| 20 | escritura: b0 motor, b1 reset del 765, b2 TC, b5 PA15 |
| 40 | lectura: b7 FDC ATT, b6 PAGING, b5 INT del 765 |

**Y sobre todo, la ventana de memoria.** Las direcciones 8000-FFFF del Z80
de la controladora no son suyas: salen al bus del NewBrain, con
`direccion = {PA15, A14..A0}`. Asi es como la `d417` lee en `9C00` el
puntero a su bloque de parametros y escribe el sector en el buffer. Sin
paginacion lo unico que responde ahi es la RAM compartida, y en la
cosimulacion con CP/M **no hubo un solo acceso fuera de ella**.

El bloque de parametros vive en `9FCD`:

| Offset | Campo | |
|--------|-------|---|
| +00 | `CBUFFER` | direccion del buffer, 2 bytes |
| +04 | `CLSTTRA` | ultima pista |
| +06 | `CDRIVE` | unidad |
| +07 | `CGAP` | |
| +08 | `CSECSIZ` | 0 = 512, 1 = 1024 |
| +0A | `CSEEKRA` | |
| +0B | `CSECTOR` | |
| +0C | `CTRACK` | 2 bytes |
| +0E | `CSIDE` | |
| +0F | `CRESULT` | FF preparada, 0 bien, 1 error de datos |
| +10 | `CCOMMAN` | 0 reset, 1 reset de unidades, 5 escribir, 6 leer, 13 formatear, 17 verificar |

El apreton de manos, tal como lo hacen las dos ROMs: el NewBrain pone
`CRESULT` a cero y levanta ATT; la controladora lee el puntero de `9C00`,
deja `CRESULT = FF` y espera a que ATT baje; el NewBrain la baja y la
controladora ejecuta y deja el resultado. La `d417` traduce el comando a
comandos del 765 (SPECIFY, RECALIBRATE, SEEK, READ DATA, WRITE DATA) con
`R = CSECTOR + 1`, `N = 2` y `EOT = R`, y mueve los datos con `INI`/`OUTI`
sondeando el registro de estado, sin DMA.

## El uPD765

`rtl/u765/u765.sv`, de gyurco (Amstrad_MiST), que lee EDSK directamente de
la SD. **Un solo cambio**: la salida `int_o`, la linea INT del 765. La
`d417` la espera en el bit 5 de su puerto 40 despues de cada SEEK y
RECALIBRATE, antes de pedir SENSE INTERRUPT STATUS; el Amstrad no la usa y
el original no la sacaba. Si se actualiza el fichero, hay que volver a
meterla.

El 765 no recibe TC. No hace falta: la `d417` pone `EOT = R`, asi que el
comando acaba solo al terminar el sector, y ademas enmascara los bits de
terminacion anormal y de fin de cilindro del resultado (`AND 88h` sobre ST0
y `AND 37h` sobre ST1). Estaba escrita contando con ello.

## Comprobacion

`tools/nbfdc.py` ejecuta **las dos ROMs de verdad**, cada una en su Z80, con
un uPD765 en Python leyendo una imagen EDSK. Con los discos de CP/M:

    A0>dir
    CONFIGUR.COM | DCOPY .COM | DISKSTAT.COM | ED .COM
    EXIT .COM | FASTEXIT.COM | FORMAT .COM | PIP .COM
    ...
    A0>stat
    A: R/W, Space: 712k
    A0>save 1 prueba.com
    A0>dir prueba.com
    PRUEBA .COM

Arranca CP/M, lista, ejecuta programas del disco y escribe. Probado con las
dos revisiones de la `d417` y con las tres geometrias (200K una cara, 400K y
800K dos caras), sin un solo sector no encontrado. Se lanza con
`make romdisco` en `test/`.

`tb_newbrain_fdc.v` comprueba el cableado del RTL contra un Z80 de guion:
ROM y su espejo, ventana con PA15 en los dos sentidos, los tres puertos con
sus espejos, el registro de control y el reset.

## Imagenes

**EDSK** (`.dsk`), que es lo que sabe leer el u765. Se montan en "Disco A:" y
"Disco B:" del OSD y las escrituras van a la tarjeta. Las que se han
probado llevan 10 sectores de 512 por pista, identificadores 1 a 10 con
intercalado 2:1 y `N = 2`.

## Solo con 32K

La disquetera exige **RAM: 32K** en el OSD. Con mas RAM el core da por
supuesto que hay modulo de expansion, y con el la controladora funciona de
otra manera (ver mas abajo), asi que se desactiva entera: ni controladora ni
ROM en 8000.

Esto costo una pantalla negra. La ROM se mapeaba con la opcion del OSD sola,
mientras que la controladora y la RAM compartida miraban ademas si habia
expansion. Con mas de 32K quedaba la ROM de disco en 8000 **sin RAM
compartida**: los ultimos 1K eran ROM de solo lectura, la d413 escribia su
vector al aire y saltaba a el, y la maquina se colgaba antes de encender el
video. Reproducido en el simulador y corregido: las dos cosas salen ahora de
la misma señal.

## Con el modulo de expansion

Funciona en la cosimulacion (`tools/nbpagdisco.py`, sistema paginado +
controladora de verdad, ROMs originales): desde el menu del sistema
paginado, dos flechas abajo y nueva linea, sale "NewBrain CP/M Version 2.2"
en 80 columnas y el `A0>`, con 512K y 768K (con 96K tambien arranca y lee el
directorio; el volcado de pantalla de la herramienta no le sigue bien la
pista en ese caso). Usar `NB_ISSUE3.ROM`, el juego que usa cdesp con la
expansion; con la series2 el cursor del menu se comporta de otra manera.

Lo que cambia respecto al sistema sin expansion, y esta en el RTL:

- La ROM de disco del NewBrain va en la **pagina 119**; la 123 es del
  sistema paginado. El menu la encuentra y ofrece "CP/M 2.2".
- No hay RAM compartida de 1K (en 8000-9FFF esta el sistema paginado). La
  d417 lee el puntero a su bloque en `0079` del NewBrain (`8079` con PA15 a
  cero) y el bloque esta en `FFCD`, en la pagina que haya en la ranura de
  `E000`. Es decir, la controladora ve la memoria **a traves de la
  paginacion**, igual que la CPU: `newbrain_fdc` saca la peticion por su
  ventana (`win_*`), `newbrain_pager` tiene un segundo puerto de consulta
  para ella (con su propio A16, el bit MA16 de su registro de control), un
  segundo `newbrain_mem` traduce la direccion, y la controladora es el
  cuarto cliente del arbitro de la SDRAM. Su Z80 se queda parado hasta que
  llega la respuesta, como la CPU principal.
- El bit PAGING del registro de control (b0 de lo que el NewBrain escribe
  en el puerto 255 con A9) le llega a la d417 por su puerto 40 y es lo que
  la manda por la ventana en vez de por la RAM compartida.

Como lo reparte el sistema paginado (manual de expansion, notas tecnicas
105 y 106): pagina 96 de sistema, regiones a partir de la 97, y las paginas
de video son las internas mas altas (104-107). CP/M pide 8 paginas con
USERPAGE (RST 20 4B) y REQUESTPAGE (46) hace sitio desplazando la region
del MMS hacia arriba. Con 96K quedan libres justo las 8 que hacen falta.

Desde el BASIC paginado se sale a CP/M con `EXIT`, no con `cpm`.

Pruebas: `tb_newbrain_fdc.v` recorre la ventana paginada con una memoria
del NewBrain de mentira (puntero por 8079 con PA15 a cero, bloque en FFCD
con PA15 a uno, MA16 segun el registro de control), y
`tb_newbrain_cpumem.v` fuerza accesos por la ventana en la maquina entera,
por el arbitro y la SDRAM (ROM, RAM y bus abierto).

## Lo que falta

**Sistema paginado.** Con el modulo de expansion la `d417` busca el puntero
de su bloque en `8079`, o sea en RAM del NewBrain, y ahi la ventana tendria
que llegar a la SDRAM. Hoy el core solo responde a la RAM compartida y la
disquetera queda deshabilitada si hay EIM.

**Formatear.** El u765 no formatea de verdad (lo dice su propio TODO), asi
que `FORMAT.COM` no escribira pistas nuevas.

**Doble paso.** Si se configura un disco de 40 pistas en una unidad de 80,
la `d417` dobla la pista al buscar y el 765 acabaria en una pista de la
imagen que no es. Con las imagenes de 40 pistas y la configuracion que
traen no aparece el problema, pero conviene saberlo.

## Imagenes de disco

Las herramientas para fabricarlas (Teledisk, directorios del PC, volcados
raw) y la descripcion del formato fisico y del bloque de especificacion de
64 bytes de la pista 0 estan en `doc/15-herramientas-disco.md`.

Comprobado de punta a punta: un disco de 200K hecho con `dir2dsk.py`
(pistas de sistema copiadas del original y dos ficheros) arranca CP/M en la
cosimulacion y `DIR` lista los dos (`make disco` en `test/`).

Notas de ese documento que afectan al core:

- `u765.sv` solo lleva dos unidades (`ready[1:0]`, `motor[1:0]`); la
  controladora del NewBrain admite cuatro. Para mas de dos habria que
  ensanchar esas señales.
- `CYCLES` es ciclos por milisegundo del reloj del 765 (el de la placa
  controladora). Aqui el 765 va a 8 MHz y `CYCLES` = 4000, lo mismo que
  mide la d417.
- Con Verilator 5.020 hay que separar la declaracion y la asignacion del
  `reg` de la funcion `SECTOR_SIZE` de `u765.sv`; Quartus e Icarus lo
  compilan tal cual.

## Cambio de disco: hace falta ^C

Si se monta otra imagen en una unidad, CP/M sigue listando el disco
anterior hasta que se pulsa `^C` (arranque en caliente). Comprobado en la
cosimulacion con las ROMs originales: tras el cambio, `DIR` no hace ni una
lectura del disco y **ni siquiera manda ordenes a la controladora**; el
directorio lo guarda la BIOS de CP/M en la memoria del NewBrain. No se
invalida por tiempo (ni con el motor ya parado, 15 s despues). Tras `^C`,
`DIR` lee el disco nuevo y lista sus ficheros.

Es el comportamiento normal de CP/M 2.2 y seria igual en la maquina real
con una disquetera de verdad: tras cambiar un disco hay que pulsar `^C`.
Por eso "a veces se entera": si entre medias se ha leido otra cosa y el
directorio ha salido de la memoria, lo vuelve a leer.

Por el lado del core, `u765.sv` si se entera del montaje: reinicia su cache
de sectores y lee la cabecera de la imagen nueva. La señal de "hay disco"
(`listo`) no cae al montar una imagen encima de otra, como si se cambiara
el disco sin abrir la puerta, pero con esta controladora y esta BIOS no
cambia nada, porque ninguna de las dos lo mira.

Con DISCIO desde BASIC pasa lo mismo; el dispositivo 15 tiene una
transaccion 6 ("Reset disk system") que hace el papel del `^C`.

## Tiempos (32 MHz)

La primera compilacion con la ventana paginada no cumplia tiempos en el reloj
del sistema: -3,8 ns en setup, -78 ns en total (Poseidon, modelo lento). Los
relojes de pixel iban sobrados. Dos rutas nuevas eran demasiado largas para
un ciclo de 31,25 ns:

- **Direccion de la controladora hasta el arbitro de la SDRAM**: su Z80,
  el paginador, el decodificador de memoria y la suma de la base de RAM en
  el mismo ciclo que el arbitro. Y como la controladora va antes que la CPU
  en la prioridad, alargaba tambien la ruta de la CPU. Ahora la traduccion
  se registra (`fdc_addr_r`, `fdc_sd`, `fdc_pide`) y el arbitro solo ve
  señales registradas; `fdc_hecho` evita pedir dos veces el mismo acceso.
- **La espera que para al Z80 de la controladora**: salia de su direccion y
  llegaba al enable de todo el Z80. Ahora va registrada; es seguro porque el
  Z80 solo cambia sus salidas en cen_p o cen_n, a 4 ciclos, y la espera
  llega al siguiente.

Los dos ciclos de mas no se notan: el Z80 de la controladora esta parado
mientras espera.
