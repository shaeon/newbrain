# Fuentes

Ordenadas por fiabilidad para uso a nivel de registro.

## Primarias

**Listados de ROM desensamblados** — `cdesp/ModNewbrain`, carpeta `ROM/`.
Ficheros `.BLST` de ABROM, CDROM y EFROM: desensamblado simbolico completo de
las tres ROMs originales, con nombres de puerto (`ENREG`, `INTCON`, `TVLL`,
`TVLATCH`). Es lo que la maquina hace de verdad. Fuente de maxima autoridad
para cualquier duda de protocolo.

**Esquemas del motherboard** — `newbrainsche1.jpg` y las paginas 23 y
siguientes del Service Manual Rev 4. Dibujados a mano, legibles. La pagina
util para nosotros es la del array de DRAM con la logica de arbitraje
CPU/video.

## Secundarias

**MAME**, `src/mame/grundy/newbrain.cpp` y `newbrain_v.cpp`. Mapa de
memoria, decodificado de E/S, bits de ENRG1 y UST, ecuacion de interrupcion,
cableado completo del COP420, tiempos RC. Marca el driver como
`MACHINE_NOT_WORKING` y tiene pendientes el video bitmap y el temporizado,
asi que para video no es fiable.

**NB-Emulator-V.3** (`cdesp`, Delphi). Semantica de los puertos de video,
protocolo de comandos del COP a alto nivel, registro de paginacion. Esta
probado contra software real, lo que le da mucho peso.

**ModNewbrain** (`cdesp`, VHDL sobre Gowin). **Ojo: no es un NewBrain
fiel.** Es una maquina modernizada con su propio mapa de E/S (teclado en
`48`, RS232 en `18-1F`, I2C en `70`, almacenamiento en `30`, sonido en `38`)
y sin COP420. Su `vga.vhd` si documenta bien la semantica del modo de video,
aunque su implementacion espia la estructura del sistema operativo en RAM en
vez de usar los puertos.

**calypso-ports** (`teiram`). Plantilla `common/template`, submodulos
`common/T80` y `common/mist-modules`, pinout en los `.qsf`, formato de
`core.definition`.

## Documentacion de usuario

Los PDF del proyecto (Service Manual Rev 1 y 4, The NewBrain System, NewBrain
Basic Technical Specification, Getting More from your NewBrain) son utiles
para el comportamiento visible y las listas de componentes, pero no bajan a
nivel de registro.

**Pendiente:** `The_NewBrain_Dissected.pdf` llego vacio al proyecto. Es el
documento que falta.

## Notas de uNBMemory.pas (emulador de cdesp)

- Con el modulo de expansion usa la AB `Aben191` (issue 3) y la EF `ef1x`
  (issue 1); sin el, la series2. Su RAM con expansion son las paginas 96 a
  107 (96K).
- Parchea `E160` y `E2E0` de la EF con `18` ("not halted ever"), para que
  su emulador no se pare en un `HALT`. Nosotros no lo necesitamos.
- Con expansion carga la ROM de disco en la pagina 119; sin ella, en la
  123. En modo paginado la controladora lee el puntero en `0079` del
  NewBrain y el bloque en `FFCD` de la ranura 7; sin paginar, `9FCD` en la
  RAM compartida.
