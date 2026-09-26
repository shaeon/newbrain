# Toda la memoria en la SDRAM

## Por que

El primer intento pedia 84 bloques M9K de los 66 que tiene el chip. Sacar la
ROM dejo 60, que cabian pero con seis de margen. La paginacion del modulo de
expansion cambia el planteamiento entero: **2 MB de espacio fisico no caben
en block RAM de ninguna manera**, asi que la RAM del sistema se va con la ROM.

Reparto de M9K despues del cambio:

| Bloque | M9K |
|--------|-----|
| Generador de caracteres | 8 |
| Buffer de linea del video | 1 |
| Scandoubler | 12 |
| OSD | 8 |
| **Total** | **29 de 66** |

Se pasa de ir al 91% a ir al 44%, con sitio de sobra para el core COP400 de la
fase 5 y para lo que venga.

## El controlador, ahora con dos puertos

Arbitraje por prioridad fija:

    refresco  >  video  >  CPU

El video tiene plazo duro y la CPU no: cuando a la CPU le toca esperar se le
quitan los clock enables y ya esta. El refresco va primero porque cuesta un 3%
del ancho de banda y no tenerlo pierde datos.

## El buffer de linea

Aqui esta la decision de diseño que evita el problema de verdad.

Leer un byte por celda de caracter no se sostiene: en 80 columnas una celda
son 16 ciclos de sistema, y un acceso a SDRAM cuesta unos 7. Con la CPU y el
refresco compitiendo por el mismo camino, el peor caso se sale del plazo y se
pierden caracteres.

En vez de eso el video **llena un buffer de linea en rafaga durante el borrado
horizontal** y el barrido activo lee de ese buffer, que es block RAM y
responde en un ciclo. Las cuentas salen holgadas:

| | |
|---|---|
| Palabras por linea (80 columnas) | 40 |
| Coste por acceso | ~7 ciclos |
| Total de la rafaga | ~280 ciclos |
| Duracion del borrado horizontal | 768 ciclos |

Quedan casi 500 ciclos para la CPU y el refresco.

Y tiene una gracia añadida: es justo lo que hacia la maquina real, que le
robaba ciclos de DRAM a la CPU aprovechando el slot de refresco para pintar.
El banco de pruebas del video se ejecuta contra un modelo de SDRAM con nueve
ciclos de latencia, para que la holgura quede comprobada y no supuesta.

## Mapa del espacio fisico

    000000-005FFF   ROM del sistema, 24K (AB, CD, EF)
    006000-007FFF   ROM de la controladora de disco, 8K (d413)
    200000-3FFFFF   RAM, hasta 2 MB

De los 8 MB de la placa se usan poco mas de 2.

## Tamaño de RAM

Opcion del OSD con cuatro valores. Mas de 32K solo existe con el modulo de
expansion, asi que la opcion lo implica en vez de pedir otra entrada de menu.

| Opcion | Espacio fisico | Que es |
|--------|----------------|--------|
| 32K | `00000-07FFF` | la maquina pelada |
| 64K | `00000-0FFFF` | el minimo para CP/M |
| 512K | `00000-7FFFF` | 64 paginas |
| 2MB | `00000-1FFFFF` | 256 paginas, el tope del registro de pagina de 8 bits |

Por encima de lo instalado las lecturas devuelven `FF` y las escrituras se
pierden, que es lo que hace una maquina a la que le falta memoria.

## Una trampa que costo una sintesis

El barrido va en el dominio de `ce_pix` y la rafaga de relleno en el de
`clk`, y en la primera version los dos escribian `fstate` y `fidx`. Icarus lo
simula sin protestar porque resuelve el ultimo que escribe; Quartus lo
rechaza, con razon, porque no hay forma de construir eso en silicio.

La solucion es que el barrido no toque esos registros: conmuta un bit
(`fill_tog`) y la maquina de estados arranca al ver que ha cambiado. Cada
registro queda con un unico excitador.

