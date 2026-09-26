# Video

## Temporizacion

Deducida del cristal de 16 MHz y consistente con los 50 Hz nominales:

| | |
|---|---|
| Reloj de punto | 16 MHz |
| Puntos por linea | 1024 |
| Lineas por trama | 312 |
| Frecuencia horizontal | 15,625 kHz |
| Frecuencia vertical | 50,08 Hz |
| Puntos activos | 640 |
| Lineas activas | 250 |

640 puntos son 80 caracteres de 8, o 40 de 16.

## Direccion de pantalla

La CPU la escribe cada trama. Confirmado en `E1FD` de la ROM EF:

    LD A,C / RLA / LD A,B / RLA   ; A = BC >> 7
    OUT (TVLL),A                  ; puerto 09, bits 15..7
    BIT 6,C / JR Z / OUT (TVLATCH),A   ; puerto 08, bit 6

O sea, la direccion son los bits 15..6 del puntero de trama: **granularidad
de 64 bytes**. La escritura del puerto 09 es ademas la que arranca el
barrido.

## Registro de modo (puerto `0C`)

| Bit | Funcion |
|-----|---------|
| 0 | video inverso global |
| 1 | juego completo: 0 = 128 caracteres + 128 en campo inverso, 1 = 256 |
| 2 | pantalla estrecha: 256/512 puntos en vez de 320/640 |
| 3 | 8 lineas por caracter (30 filas); si 0, 10 lineas (26 filas) |
| 6 | 80 columnas, EL = 128 bytes; si 0, 40 columnas, EL = 64 |

`EL` es el paso en memoria entre filas consecutivas.

## Recorrido

Cada fila de caracteres empieza en `base + fila * EL`. Dentro de la fila:

- un byte `00` deja **en blanco el resto de la fila**;
- `00 00 20 20` al principio de una fila es el **final de la pantalla**: lo
  que queda por debajo va en blanco;
- `00 00 00 00` al principio de una fila es el **comienzo de los graficos**.

Las dos secuencias no son lo mismo, y confundirlas se nota: al arrancar, el
sistema deja `00 00 20 20` detras de las 24 filas de texto, asi que tomarlo
por graficos pintaba una fila de basura abajo del todo.

Con el bit 1 a cero, los caracteres con el bit 7 puesto se dibujan en campo
inverso usando el glifo del codigo sin ese bit.

## Zona grafica: resuelto

La regla no estaba documentada en ningun sitio, y ni el emulador de cdesp ni
su `vga.vhd` sirven de guia porque los dos sacan el ancho y el alto leyendo
estructuras del sistema operativo, cosa que el hardware no puede hacer. Se
midio preguntandoselo a la propia maquina, que sabe donde tiene sus
graficos: `PEN(7)` da la primera direccion, `PEN(8)` la ultima mas uno y
`PEN(9)` el ancho en puntos.

Con la consola abierta como `"l110"` y los graficos como `"w150"`:

| | |
|---|---|
| `PEN(7)` | 2596 |
| `PEN(8)` | 14596 |
| `PEN(9)` | 640 |

12000 bytes para 150 lineas son **80 bytes por linea de barrido**, que es
justo ancho/8. No es `EL`: los graficos van empaquetados, sin los bytes de
sobra que el sistema se reserva en las filas de texto.

| Modo | Puntos | Bytes por linea | Hueco a cada lado |
|------|--------|-----------------|-------------------|
| 80 columnas | 640 | 80 | 0 |
| 80 columnas, estrecha | 512 | 64 | 64 puntos, 8 bytes |
| 40 columnas | 320 | 40 | 0 |
| 40 columnas, estrecha | 256 | 32 | 64 puntos, 4 bytes |

En 40 columnas cada punto se pinta doble, igual que los caracteres, que ahi
miden 16 puntos.

**El bit 0 de cada byte es el punto de la IZQUIERDA**, al reves que en el
generador de caracteres. Pintandolo al reves, los textos que los programas
dibujan sobre los graficos salen en espejo, que es como se encontro.

