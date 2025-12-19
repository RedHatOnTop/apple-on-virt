---
title: Watchdog Timer (WDT)
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/soc/wdt.md
project-relevance:
  Emulator must implement WDT to prevent guest from rebooting unexpectedly (or to support reboot requests).
confidence: high
---

## Extracted Facts

### Specifications
- **Base Address**: `0x2_3d2b_0000` (on M1).
- **Clock**: 24 MHz.
- **Width**: 32-bit (wraps in ~3 mins).

### Registers (Offsets from Base)
- `+0x10`: Timer Count (Read).
- `+0x14`: Compare Value (Read/Write). Default 120s (`0xAD3...`?).
- `+0x1c`: Control.
    - Write `4`: Enable.
    - Write `0`: Disable.
    - Bit `0x04`: Reboot Enable (triggers reboot when Count >= Compare).

### Recovery Mode WDT
- Additional registers at `+0x20` / `+0x24` / `+0x2c`.
- Trigger reboot into Recovery Mode instead of normal reboot.

## Explicit Non-Facts / Unknowns
- Exact value of default 120s in ticks (24MHz * 120 = 2,880,000,000 > 2^32? No, 2.88e9 < 4.29e9. Fits).

## Notes for Future Phases
- Implement simple counter incrementing at 24MHz (virtual time).
- Handling "Control bit 0x04" is the trigger mechanism.
