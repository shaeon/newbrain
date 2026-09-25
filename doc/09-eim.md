# Modulo de Expansion Principal (EIM)

Es la pieza que hace falta para que existan la expansion de memoria y la
disquetera. Lo que hay hecho, lo que falta y de donde sale cada cosa.

## Que lleva la placa

Segun `eim.cpp` de MAME, que no implementa comportamiento pero si el
inventario de hardware:

| Pieza | Nota |
|-------|------|
| Z80 CTC | a 16 MHz / 8 = 2 MHz |
| ACIA 6850 | puerto serie |
| ADC0809 | 8 entradas analogicas, a 500 kHz |
| DAC0808 | salida analogica |
| RAM | 96K por defecto en MAME |
| 24K de ROM | tres imagenes de 8K |

Las ROMs, con los nombres que MAME les da y la fecha que llevan dentro:

| Fichero | Contenido |
|---------|-----------|
| `e415-3.rom` | `19#8#83.aci` |
| `e416-3.rom` | `10#8#83.mtv` |
| `e417-2.rom` | sin identificar, probablemente el sistema paginado |

Los nombres coinciden con los que usa el emulador de cdesp para sus paginas,
lo que confirma que hablan del mismo hardware.

## Lo que ya funciona

**Paginacion completa** (`newbrain_pager.v`), segun el Apendice F: dieciseis
registros de pagina por el puerto 2, control por el 255, dos juegos de ocho
ranuras y 2 MB de espacio fisico. Ver `doc/07-paginacion.md`.

**Reparto de paginas a ROM** en `newbrain_mem.v`:

| Pagina | Sin expansion | Con expansion |
|--------|---------------|---------------|
| 120 | ROM AB | ROM AB |
| 121 | ROM CD | ROM CD |
| 122 | ROM EF | ROM EF |
| 123 | ROM de disco | sistema paginado |
| 124 | — | MTV |
| 125 | — | ACI |

Que la pagina 123 sea una cosa u otra segun lo enchufado no es un apaño: es
la misma ranura de `8000` ocupada por quien este presente, igual que en la
maquina real.

**Puertos propios del EIM** en `newbrain_io.v`. Con el modulo presente el
decodificado pasa de A0-A4 a **A0-A7 completos**, tal y como dice la nota 2
del Apendice F, y aparecen:

| Puerto | Funcion |
|--------|---------|
| `01` | ENREG2, registro de habilitacion 2 |
| `03` | salida paralela enclavada, Centronics |
| `15` | UST2, registro de estado 2 |

Sin expansion el `15` sigue siendo un alias del `14`, que es lo que hace la
maquina pelada, y el `01` no existe.

**Registro de estado 2**, que es la configuracion de arranque que la maquina
consulta:

| Bit | Significado |
|-----|-------------|
| D2 | uno: video normal. cero: inverso |
| D3 | uno: alimentacion de red |
| D4 | uno: 40 columnas. cero: 80 |
| D6 | uno: se quiere pantalla |

Los tres de configuracion salen de opciones del OSD, asi que se puede
arrancar directamente en 80 columnas o en video inverso.

**Carga de las ROMs del EIM**: el fichero crece a 61440 bytes con 24K mas al
final. Todo lo opcional va detras, asi que un fichero de 28672 o de 36864
sigue valiendo.

## Lo que falta

**Z80 CTC.** Es el temporizador del modulo y genera los relojes de la ACIA.
Hace falta para el puerto serie y probablemente para que el sistema paginado
arranque sin colgarse esperando una interrupcion. Es el siguiente trozo de
RTL, y no es pequeño: cuatro canales con contador, prescaler, vector de
interrupcion y cadena de prioridad.

**ACIA 6850.** Puerto serie. No hace falta para arrancar.

**ADC0809 y DAC0808.** Entradas y salida analogicas. Nada que ver con
arrancar; el DAC ademas tiene el detalle, documentado en el Apendice F, de
que en los primeros 200 modulos los bits de datos van invertidos.

**Las ROMs.** No estan en `newbrain.zip`: van en el romset del dispositivo.
Sin ellas nada de esto se puede probar de verdad.

**El reparto de paginas** viene del mapa del emulador de cdesp, no de
documentacion de Grundy. Es lo mas probable que haya que ajustar cuando
tengamos las ROMs y se pueda contrastar.

## Orden recomendado

1. Conseguir las tres ROMs del EIM.
2. Arrancar con la paginacion activa y ver hasta donde llega el sistema
   paginado. Con `tools/nbsim.py` se puede hacer sin tocar la placa, que es
   como se resolvieron el video y el teclado.
3. Implementar el CTC si resulta que el arranque lo necesita.
4. La disquetera despues, que ademas depende de desensamblar la `d413`. Ver
   `doc/06-expansion.md`.
