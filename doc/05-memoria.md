# Reparto de memoria en el 10CL025

## El error de cuentas inicial

La hoja de caracteristicas del Cyclone 10 LP dice 594 Kbit de block RAM en el
10CL025, que parecian 74 KB. **No lo son para lo que necesitamos.** Un M9K
tiene 9216 bits, pero en modo de byte solo se aprovechan 8192, y cada bloque
almacena 1024 bytes. Con 66 bloques eso son **66 KB reales** de memoria de
byte, no 74.

Peor aun: Quartus asigna bloques enteros, asi que una memoria de 4 KB puede
acabar ocupando mas de los 4 bloques teoricos segun como infiera los puertos.

## Lo que no cabia

Primer intento de compilacion, con todo en block RAM:

| Bloque | Tamaño | M9K |
|--------|--------|-----|
| RAM del sistema | 32 KB | 32 |
| ROM del sistema | 24 KB | 24 |
| Generador de caracteres | 4 KB | 8 |
| Buffer de linea del scandoubler | — | 12 |
| Buffer del OSD | — | 8 |
| **Total** | | **84** |

Con 66 disponibles, se pasaba en 18. El fitter fallo con
`Error (170048): Selected device has 66 RAM location(s) of type M9K`.

Conviene fijarse en que 20 de los 84 bloques son del OSD y el scandoubler de
`mist_video`, que vienen dados y no se pueden recortar.

## La solucion

La ROM del sistema se saca a la **SDRAM**. Es la candidata obvia:

- es de solo lectura desde el punto de vista del Z80, y se escribe una sola
  vez al cargar desde la SD;
- tiene un unico cliente, la CPU, asi que el controlador puede ser de un solo
  puerto y sin arbitraje;
- el Z80 va a 4 MHz y la SDRAM a 32, asi que una lectura completa cabe de
  sobra dentro de un estado T. Aun asi el core para el Z80 mientras espera,
  quitandole los clock enables, en vez de jugar con `WAIT_n`.

La RAM se queda en block RAM porque tiene dos clientes simultaneos, la CPU y
el generador de imagen, y es lo mas sensible a la latencia. El generador de
caracteres tambien se queda, por no meter un segundo cliente en la SDRAM con
el plazo justo de una celda de caracter.

Reparto resultante:

| Bloque | M9K |
|--------|-----|
| RAM del sistema | 32 |
| Generador de caracteres | 8 |
| Scandoubler | 12 |
| OSD | 8 |
| **Total** | **60 de 66** |

Quedan 6 bloques de margen.

## Resuelto: ver doc/08-sdram.md

La llegada de la paginacion obligo a mover tambien la RAM del sistema a la
SDRAM, porque 2 MB de espacio fisico no caben en block RAM de ninguna forma.
El reparto quedo en **29 bloques de 66**. Lo que sigue se deja como registro
de las opciones que se valoraron.

## Si hiciera falta mas margen

Por orden de menor a mayor riesgo:

1. **Generador de caracteres a SDRAM** (libera 8). Necesita un segundo
   cliente en el controlador, con el plazo de una celda de caracter: en 80
   columnas son 8 relojes de punto, o sea 16 ciclos de sistema. Da, pero hay
   que repartir turnos fijos entre CPU y video.
2. **Recortar el generador de caracteres a 2560 bytes** (libera unos 5). Solo
   si se confirma que la EPROM esta ordenada por linea de barrido y que las
   lineas 10 a 15 no se usan. Depende de una suposicion que aun no esta
   verificada, ver `doc/04-video.md`.
3. **RAM del sistema a SDRAM** (libera 32). Es lo que mas libera y lo mas
   delicado: haria falta un controlador con tres clientes y prioridad para el
   video. Probablemente inevitable en la fase 6, cuando entre la paginacion,
   que en cualquier caso va a vivir en SDRAM. El tamaño del espacio paginado
   sigue sin confirmarse: ver `doc/06-expansion.md`.

## Geometria de la SDRAM

El controlador usa columnas de 8 bits (256 columnas, 512 bytes por fila), que
es lo conservador: vale igual para un chip de 64 Mbit que de 128, y de los
8 MB de la placa solo se tocan los primeros 24 KB.

    direccion de byte -> palabra = addr[23:1], byte = addr[0]
    columna = palabra[7:0]   fila = palabra[20:8]   banco = palabra[22:21]

El reloj de la SDRAM sale invertido respecto al del sistema. A 32 MHz eso deja
medio periodo, 15,6 ns, de margen.
