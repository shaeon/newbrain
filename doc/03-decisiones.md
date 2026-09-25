# Decisiones de diseño y cuestiones abiertas

## Decidido

**Relojes.** PLL de 12 MHz a 32 MHz. El Z80 va a 32/8 = 4,000 MHz exactos y
el punto de video a 32/2 = 16 MHz, que reproduce el cristal real. Evita
tener que sintetizar 16 MHz por separado.

**ROM en SDRAM, RAM y generador de caracteres en block RAM.** La cuenta
inicial de "56 KB de los 74 disponibles" estaba mal: en modo de byte cada M9K
guarda 1 KB, asi que los 66 bloques del chip son 66 KB, y el OSD con el
scandoubler ya se llevan 20. El primer intento de compilacion pedia 84
bloques y el fitter lo rechazo. Ver `doc/05-memoria.md`.

**ROMs por `data_io`, no en el `.rbf`.** Un unico fichero de 24576 bytes.
Evita redistribuir ROMs y permite cambiar de revision sin resintetizar.

**COP420 por fases.** Stub, luego HLE del protocolo, luego core COP400. Ver
`02-cop420.md`.

**Modelo A y AD a la vez.** El display fluorescente no es hardware aparte:
es el destino de la trama serie del COP. Se captura y se decide despues si
se pinta como overlay, se saca por pines auxiliares, o ambas.

**Tiempos de arranque: resuelto.** Verificado en el listado de EFROM que la
ROM solo sondea `POWTEST` en el bucle `PWAIT` de `E009` y no mide el
intervalo. Acortar los RC es seguro. `newbrain_powerup` mantiene los tiempos
reales por defecto y expone una entrada `fast` que los divide por 32,
conectada al bit 6 del OSD.

**`ce_divider` de `mist_video`: resuelto.** En `scandoubler_framing.v` el
valor N significa `clk_sys / (N+1)`, asi que 1 da los 16 MHz que buscabamos
desde los 32 del sistema.

**Entidad del T80: resuelto.** `T80pa` existe en `common/T80/T80pa.vhd` con
los puertos que usa el core. Tiene ademas `OUT0`, `R800_mode`, `REG`,
`DIRSet` y `DIR`, todos con valor por defecto o de salida, asi que se pueden
dejar sin conectar.

**Ancho de `status` y de `ioctl_addr`: corregido.** `user_io` declara
`status` de 64 bits y `data_io` declara `ioctl_addr` de 27, no de 32 y 25
como estaban en el top. La plantilla de calypso-ports arrastra el mismo
desajuste en `status`.

**Bancos de estado de UST_A: resuelto.** Los eligen `ENREG[7:6]` para el
bit 0 y `ENREG[5:4]` para el bit 1, segun `uNBIO.pas` de cdesp. Ver
`01-hardware.md`.

**Cinta: resuelto.** El ERROR 131 era `LENGTHERR`, provocado por los REGINT
que el HLE mandaba en mitad de un bloque. Ver `11-cinta.md`.

**Disquetera: HLE, no un segundo Z80.** La controladora habla con el
NewBrain por 1K de RAM compartida, no por puertos de datos, asi que el
protocolo se puede atender directamente. Ver `13-disquetera.md`.

**Arranque en frio del T80: parcheado.** En `common/T80/T80pa.vhd` la rama
de reset no inicializaba `IntCycleD_n` ni `Wait_s`. En una FPGA recien
configurada podian empezar indefinidos y estropear el primer ciclo de bus o
de interrupcion; los resets posteriores iban bien porque la ejecucion ya los
habia dejado validos. Ahora el reset pone `IntCycleD_n <= "11"` y
`Wait_s <= '1'`. **Es un cambio sobre el T80 de fuera**: si se actualiza el
submodulo, hay que volver a aplicarlo.

**Opciones de arranque fuera del menu.** Video normal, 40 columnas y
pantalla activa quedan fijos, que era lo que el menu daba por defecto. Los
bits 18 a 20 de `status` quedan libres.

**Polaridad de POWTEST: resuelto.** Va al reves que en MAME. Vale 1 mientras
el mapa esta forzado y 0 cuando la RAM es visible. Ver `01-hardware.md`.

## Abierto

**Bits 3, 4 y 6 de UST_A.** Se leen a 1 y no se ha identificado su funcion.

**Fuente de `CLKINT`.** De momento es un contador de 50 Hz. En la maquina
real casi con seguridad viene de la trama de video (50,08 Hz). En cuanto
exista el generador de video hay que colgarlo de `vsync_pulse`.

**Decodificado de TVL.** MAME distingue los dos puertos del grupo con A6
(`08` contra `48`); el emulador y los listados de ROM usan A0 (`08` contra
`09`). Implementado segun la ROM. Si algun dia aparece software que use `48`
habra que revisarlo.

**Lectura del bus abierto.** `8000-9FFF` devuelve `FF`. En la maquina real
seria el ultimo dato del bus; si algun programa depende de ello, habra que
implementar bus flotante.