Para que no vuelva a pasar hay `tools/nbdrivers.py`, que revisa todo el RTL
buscando este patron y se ejecuta con `make`.

## Dos fallos que dejaban la pantalla negra

**El reset de la maquina llegaba al controlador de SDRAM.** El reset del core
incluye `ioctl_download`, que es justo lo que esta activo mientras data_io
escribe la ROM. Con el controlador en reset durante toda la carga, la ROM no
llegaba nunca a memoria: la maquina arrancaba leyendo ceros y la pantalla
salia negra sin ninguna pista.

Ahora son dos resets distintos: la maquina se reinicia al cargar, la memoria
solo cuando el PLL pierde el enganche. El camino de carga tambien vive fuera
del reset de la maquina, porque por definicion se usa mientras esta activo.

`test/tb_newbrain_load.v` cubre esto de extremo a extremo: escribe bytes con
la maquina en reset y comprueba que aparecen en el modelo de SDRAM. Verificado
en los dos sentidos, con el cableado viejo falla y con el arreglo pasa.

**El reloj de la SDRAM se generaba invirtiendo `clk_sys` por la trama.** Eso
añade un retardo que no controla nadie y que cambia entre sintesis: es la
forma tipica de que la SDRAM funcione a ratos, o no funcione. Ahora sale de
una salida propia del PLL desfasada un cuarto de periodo (-7800 ps a 32 MHz),
que es lo que hacen los demas cores de calypso-ports.

Con una vuelta de tuerca: **es `c0` el que va a la SDRAM y `c1` el del
sistema**, no al reves. El `.sdc` compartido declara los retardos de la
memoria contra `clk[0]` usando `SDRAM_CLK` como pata de referencia, asi que
si `SDRAM_CLK` no sale de `clk[0]` TimeQuest avisa

    Warning (332079): Reference pin SDRAM_CLK is invalid

y, lo que importa, **las rutas de memoria se quedan sin restringir de
verdad**: el fitter las coloca donde le parece. El aviso no era cosmetico.

## Dos fallos de protocolo que tuvieron la maquina colgada

Los dos venian de dar por buena la geometria del chip sin comprobarla.

**La precarga automatica nunca se emitia.** La columna se enviaba como
`{4'b0000, 1'b1, col}`, que en un bus de 13 bits deja el uno en **A8**, no en
A10. Sin precarga la fila se queda abierta, y el siguiente ACTIVE a otra fila
viola el protocolo. Funcionaba mientras todo caia en la misma fila -- el
arranque de la ROM -- y se rompia en cuanto el test de RAM recorria memoria.

**La geometria era de un chip de 128 Mbit.** El de la Calypso es de 64:

    4096 filas x 256 columnas x 4 bancos x 16 bits = 64 Mbit = 8 MB

o sea filas de **12 bits** y banco en `word[21:20]`, con 2 MB por banco. Con
filas de 13 bits, la RAM caia en la fila 4096, que no existe y se pliega sobre
la 0: **la RAM machacaba la ROM**. La RAM pasa ahora al banco 2, en `400000`.

### Por que no lo vio la simulacion

El modelo de SDRAM era demasiado complaciente: usaba solo 8 bits de fila, asi
que el plegado no se notaba, y no comprobaba el protocolo. Ahora:

- la direccion la forman banco y fila **completos**, sin plegar nada;
- un READ o WRITE sin ACTIVE previo es error;
- un ACTIVE sobre un banco ya abierto, sin precarga de por medio, tambien:
  eso es lo que delata que falta la precarga automatica;
- una fila por encima de 4096 es error.

Y el banco de pruebas escribe y lee cruzando filas y los cuatro bancos.
Verificado en los dos sentidos: con la precarga en A8 el modelo protesta, y
con la geometria de 128 Mbit falla con el mismo sintoma que se veia en la
placa, *la ROM en 000000 quedo en 77: algo la piso*.

## Cabos sueltos