**Con la pantalla estrecha la imagen va centrada**, con 64 puntos en blanco
a cada lado, y el hueco de la izquierda se salta **una sola vez**: en la
primera linea esos 8 bytes todavia se leen, y a partir de la segunda la fila
ya empieza en el primer byte de la imagen.

Todo esto se midio con un programa que abre `"l100"` y `"n180"` y dibuja una
linea vertical en x=0 y otra en x=511. En memoria, la de x=0 enciende el bit
0 del byte que apunta `PEN(7)`, que cae 8 bytes despues del comienzo de la
fila del terminador, y la de x=511 el bit 7 del byte 63 de la fila anterior.
Las dos marcas se repiten cada 64 bytes.

**Contrastado contra el emulador.** Pintando la memoria de SHADOW con esta
regla y comparandola punto a punto con una captura del emulador de cdesp,
coinciden el **92,6%** de los 512x180 puntos, y el encaje aparece justo en
la posicion medida en la captura (x=66, y=141 de la imagen). Lo que falta se
explica porque el volcado se tomo en un momento distinto del dibujado.

**Los graficos empiezan en la fila del terminador, no en la siguiente.** Lo
dicen las cuentas: en el ejemplo de arriba quedan 9 filas de texto, y
9 x 10 + 160 lineas graficas son exactamente las 250 visibles. No sobra
sitio para una fila de texto de mas. Ademas el hueco entre el terminador y
`PEN(7)` mide 800 bytes = 10 lineas de 80, que son las 10 de margen que deja
el sistema. Los cuatro bytes del terminador son parte de la imagen y valen
cero, asi que no se ven.

**Lo que estaba mal.** Se avanzaba `EL` (128 bytes) por linea de barrido en
vez de 80, con lo que cada linea salia desplazada respecto a la anterior y
la imagen se repetia en diagonal; y los graficos empezaban una fila tarde,
de modo que la primera fila de la imagen se pintaba como caracteres sueltos.
Es lo que se veia con SHADOW y con DEMO21.

**Un tercer fallo, del mismo sitio.** El terminador se buscaba tambien
durante el borrado vertical, cuando el buffer de linea todavia lleva lo
ultimo que se leyo en la trama anterior. Si eran ceros (la zona grafica, o
la maquina recien arrancada) se daba por bueno y la trama entera se pintaba
como graficos. Y como el fallo se realimentaba trama a trama, bastaba con
que colara una vez. Ahora solo se busca dentro de la zona activa.

## Estado de la implementacion

Hecho y verificado en simulacion: 40 y 80 columnas, caracteres de 8 y 10
lineas, campo inverso por caracter, video inverso global, fin de linea, paso
entre filas, deteccion del terminador de texto, zona grafica con su paso y
pantalla estrecha.

### Pendiente o sin confirmar

### Organizacion del generador de caracteres: resuelto

Ya no es una suposicion, esta volcado de una EPROM real. **Ordenado por linea
de barrido**, 256 bytes por fila, 16 filas:

    direccion = fila * 256 + codigo de caracter

Cada glifo ocupa **8 filas**, de la 0 a la 7. Las filas 8 a 15 son un segundo
juego que comparte mayusculas y digitos pero cambia las minusculas; sin
identificar, y el core no lo usa.

### Los descendentes

La celda es de 10 lineas pero el glifo solo tiene 8. **Las dos que faltan son
el descendente, y estan guardadas en las filas 0 y 1**, marcadas con el
**bit 0** puesto. El bit 0 es la columna de separacion entre caracteres, que
ningun glifo usa en esas dos filas: sale gratis como marca.

Los caracteres marcados en la EPROM son exactamente

    , ; _ g j p q y

o sea justo los que bajan de la linea base. No hay ninguno de mas ni de
menos, lo que confirma la interpretacion.

La regla de pintado es por fila y no necesita mirar el glifo entero, que es
lo que la hace implementable en logica discreta:

