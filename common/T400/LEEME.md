# T400

Core del microcontrolador COP400 de Arnim Laeuger, tomado de
https://github.com/devsaurus/t400

Licencia BSD de tres clausulas; el aviso de copyright esta en la cabecera de
cada fichero y se conserva sin tocar.

Se usa **`t400_core`** directamente, no el envoltorio `t420`: el core expone
la memoria de programa y la de datos como puertos externos
(`pm_addr_o`/`pm_data_i`, `dm_*`), que es justo lo que hace falta para
alimentarlo con la ROM del NewBrain cargada desde la SD.

Solo se copia `rtl/vhdl`. Lo de `syn` y `tb` no hace falta.
