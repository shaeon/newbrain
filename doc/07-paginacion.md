# Paginacion del modulo de expansion

**Fuente: Apendice F del Manual Tecnico de Software de Grundy, "NewBrain
Input/Output Port Map".** Esto ya no es deduccion: son los registros tal y
como los documento el fabricante. Hace innecesario desensamblar la ROM del
sistema paginado.

## Notas generales del apendice

1. Sin modulo de expansion el NewBrain decodifica **solo A0-A4**, asi que
   cada puerto se repite ocho veces en el rango 0-255.
2. **Con el modulo de expansion el decodificado pasa a A0-A7** y desaparece
   la repeticion.
3. Grundy se comprometio a no usar los puertos 32 a 63.
4. Algunos puertos se decodifican ademas con A8-A15.

Modulos: `P` procesador A/AD, `EI` expansion, `DC` controladora de disco,
`NC` controladora de red, `API` interfaz de periferico autonomo, `ME`
expansion de memoria.

## Lo que hace de verdad: medido con las ROMs originales

Lo de abajo del Apendice F era una lectura nuestra, y en dos cosas no
cuadraba con lo que hace la ROM del sistema paginado (`16#8#83.POS`). Se
comprobo arrancandola en `tools/nbpag.py`, un modelo en Python con el mismo
decodificado que el RTL, y contrastando con el emulador de cdesp, que la
arranca.

**La ROM solo hace cuatro escrituras** para ponerse en marcha:

    OUT 07   <- B0     ENREG
    OUT 8802 <- 7B     ranura de 8000, juego principal: pagina 123 (ella misma)
    OUT 5802 <- 7B     ranura de 4000, juego alternativo: pagina 123
    OUT FFFF <- 09     paginacion encendida, juego principal, modo normal

De ahi salen tres reglas:

1. **La pagina es el dato tal cual, 7 bits.** `7B` es 123 en decimal. No va
   invertida ni lleva A11, como deciamos: con el valor invertido la ROM se
   paginaba a si misma fuera y la maquina se caia. cdesp lo hace igual
   (`page := Value and $7F`).
2. **Los registros arrancan con el mapa natural.** La ROM no toca las demas
   ranuras y da por hecho que ya tienen lo que habia sin paginar.
3. **El juego alternativo arranca vacio**: lee FF hasta que se escribe.

**La numeracion va al reves** de lo que uno supondria:

| Ranura | Pagina | Que es |
|--------|--------|--------|
| 0000 | 107 | RAM interna |
| 2000 | 106 | RAM interna (aqui va la pantalla) |
| 4000 | 105 | RAM interna |
| 6000 | 104 | RAM interna |
| 8000 | 123 | sistema paginado (POS) con expansion; ROM de disco sin ella |
| A000 | 122 | ROM AB |
| C000 | 121 | ROM CD |
| E000 | 120 | ROM EF |

124 es la MTV y 125 la ACI. La RAM del modulo va de la 103 hacia abajo. En
el RTL la pagina P de RAM esta en el indice fisico `107 - P`: asi la RAM
interna queda en los primeros 32K, que es donde esta sin paginar y donde la
lee el video.

**Y sin paginar, con el modulo puesto, en 8000 tiene que estar ya la POS**:
la ROM AB busca ahi una ROM al arrancar para ejecutarla. Sin ella el sistema
paginado ni siquiera llegaba a arrancar.

## Cuanta RAM

| RAM | Paginas | Resultado |
|-----|---------|-----------|
| 64K | 107..100 | **no arranca**: la ROM prueba la 99, no hay nada y se rinde |
| 96K | 107..96 | arranca. Es lo que traia el modulo de expansion |
| 512K | 107..44 | arranca |
| 768K | 107..12 | arranca |
| 864K | 107..0 | **no arranca**: al llegar a la pagina 0 la ROM se lia |

Por eso las opciones del OSD son 32K, 96K, 512K y 768K.

## Como se prueba

Con RAM de 96K o mas sale **"NewBrain paged system main menu"**. Con el
cursor en BASIC y NUEVA LINEA se entra en el BASIC paginado. Y
`cinta/PRUEBA_MEM.BAS` (en las descargas) lo demuestra:

    10 PRINT FREE
    20 DIM A(3000),B(3000)
    30 PRINT FREE

| | Primer FREE | Linea 20 | Segundo FREE |
|---|---|---|---|
| 32K sin expansion | 30330 | **ERROR 10 AT 20** | — |
| Sistema paginado | 40836 | bien | 4775 |

Son dos matrices de 18K; una sola no sirve, porque cada matriz tiene un
limite de unos 32K (da ERROR 72 con o sin expansion). Comprobado en la
cosimulacion con la ROM series2: `make rompag` y `tools/nbpag.py`.

## Registros, segun el Apendice F

Lo que sigue es la documentacion del fabricante, que vale para los indices
y el puerto 255; el valor de la pagina es el de arriba.

## Puerto 2 — carga de los registros de pagina

Escritura, modulo EI.

Hay **dieciseis registros de 8 bits**. Lo llamativo es que ni el registro ni
buena parte del valor viajan en el dato: van en la **parte alta de la
direccion de E/S**, que el Z80 saca en `OUT (C),A`.

    indice = {A12, A15, A14, A13}        de mas a menos significativo
    pagina = ~{A11, D6, D5, D4, D3, D2, D1, D0}

