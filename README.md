# Grundy NewBrain for MiST-family FPGA boards

*[Leer en español](README_es.md)*

An FPGA implementation of the **Grundy NewBrain** (1982) for the **MiST**,
**Calypso**, **SiDi** and **Poseidon** boards. It runs the original ROMs, including the
COP420 keyboard/display microcontroller and the disk controller's own Z80,
and boots BASIC and CP/M 2.2 from EDSK disk images.

## Features

- Z80 at 4 MHz (T80), with the whole memory map (ROM and RAM) in SDRAM.
- **Real COP420**: the original COP ROM runs on a COP400 core and handles the
  keyboard, the 16-character display and the 50 Hz timer.
- **Video**: 40 and 80 column text, pixel graphics, reverse video and the
  256-character mode, with an OSD choice of phosphor colour.
- **Tape**: `.bas`/`.bin` files from the OSD, or real audio on the audio
  input.
- **Expansion Interface Module**: paged memory from 96K to 768K and the
  paged operating system with its main menu.
- **Disk controller**: a second Z80 running the original controller ROM
  with a uPD765, reading EDSK images. CP/M 2.2 works both on the 32K machine
  (`cpm` from BASIC) and on the 64K paged system (from the main menu).
- Optional, off by default: the two serial ports, tape motor remote, and a
  16x2 I2C LCD (Arduino LiquidCrystal_I2C module) showing the display text.
- Disk image tools: Teledisk to EDSK, PC folder to bootable CP/M disk, and
  raw dumps to EDSK.

**ROMs are not included.** They are copyright of their owners and have to be
supplied by the user.

## How it works

The NewBrain is small, but has three processors, and so does the core.

**Main CPU and memory.** The T80 runs at 4 MHz from a 32 MHz system clock
using clock enables. All ROM and RAM live in the SDRAM; a fixed-priority
arbiter serves video, CPU, tape, ROM download and the disk controller, and
stalls the CPU by withholding its enables when it has to wait. The memory
decoder reproduces the NewBrain map and, when the Expansion Interface Module
is selected, its paging: eight 8K slots, two slot sets and page registers,
with page numbers exactly as the original paged system expects.

**The COP420.** In the real machine a National COP420 scans the keyboard,
drives the vacuum fluorescent display, times the tape and interrupts the Z80
every 20 ms. The core runs the original COP ROM on the T400 COP400 core,
talking to the Z80 through the same MICROBUS port. A PS/2 keyboard is
translated into the NewBrain key matrix, with a small queue and a minimum
key-down time so that the COP's 20 ms scan never misses a key.

**Tape.** Tape commands are served by a separate high-level module that
takes over the COP port whenever the Z80 sends a cassette command, while the
real COP keeps the keyboard, display and timer. It loads files from the OSD
and demodulates real tape audio.

**Video.** The video generator walks the NewBrain's display file in RAM:
text lines and the graphics area with its terminators, 40 or 80 columns, and
the character generator ROM. A line buffer is filled from SDRAM in the system
clock domain and scanned out in a separate pixel clock domain. The dot clock
is 13.5 MHz instead of the machine's 16 MHz: the line still lasts 64 us, the
image fills a 4:3 screen as the emulators do, and the scandoubled 31 kHz
output is exactly the standard 720x576 50 Hz timing, which monitors
recognise.

**Disk controller.** The NewBrain disk interface is a board with its own Z80,
EPROMs, RAM and a NEC uPD765. The core emulates it as such: a second T80 runs
the original controller ROM and drives the `u765` floppy controller, which
reads EDSK images from the SD card. Without expansion it shares 1K of RAM with
the NewBrain; with the Expansion Interface Module it reaches the paged memory
through the same page translation as the CPU.

**Testing.** Every block has an Icarus Verilog testbench, and the behaviour
of the original ROMs was checked in co-simulation (Python Z80 and COP420
models running the real ROMs) before and after writing the RTL. See
`doc/00-desarrollo.md` for the development notes.

