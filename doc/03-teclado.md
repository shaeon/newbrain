# Teclado y codificacion de teclas

## Matriz

16 filas x 4 bits. En la maquina real el contador CD4024 recorre las filas y
el latch CD4076 devuelve los cuatro bits, que llegan al COP repartidos entre
varias patas (`G2`, `G1`, `IN0`, `G3`).

Filas, con el bit de cada tecla tal como lo cablea MAME:

| Fila | bit 0 | bit 1 | bit 2 | bit 3 |
|------|-------|-------|-------|-------|
| 0 | — | STOP | — | — |
| 1 | abajo | derecha | izquierda | arriba |
| 2 | U | 8 | 7 | J |
| 3 | I | 9 | 6 | N |
| 4 | Y | 0 | 5 | M |
| 5 | O | ( [ | 4 | , |
| 6 | L | ) ] | 3 | . |
| 7 | ; : | * £ | 2 | B |
| 8 | H | VIDEO TEXT | 1 | V |
| 9 | G | P | T | C |
| 10 | F | = @ | R | X |
| 11 | D | - \\ | E | Z |
| 12 | S | + ^ | W | INSERT |
| 13 | A | NEW LINE | Q | K |
| 14 | / ? | — | espacio | INICIO |
| 15 | SHIFT | GRAPHICS | REPEAT | CONTROL |

Los modificadores son teclas normales de la matriz, en la fila 15.

## Formato del byte que entrega el COP

    b7 b6   modificador        b5..b0   codigo de matriz
    0  0    normal
    0  1    SHIFT
    1  0    CONTROL
    1  1    GRAPHICS

Los modificadores salen de la rutina `KLK3A` de la ROM AB (`B781`): primero
`BIT 7,B` separa control/graphics del resto, y despues `BIT 6,B` distingue
graphics de control, o shift de normal.

El valor `80` (control + codigo 0) se usa como "no hay tecla". La rama KBD de
la rutina de interrupcion lee **dos veces**: la primera espera un centinela
distinto de `80` y la segunda recoge el codigo. Ver `02-cop420.md`.

La codificacion de esta pagina esta **verificada contra la maquina real**:
inyectando el codigo 46 en el simulador aparece una `a` en pantalla, y una
secuencia de `a`, espacio e Intro hace que el interprete conteste
`ERROR 55`.

## Codigo de matriz

    codigo = columna * 16 + ((fila + 1) mod 16)

donde `columna` **no** es el numero de bit, sino el orden en que el COP los
serializa:

| bit de la matriz | columna |
|------------------|---------|
| 2 | 0 |
| 1 | 1 |
| 0 | 2 |
| 3 | 3 |

### Como se ha deducido

No es una conjetura. La ROM AB tiene en `A1A7` una tabla de 64 bytes
(`KTABLE`) indexada justo por este codigo, que la rutina de traduccion
consulta despues de hacer `AND 3FH`. Volcandola y comparandola posicion a
posicion con la matriz encajan las 50 y pico teclas con caracter asignado:

| Tecla | Fila, bit | Codigo | `KTABLE` |
|-------|-----------|--------|----------|
| A | 13, 0 | 46 | `61` = 'a' |
| Q | 13, 2 | 14 | `71` = 'q' |
| espacio | 14, 2 | 15 | `20` |
| NEW LINE | 13, 1 | 30 | `0D` |
| * | 7, 1 | 24 | `2A` = '*' |
| 7 | 2, 2 | 3 | `37` = '7' |
| izquierda | 1, 2 | 2 | `08` |

El caso de `*` es el que cierra la deduccion: la rutina de interrupcion hace
`AND 3FH` / `CP 18H` con el comentario `* KEY`, y `18H` = 24 es exactamente
el codigo que da la formula. Las cuatro entradas a 0 de la tabla (indices 0,
16, 32 y 48) se corresponden con la fila 15, la de los modificadores, que no
tienen caracter.

El desplazamiento de una fila viene del momento en que el COP muestrea
respecto al reset del contador CD4024.

## Tablas de traduccion en la ROM AB

| Direccion | Tabla | Uso |
|-----------|-------|-----|
| `A1A7` | KTABLE | 64 bytes, sin modificador |
| `A1E7` | KTAB4 | 64 bytes, shift |
| `A227` | KTAB1 | 32 bytes |
| `A247` | KTAB2 | 32 bytes |
| `A267` | KTAB3 | 32 bytes |
| `A287` | KTAB5 | modo TTCAPS |
| `A292` | KTAB6 | |

## Distribucion PC que usa el core

No hay correspondencia natural para algunos simbolos, asi que la asignacion
es una eleccion nuestra y se puede cambiar sin tocar nada mas:

| NewBrain | PC |
|----------|-----|
| STOP | Esc |
| NEW LINE | Intro |
| `(` `[` | `[` |
| `)` `]` | `]` |
| `*` `£` | `'` |
| `+` `^` | `` ` `` |
| VIDEO TEXT | AltGr |
| GRAPHICS | Alt |
| REPEAT | Tab |
| CONTROL | Ctrl |
| INICIO | Inicio |


## De donde salen las teclas

**Por la linea PS/2 serie de `user_io`, no por `key_strobe`.** Esa interfaz
arma cada tecla dando por hecho que el firmware manda la secuencia entera
(`E0`, `F0` y el codigo) en una sola transferencia SPI, y reinicia el estado
del prefijo al empezar cada transferencia. El firmware de la SiDi manda un
byte por transferencia: el `F0` se perdia y **cada soltar llegaba como otra
pulsacion**. Salian dos caracteres por tecla, y lo peor, SHIFT, CONTROL y
GRAPHICS se quedaban pegados porque su soltar los volvia a apretar, asi que
parecia que habia cambiado el juego de caracteres.

`user_io` saca tambien el teclado como PS/2 serie, byte a byte, y ahi el
prefijo nunca se pierde. `rtl/newbrain_ps2.v` lo recibe, guarda `E0` y `F0`
entre bytes y entrega las teclas con el formato de siempre.

`tb_newbrain_ps2_uio.v` lo prueba contra el serializador de verdad de
`user_io`, con los bytes llegando de golpe (como en la Calypso) y uno a uno
con huecos (como en la SiDi): ocho eventos exactos, ni uno de mas, y el
SHIFT se suelta.
