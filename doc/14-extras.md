# Extras: puertos serie, remote y pantalla LCD

Tres salidas del NewBrain hacia fuera, cada una detras de su macro. Vienen
**desactivadas**: en el `.qsf` de cada placa estan la macro y los pines
comentados, con `PIN_xx` en lugar del numero. Para usar una se descomenta la
macro y sus pines y se ponen pines libres de la placa. Sin la macro el
puerto no existe en el top, asi que no hace falta asignarle pin.
`tools/nbpines.py` (en `make integration`) avisa si se activa una macro y
falta algun pin.

## Puertos serie: `NB_SERIE`

Los dos puertos serie de la maquina, que en el NewBrain son por programa:
la ROM mueve los bits a mano con el registro `ENREG` (puerto 07) y lee los
de entrada del `UST_B` (puerto 16).

| Pin | Sentido | Del NewBrain |
|-----|---------|--------------|
| `V24_TXD` | salida | ENREG b5 (DO) |
| `V24_RTS` | salida | ENREG b4 (_RTSD), activo a nivel bajo |
| `V24_RXD` | entrada | UST_B b0 (RDDK) |
| `V24_CTS` | entrada | UST_B b1 (_CTSD), activo a nivel bajo |
| `PRN_TXD` | salida | ENREG b7 (PO), la impresora |
| `PRN_CTS` | entrada | UST_B b7 (_CTSP), activo a nivel bajo |

Niveles TTL con la linea en reposo a 1 (tras arrancar, ENREG vale `AE`: DO y
PO a uno). Para un conector RS232 de verdad hace falta un MAX3232 o similar.

Sin la macro, RXD queda en reposo (1) y los dos CTS dando paso (0). Antes RXD
estaba atado a 0, que para un puerto serie es un bit de inicio permanente.

## Remote de las cintas: `NB_REMOTE`

`TAPE_REMOTE1` y `TAPE_REMOTE2`, a 1 con el motor en marcha, para un
transistor o un rele que pare el magnetofono.

En la maquina original los sacaba el COP por G1 y G3. Aqui la cinta la lleva
el modulo de cinta y al COP de verdad le llega un NULLCOM, asi que el remote
sale del modulo: los bits de motor del `CASSCOM` en curso (b3 para la cinta
1, b1 para la 2) mientras dura la operacion.

## Pantalla LCD 16x2 por I2C: `NB_LCD`

Lo que el NewBrain AD enseñaba en su display fluorescente de 16 digitos, en
una pantalla LCD de 16x2 con el modulo I2C de siempre (PCF8574 detras de un
HD44780), el de la libreria LiquidCrystal_I2C de Arduino:

    P0 RS   P1 RW   P2 E   P3 retroiluminacion   P4..P7 D4..D7

- **Linea 1:** el texto del display fluorescente.
- **Linea 2:** "Cinta" mientras la cinta trabaja y "Disco" mientras trabaja
  la disquetera.

La **direccion I2C** se elige en el OSD, en "Pantalla I2C": `27h` y `20h`
(PCF8574) o `3Fh` y `38h` (PCF8574A). La de casi todos los modulos es 27h.

**Tension:** los modulos llevan resistencias de subida a 5 V en SDA y SCL.
Hay que alimentarlos a 3,3 V (casi todos funcionan, aunque el contraste
cambia) o poner un adaptador de niveles.

### De donde sale el texto

El display lo lleva el COP, pero el texto se lo manda el Z80 por el puerto
06, y `rtl/newbrain_vfd_espia.v` lo escucha. Medido con las dos ROMs
originales: a una interrupcion del COP, el Z80 contesta con DISPCOM (A0), y
en la siguiente, sin leer vector, escribe 18 bytes. Los dos primeros son de
control y los 16 siguientes el texto **al reves**; "NEWBRAIN BASIC" llega
como `20 00 20 20 43 49 53 41 42 20 4E 49 41 52 42 57 45 4E`. Los 6 bytes de
TIMCOM se saltan.

### Pruebas

- `tb_newbrain_vfd_espia.v`: la secuencia real, con un TIMCOM de por medio
  que no se cuela y un DISPCOM sin datos que no cambia nada.
- `tb_newbrain_lcd_i2c.v`: decodifica el bus I2C como el PCF8574 y pasa lo
  que llega a un HD44780 de mentira (8 bits hasta el paso a 4 bits, luego por
  parejas de nibbles, dato en la bajada de E). Al final su memoria tiene las
  dos lineas, con la retroiluminacion encendida, y un cambio de texto se ve
  en la vuelta siguiente.
- `make integration` elabora el top con las tres macros puestas.