## Building

Open the project for your board in Quartus (`mist/`, `calypso/`, `sidi/`
or `poseidon/`) and compile. The testbenches run with `make` in `test/`.
The documentation in `doc/` is in Spanish.

## Credits

This core stands on the work of many people. Thank you all.

**Code used in the core**

- **T80** Z80 core: Daniel Wallner, with later fixes by Sorgelig and the
  MiST/MiSTer community. BSD-style license.
- **T400** COP400 core: Arnim Läuger (https://github.com/devsaurus/t400).
  BSD 3-clause license. Converted to Verilog for this project.
- **MiST modules** (`user_io`, `data_io`, `mist_video`, OSD, scandoubler and
  related): Till Harbaum, Gyorgy Szombathelyi (gyurco) and the MiST
  community. GPL v3 or later.
- **u765** uPD765 floppy controller: Gyorgy Szombathelyi (gyurco), from
  Amstrad_MiST. GPL v2 or later.
- Delta-sigma DAC: based on Xilinx application note XAPP154.

**References and inspiration**

- **MAME** NewBrain driver and COP400 core (Curt Coder and the MAME team,
  BSD 3-clause). The Python COP420 model and disassembler used in the tools
  are ported from MAME's COP400 core.
- **NewBrain Emulator** by Chris Despoinidis (**CDesp**), and his
  ModNewbrain project: an invaluable reference for the memory map, paging
  and disk system (https://newbrainemu.eu/).
- Amstrad core by gyurco (MiST and Poseidon project templates, phosphor
  colours) and
  Oric core by rampa069 (SiDi board structure).
- Documentation: *The NewBrain Dissected*, the Grundy service manuals and
  technical notes, the Tradecom *Expansion & Disk Controller Manual* and the
  *Software Technical Manual*.
- beepgenerator, for the tape format (author unknown; if you are the
  author, please get in touch so we can credit you).

**Tools**

- The co-simulation tools use the Python `z80` package by Ivan Kosarev
  (MIT license, not included).
- The Teledisk converter contains an implementation of the LZHUF algorithm
  by Haruyasu Yoshizaki and Haruhiko Okumura.

## Thanks

To the **Retro-Wiki FPGA-dev Team**, especially **Ron, Manuel (teiram), Somhi,
Roderick, Rampa, Kyp and Benito**, for their help and patience.

To **Turri (turri21)**, thanks for the Z80 CPU fix and for the port to Senhor!

To **https://newbrainemu.eu/**, and especially to **CDesp**, for keeping the
NewBrain alive and for all the knowledge collected there.

## AI assistance and resources

Parts of this core were developed with the assistance of Claude (Anthropic),
used for code, testbenches, co-simulation and documentation. Access to Claude
was provided by Advanced Computer Trading, S.L. (actsl.com), which also
authorises the publication of this work under the license below. All design
decisions, integration, testing on real hardware and final review were
carried out by the author, Shaeon (Carlos Palmero).

## License

Copyright (C) 2026 Shaeon (Carlos Palmero).

This program is free software: you can redistribute it and/or modify it
under the terms of the **GNU General Public License** as published by the
Free Software Foundation, either **version 3** of the License, or (at your
option) any later version. See [LICENSE](LICENSE).

Version 3 is required because some of the included modules (the MiST
modules) are licensed under GPL v3 or later. Third-party files keep their
own copyright notices and licenses, which are compatible with the GPL v3.

## Disclaimer

This project is provided **"as is", without warranty of any kind**, express
or implied, including but not limited to the warranties of merchantability
and fitness for a particular purpose. In no event shall the authors or
contributors be liable for any claim, damages or other liability arising
from the use of this software, of the hardware it runs on, or of any
connected equipment. Use it at your own risk.

NewBrain is a trademark of its respective owners. This project is not
affiliated with or endorsed by them.
