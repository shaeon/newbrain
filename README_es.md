# Grundy NewBrain para placas FPGA de la familia MiST

*[Read in English](README.md)*

Implementación en FPGA del **Grundy NewBrain** (1982) para las placas
**MiST**, **Calypso**, **SiDi** y **Poseidon**. Ejecuta las ROMs originales, incluidos
el microcontrolador COP420 del teclado y el display y el Z80 propio de la
controladora de disco, y arranca BASIC y CP/M 2.2 desde imágenes de disco
EDSK.

## Características

- Z80 a 4 MHz (T80), con todo el mapa de memoria (ROM y RAM) en la SDRAM.
- **COP420 real**: la ROM original del COP corre en un núcleo COP400 y lleva
  el teclado, el display de 16 caracteres y el reloj de 50 Hz.
- **Vídeo**: texto de 40 y 80 columnas, gráficos de puntos, vídeo inverso y
  el modo de 256 caracteres, con color de fósforo y aspecto elegibles en el
  OSD.
- **Cinta**: ficheros `.bas`/`.bin` desde el OSD, o audio real por la
  entrada de audio.
- **Módulo de expansión**: memoria paginada de 96K a 768K y el sistema
  operativo paginado con su menú principal.
- **Controladora de disco**: un segundo Z80 que ejecuta la ROM original de la
  controladora con un uPD765, leyendo imágenes EDSK. CP/M 2.2 funciona tanto
  en la máquina de 32K (`cpm` desde BASIC) como en el sistema paginado de 64K
  (desde el menú principal).
- Opcionales, desactivados de fábrica: los dos puertos serie, el remote del
  motor de la cinta y una pantalla LCD I2C de 16x2 (módulo LiquidCrystal_I2C
  de Arduino) con el texto del display.
- Herramientas de imágenes de disco: de Teledisk a EDSK, de una carpeta del
  PC a un disco CP/M arrancable, y de volcados raw a EDSK.

**Las ROMs no se incluyen.** Tienen copyright de sus propietarios y las tiene
que aportar el usuario.

## Cómo funciona

El NewBrain es pequeño, pero tiene tres procesadores, y el core también.

**CPU principal y memoria.** El T80 va a 4 MHz a partir de un reloj de
sistema de 32 MHz, con habilitaciones de reloj. Toda la ROM y la RAM viven en
la SDRAM; un árbitro de prioridad fija atiende al vídeo, la CPU, la cinta, la
carga de ROMs y la controladora de disco, y detiene la CPU quitándole las
habilitaciones cuando le toca esperar. El decodificador de memoria reproduce
el mapa del NewBrain y, con el módulo de expansión, su paginación: ocho
ranuras de 8K, dos juegos de ranuras y registros de página, con los números de
página exactamente como los espera el sistema paginado original.

**El COP420.** En la máquina real, un COP420 de National barre el teclado,
maneja el display fluorescente, cronometra la cinta e interrumpe al Z80 cada
20 ms. El core ejecuta la ROM original del COP en el núcleo COP400 T400, que
habla con el Z80 por el mismo puerto MICROBUS. Un teclado PS/2 se traduce a
la matriz de teclas del NewBrain, con una pequeña cola y un tiempo mínimo de
pulsación para que el barrido de 20 ms del COP no pierda ninguna tecla.

**Cinta.** Las órdenes de cinta las atiende un módulo aparte, de alto nivel,
que se queda el puerto del COP cuando el Z80 manda una orden de cinta,
mientras el COP real sigue con el teclado, el display y el reloj. Carga
ficheros desde el OSD y desmodula el audio de cintas reales.

**Vídeo.** El generador de vídeo recorre el fichero de pantalla del NewBrain
en la RAM: las líneas de texto y la zona gráfica con sus terminadores, 40 u 80
columnas, y la ROM del generador de caracteres. Un buffer de línea se llena
desde la SDRAM con el reloj del sistema y se pinta con un reloj de píxel
aparte, así que el reloj de punto puede ser el de la máquina, 16 MHz
(**Aspect: Original**), o 13,5 MHz, que llena una pantalla 4:3 como los
emuladores (**Aspect: Wide**).

**Controladora de disco.** El interfaz de disco del NewBrain es una placa con
su propio Z80, EPROMs, RAM y un NEC uPD765. El core la emula tal cual: un
segundo T80 ejecuta la ROM original de la controladora y maneja el
controlador de disquete `u765`, que lee imágenes EDSK de la tarjeta SD. Sin
expansión comparte 1K de RAM con el NewBrain; con el módulo de expansión
llega a la memoria paginada con la misma traducción de páginas que la CPU.

**Pruebas.** Cada bloque tiene su banco de pruebas en Icarus Verilog, y el
comportamiento de las ROMs originales se comprobó en cosimulación (modelos en
Python del Z80 y del COP420 ejecutando las ROMs reales) antes y después de
escribir el RTL. Las notas de desarrollo están en `doc/00-desarrollo.md`.

