---
title: UART Debugging
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/soc/serial-debug.md
  - docs/external/Asahi Linux Docs/docs/hw/soc/memmap.md
project-relevance:
  Emulator needs to provide a UART at the correct address for early boot logging (guest console).
confidence: high
---

## Extracted Facts

### Hardware
- **UART0**: Debug Console.
- **Base Address**: `0x2_3520_0000` (T8103/M1).
- **Physical Interface**: USB-C SBU pins (1.2V logic), requires USB-PD VDM commands to enable on real hardware.

### Emulator Implementation
- Address: `0x235200000`.
- Type: Compatible with Samsung S5L / "Apple S5L" (from memmap I2C name, implied similar IP style) or standard-ish UART used by m1n1.
- m1n1 uses this port for output.

## Explicit Non-Facts / Unknowns
- Detailed register map for UART is not in `serial-debug.md` (which focuses on cabling).
- Compatibility with PL011 or 16550 is not stated (usually Apple UARTs are samsung-variant style).

## Notes for Future Phases
- Map a UART device at `0x2_3520_0000`.
- Check m1n1 source (if available later) for exact register offsets (TX/RX/Status), or assume standard Apple/Samsung offsets if known from other docs (none here).