**El reparto de paginas a ROM.** Con la paginacion activa, las paginas 120 a
123 se tratan como las ROMs internas (AB, CD, EF y la de disco). Esa
numeracion sale del mapa del emulador de cdesp, **no de documentacion de
Grundy**. Funciona en su emulador, pero conviene contrastarlo.

**Escrituras sincronas.** La CPU espera el acuse de la escritura en vez de
darla por hecha. Se podria dejar en el aire y ahorrar unos ciclos, pero
complica el control y de momento no hace falta.

**El reloj de la SDRAM** ya no sale del PLL con un desfase: es `clk_sys`
invertido por un registro DDR del pin, ver la ultima seccion. El margen de
Quartus es amplio, pero el real solo lo confirma el hardware.

## Tiempos de lectura y desfase del reloj de la SDRAM

`SDRAM_CLK` sale de `c0`, adelantado respecto al sistema (`c1`). La orden
READ sale en un flanco del sistema; la SDRAM la toma en su siguiente flanco,
y con latencia CAS 2 saca el dato dos flancos suyos despues. El controlador
lo recoge en el paso 2 de `S_RD`, que es el primer flanco del sistema tras
ese flanco de la SDRAM. Asi que **la ventana de lectura es exactamente el
adelanto** de `c0`, y en ella tienen que caber el tiempo de acceso de la
SDRAM (6,4 ns en el `.sdc`) y el camino hasta el registro en la FPGA.

Con -7800 ps, la Poseidon no cumplia: -3,7 ns en las 32 rutas de
`SDRAM_DQ` a `b_dout` y `a_dout` (modelo lento a 85 grados). Ahi
`SDRAM_CLK` va por rutado no dedicado (aviso 15064) y llega ~2,4 ns tarde.
En la Poseidon el adelanto pasa a **-12500 ps**: la ventana gana 4,7 ns y
las ordenes siguen teniendo ~18 ns para llegar a la SDRAM, con mas margen
de hold. Calypso y SiDi siguen en -7800 mientras cumplan.

Para ver estas rutas en Quartus (Timing Analyzer, tras Update Timing
Netlist):

    report_timing -setup -npaths 40 -detail summary -to_clock {pll|altpll_component|auto_generated|pll1|clk[1]} -file fallos_clk1.txt

## Reloj de la SDRAM por un registro DDR del pin

Aun con -7800 ps la Calypso tampoco cumplia: -4,05 ns en las mismas rutas.
El reloj de `c0` llega a la pata por un camino distinto del de los datos y
las ordenes, y ese desfase (~3 ns) se comia la ventana. Guardar el dato en
el registro del pin (`dq_in`, con `FAST_INPUT_REGISTER`, que antes no se
podia aplicar porque habia un multiplexor delante) solo lo dejaba en
-3,02 ns.

Ahora `SDRAM_CLK` sale de un `altddio_out` (`sdramclk_ddr` en
`newbrain_top.sv`) con `datain_h = 0` y `datain_l = 1` sobre `clk_sys`: es el
reloj del sistema invertido, adelantado medio periodo (15,6 ns), y sale por
un registro de pin como las ordenes y los datos, con retardos emparejados.
Las ordenes siguen llegando a la SDRAM en el mismo ciclo, asi que la
secuencia del controlador no cambia; solo el acuse de lectura sale un ciclo
mas tarde, porque el dato pasa por `dq_in`. `c0` queda sin usar en todas las
placas.

En el `.sdc`, `sdram_clk` es un reloj generado de `clk[1]`, invertido, en la
pata `SDRAM_CLK`, y los retardos de la memoria van contra el. Calypso, modelo
lento a 85 grados:

| Ruta | Antes | Ahora |
|------|-------|-------|
| `SDRAM_DQ` -> `dq_in`, setup | -4,05 ns | +4,77 ns |
| `SDRAM_DQ` -> `dq_in`, hold | | +22,8 ns |
| ordenes y datos -> SDRAM, setup | +19,98 ns | +13,5 ns |
| ordenes y datos -> SDRAM, hold | | +14,7 ns |