## Compilar

Abre en Quartus el proyecto de tu placa (`mist/`, `calypso/`, `sidi/` o `poseidon/`) y
compila. Los bancos de pruebas se lanzan con `make` en `test/`.

## Créditos

Este core se apoya en el trabajo de mucha gente. Gracias a todos.

**Código usado en el core**

- **T80**, núcleo Z80: Daniel Wallner, con correcciones posteriores de
  Sorgelig y la comunidad MiST/MiSTer. Licencia tipo BSD.
- **T400**, núcleo COP400: Arnim Läuger
  (https://github.com/devsaurus/t400). Licencia BSD de tres cláusulas.
  Convertido a Verilog para este proyecto.
- **Módulos de MiST** (`user_io`, `data_io`, `mist_video`, OSD, scandoubler y
  relacionados): Till Harbaum, Gyorgy Szombathelyi (gyurco) y la comunidad
  MiST. GPL v3 o posterior.
- **u765**, controlador de disquete uPD765: Gyorgy Szombathelyi (gyurco), de
  Amstrad_MiST. GPL v2 o posterior.
- DAC delta-sigma: basado en la nota de aplicación XAPP154 de Xilinx.

**Referencias e inspiración**

- **MAME**: el driver del NewBrain y el núcleo COP400 (Curt Coder y el equipo
  de MAME, BSD de tres cláusulas). El modelo en Python del COP420 y su
  desensamblador, en las herramientas, están portados del núcleo COP400 de
  MAME.
- **NewBrain Emulator** de Chris Despoinidis (**CDesp**), y su proyecto
  ModNewbrain: una referencia imprescindible para el mapa de memoria, la
  paginación y el sistema de disco (https://newbrainemu.eu/).
- El core de Amstrad de gyurco (plantillas de los proyectos del MiST y la
  Poseidon, colores de fósforo) y el core de Oric de rampa069 (estructura para la SiDi).
- Documentación: *The NewBrain Dissected*, los manuales de servicio y notas
  técnicas de Grundy, el *Expansion & Disk Controller Manual* de Tradecom y el
  *Software Technical Manual*.
- beepgenerator, para el formato de cinta (autor desconocido; si eres el
  autor, escríbenos y te citamos).

**Herramientas**

- Las herramientas de cosimulación usan el paquete `z80` de Python de Ivan
  Kosarev (licencia MIT, no incluido).
- El conversor de Teledisk contiene una implementación del algoritmo LZHUF de
  Haruyasu Yoshizaki y Haruhiko Okumura.

## Agradecimientos

Al **Retro-Wiki FPGA-dev Team**, en especial a **Ron, Manuel (teiram), Somhi,
Roderick, Rampa, Kyp y Benito**, por su ayuda y su paciencia.

A **Turri (turri21)**, ¡gracias por el arreglo de la CPU Z80 y por el port a Senhor!

A **https://newbrainemu.eu/**, y en especial a **CDesp**, por mantener vivo
el NewBrain y por todo el conocimiento reunido allí.

## Asistencia de IA y recursos

Partes de este core se desarrollaron con la ayuda de Claude (Anthropic), usado
para código, bancos de pruebas, cosimulación y documentación. El acceso a
Claude lo proporcionó Advanced Computer Trading, S.L. (actsl.com), que además
autoriza la publicación de este trabajo bajo la licencia indicada abajo. Todas
las decisiones de diseño, la integración, las pruebas en hardware real y la
revisión final las hizo el autor, Shaeon (Carlos Palmero).

## Licencia

Copyright (C) 2026 Shaeon (Carlos Palmero).

Este programa es software libre: puedes redistribuirlo y/o modificarlo bajo
los términos de la **Licencia Pública General de GNU** publicada por la Free
Software Foundation, ya sea la **versión 3** de la licencia o (a tu elección)
cualquier versión posterior. Ver [LICENSE](LICENSE).

Hace falta la versión 3 porque algunos de los módulos incluidos (los módulos
de MiST) tienen licencia GPL v3 o posterior. Los ficheros de terceros
conservan sus propios avisos de copyright y licencias, que son compatibles con
la GPL v3.

## Exención de responsabilidad

Este proyecto se entrega **"tal cual", sin garantía de ningún tipo**, ni
expresa ni implícita, incluidas, entre otras, las garantías de
comerciabilidad y de idoneidad para un fin concreto. En ningún caso los
autores o colaboradores serán responsables de ninguna reclamación, daño u otra
responsabilidad derivada del uso de este software, del hardware en el que se
ejecuta o de cualquier equipo conectado. Úsalo bajo tu propia responsabilidad.

NewBrain es una marca de sus respectivos propietarios. Este proyecto no está
afiliado a ellos ni cuenta con su respaldo.