| Linea de celda | Que se pinta |
|----------------|--------------|
| 0 y 1 | filas 0 y 1, **en blanco si llevan la marca** |
| 2 a 7 | filas 2 a 7 tal cual |
| 8 y 9 | filas 0 y 1 **solo si llevan la marca**, y sin el bit 0 |

Asi la 'A' ocupa las lineas 0 a 7 y la 'p' las lineas 2 a 9, y las dos
comparten linea base en la 7.

El bit 0 si se usa como pixel en las filas 2 a 7 (110 bytes lo llevan), asi
que la mascara solo se aplica a las filas 0 y 1.

**Como se encontro.** Sobre hardware los descendentes salian **encima** del
glifo, porque el core pintaba las filas 0 a 7 tal cual. Volcando la EPROM se
vio que en `p`, `q`, `g` e `y` las filas 0 y 1 eran el rabito, y que todas
ellas llevaban un pixel suelto en la ultima columna que las mayusculas no
tenian. Esa columna era la marca.

**Desfase de inicio.** El emulador empieza a leer en `base + 4` en 80
columnas y `base + 2` en 40. No esta explicado de donde sale. Esta como
parametro (`START_OFS_80` / `START_OFS_40`).

**Pantalla estrecha.** El bit 2 recorta la zona grafica a 512 o 256 puntos.
En texto no recorta nada: el sistema operativo lo enciende al abrir un
stream grafico estrecho y deja las filas de texto con sus 80 o 40
caracteres, asi que recortar tambien el texto seria inventar.

**Robo de ciclos de DRAM.** En la maquina real el generador de imagen roba
ciclos a la CPU aprovechando el slot de refresco (`TVRQP` / `CPRQ` /
`CPROG`). Aqui se usa un segundo puerto de la RAM, que no tiene efectos
observables desde la CPU salvo en el temporizado exacto. Importa para la
cinta: las rutinas `CASSIN` y `CASSOUT` apagan el video antes de mover cada
byte precisamente por eso.

**Fuente de `CLKINT`.** Sigue siendo un contador de 50 Hz independiente.
`newbrain_video` ya saca `vsync_pulse` para colgarlo de la trama, que es casi
con seguridad lo correcto.

## Proporciones: opcion Aspect (Original / Wide)

El reloj de punto de la maquina es de 16 MHz (lleva un cristal de 16 MHz y
el Z80 va a 16/4): 1024 puntos por linea de 64 us, 640 activos, que en 80
columnas ocupan 40 us de los ~52 visibles. Los emuladores (MAME y el de
cdesp) pintan 640x250 sin bordes. Medido a tamaño real en una captura del
emulador de cdesp: 7,85 px por caracter y 20 px por fila, o sea puntos de
1 px de ancho y lineas de 2 px de alto (proporcion 2,04). En una foto del
core, 9,6 px por caracter y 29 px por fila (2,42): cada fila un 19 % mas
alta respecto al ancho.

La opcion **Aspect** del OSD elige el reloj de punto:

- **Original:** 16 MHz, 1024 puntos por linea, como la maquina.
- **Wide:** 13,5 MHz, 864 puntos por linea (los mismos 64 us; es el reloj
  del video digital PAL, BT.601). Los 640 puntos ocupan 47,4 us y la
  proporcion pasa de 2,42 a 2,42 x 13,5/16 = 2,04, la del emulador. La
  zona activa se centra en el mismo instante de la linea (hsync 64 puntos,
  comienzo en 144).

Como 13,5 MHz no sale de 32 con un divisor entero, el video tiene su propio
reloj:

- El PLL de cada placa da dos salidas nuevas: **c2 a 27 MHz** y **c3 a 32
  MHz**. `newbrain_clkmux` elige una u otra sin glitches (cada reloj se
  habilita solo con el otro ya deshabilitado, y en su flanco de bajada) y
  el resultado es `clk_pix`; el punto es `clk_pix / 2`.