`D7` no se usa, y **todo el valor va invertido**.

Lo elegante del diseño: `{A15,A14,A13}` es exactamente la ranura de 8K a la
que afecta el registro, y `A12` elige el juego. O sea que para reprogramar la
ranura que cubre `A000` basta con montar una direccion de E/S que tenga esos
bits puestos, sin calcular indices.

## Puerto 255 — registro de estado de paginacion

Escritura. Cada modulo tiene el suyo, y se elige por la parte alta:
**A8** el de expansion, **A9** el de la controladora de disco, **A10** el de
la de red. Esto confirma por la via del fabricante el esquema de seleccion de
dispositivo que habiamos deducido de los simbolos `EXPANSION`,
`DISCCONTROLLER` y `NETWORKCONTROL`.

| Bit | Funcion |
|-----|---------|
| D0 | uno habilita los circuitos de paginacion |
| D1 | sin usar |
| D2 | uno pone A16 local a uno: activa el **segundo juego** de ocho registros |
| D3 | **cero** selecciona modo multiproceso, que alarga los registros de pagina de 8 a **12 bits** |
| D4 | uno aisla la maquina local (modo multiproceso) |

## Cuanta memoria: 2 MB, y 32 en multiproceso

Queda zanjado:

| Modo | Bits de pagina | Paginas | Espacio |
|------|----------------|---------|---------|
| Normal | 8 | 256 | **2 MB** |
| Multiproceso (D3=0) | 12 | 4096 | 32 MB |

Las cifras que manejabamos antes eran las dos bajas: *The NewBrain Dissected*
decia "medio megabyte o asi" y el emulador de cdesp enmascara la pagina a 7
bits, lo que da 1 MB. Lo segundo es una simplificacion suya que le basta
porque las paginas que usa (104-107 RAM interna, 120-123 ROM) caben todas por
debajo de 128.

## El sistema paginado por dentro (manual de expansion, notas 105 y 106)

Lo que hizo falta para entender por que CP/M "volvia al menu":

- **Llamadas al sistema:** `RST 20` seguido de un byte con el numero de
  funcion (ZCODE); `RST 28` es lo mismo pero solo si el acarreo esta a
  cero (un "CALL NC"). Las tablas de funciones estan en `1200`-`15FF` de la
  pagina de sistema. Funciones vistas: `4B` USERPAGE (HL = paginas para la
  region 0; devuelve en HL la mas baja), `46` REQUESTPAGE (A = paginas,
  B = region; comprueba hueco, recoge basura y desplaza regiones), `4A`
  el manejador de fallo, `48`, `45`, `34`, `30`, `31`.
- **Pagina de sistema** (la 96, en la ranura 0): `0079` DISCBUFFER (el
  puntero al bloque de la controladora), `008B`-`009A` S0..S7 (que pagina
  hay en cada ranura), `009F` VIDEOTOP, `00A1` VIDEOBASE, `00A5` UPPAGE,
  `00BB` PUSER, `0700` TABLEZERO del MMS, `1200` ZPTABLE, `1600` VIDTABLE,
  `16A0`-`1701` REGIONTABLE, `1702` SLOTZEROCODE.
- **Regiones:** toda la RAM repartida, menos la pagina de sistema,
  pertenece a una de 16 regiones, con paginas contiguas y en orden. La tabla
  de regiones tiene 6 bytes por region: primera pagina (2), pagina y
  direccion del gestor de region (4); el final de una region es el principio
  de la siguiente, y REGTOP cierra la lista. Region 0: programa de usuario;
  1: DISCIO; 8: MMS.
- **Video:** las paginas de video son las internas mas altas (104-107):
  VIDEOBASE es la primera (108, y se usan hacia abajo) y VIDEOTOP baja
  segun se reservan areas. Las paginas libres para regiones son las que
  quedan entre REGTOP y VIDEOTOP.
- **Sondeo de RAM al arrancar** (`8030` de la ROM del sistema paginado):
  baja desde la pagina 127 hasta la primera que admite escritura (107),
  sigue mientras haya RAM hasta la primera que no (95), y se queda con 96
  como pagina de sistema y 108 como tope.
- **Con 96K:** 96 sistema, 97 el MMS, libres de la 98 a la 105 (justo las 8
  que pide CP/M), 106-107 video. REQUESTPAGE desplaza el MMS a la 105 y
  region 0 queda 97-104. CP/M monta sus 64K con 96-103 (ranura 0 = pagina
  de sistema) y pone las 98-103 en las ranuras 2-7.
- **Cabeceras de ROM:** el sistema busca aplicaciones en las ROMs por su
  cabecera (tipo 5 = programa de usuario con nombre y entrada; tipo 1 =
  rutina de inicializacion, que en la ROM de disco es `80B4` y solo instala
  sus rutinas de dialogo con la controladora y pone el disco como
  dispositivo por defecto).

Herramientas: `tools/nbpagdisco.py` junta el sistema paginado con la
controladora de verdad; con el se vio todo lo anterior.

## Estado de la implementacion

Hecho y comprobado: el sistema paginado arranca con las ROMs originales,
llega a su menu y a su BASIC, y ve mas memoria. Lo que falta: la disquetera
con paginacion (con el modulo puesto la d413 busca su bloque en la RAM del
NewBrain y el core la desactiva) y el modo multiproceso.