- `newbrain_video` queda partido en dos dominios: el **relleno** del buffer
  de linea va con el sistema (`clk`), contra la SDRAM, como antes; el
  **barrido**, la lectura del buffer y la salida, con `clk_pix`. Se hablan
  por el conmutador `fill_tog` (sincronizado en el sistema, que retiene la
  base y el numero de palabras al verlo) y por el buffer de linea, que es
  una memoria de doble reloj. `tvtl`, `tv_addr`, `tv_enable`, el reset y
  la opcion pasan por dos biestables.
- El generador de caracteres se escribe con el sistema (carga de la ROM) y
  se lee con `clk_pix`. `mist_video` y el scandoubler van con `clk_pix`.
- Tiempo: rellenar una linea de 80 columnas tarda unos 9 us; en Wide hay
  casi 16 us entre el final de una linea activa y el comienzo de la
  siguiente.
- En el `.sdc` de cada placa: sistema (c0, c1), c2 y c3 son tres grupos
  asincronos.

Pruebas: `tb_newbrain_video.v` se pasa dos veces, en Original (los dos
relojes iguales) y en Wide (pixel a 32/27 del sistema, asincronos): todas
las comprobaciones de contenido (glifos, descendentes, terminadores,
graficos) salen iguales y la linea dura lo mismo en los dos modos.
`tb_newbrain_clkmux.v` hace 20 cambios de reloj y comprueba que no sale
ningun pulso corto.

`tb_newbrain_video_sync.v` (`make videosync`, con Verilator) mide la salida
de 15 kHz: el generador mas `mist_video` con el scandoubler desactivado, en
los dos modos y con varios ajustes de centrado. Comprueba duracion de linea
y de hsync, 312 lineas, vsync de 3 lineas alineada con hsync, blanqueo,
640x250 visibles, el sincronismo compuesto (308 pulsos de hsync y 3 de vsync
por trama) y que la primera linea visible sea la linea 0 de la fila 0. Asi
aparecio que el ajuste V centre movia la zona visible pero no el recorrido:
las filas avanzaban desde `V_START` y no desde el comienzo ajustado, y cada
fila salia cortada o con su primera linea repetida.

Al cambiar la opcion se pierde una trama como mucho, y el monitor puede
tardar un momento en reengancharse.

## Sincronismo compuesto a 15 kHz

El core da la hsync y la vsync separadas. Cuando el OSD pide 15 kHz con
sincronismo compuesto (scandoubler desactivado y sin `no_csync`), o YPbPr,
`mist_video` lo forma como `~(hs ^ vs)` y lo saca por `VGA_HS`.

Con la hsync normal, ese XOR invierte el pulso durante las 3 lineas de
vsync: el flanco de bajada de esas lineas llega 4,75 us tarde (al final del
pulso) y el de la linea 3 se pierde dentro del pulso ancho. Salen **311
flancos por trama** en vez de 312, y un monitor que cuenta flancos marca
15,64 kHz / 311 = **50,29 Hz** en vez de 50,08, y recibe un tiron de fase en
cada trama.

La maquina real hacia lo mismo (un 74LS86 con `HSYNC XOR VSYNC`, sin
pulsos de igualacion), pero iba a una tele por video compuesto, que no se
fija en eso.

Ahora `newbrain_video` saca tambien `hsync_cs`: igual que `hsync` salvo en
las lineas de vsync, donde el pulso va al **final** de la linea. El XOR de
`mist_video` da entonces los pulsos anchos de PAL, con la muesca al final,
y un flanco de bajada al principio de cada una de las 312 lineas. El top se
la pasa a `mist_video` solo cuando este va a formar el compuesto; con H y V
separadas, y siempre a 31 kHz (el scandoubler necesita la hsync de verdad),
va la hsync normal. Como solo cambia en lineas en blanco, la imagen no se
mueve.

`tb_newbrain_video_sync.v` lo comprueba: 312 flancos de bajada por trama,
todos a una linea exacta del anterior, 309 pulsos de hsync y 3 anchos.

