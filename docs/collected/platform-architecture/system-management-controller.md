---
title: System Management Controller (SMC)
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/soc/smc.md
project-relevance:
  Emulator needs to handle SMC mailbox commands to avoid guest hangs/panics (e.g. reading battery or lid status).
confidence: high
---

## Extracted Facts

### Role
- Handles temperature, voltage, battery, fans, lid switch, GPIOs.
- "documented" only by Linux driver RE.
- Accesses via Mailbox protocol(?).

### Protocol
- **Keys**: 4-character ASCII codes (e.g., `SBAV`, `B0RM`).
- **Data Types**: `flt` (float), `ui8`/`ui16`/`ui32`/`ui64`, `si*` (signed), `ch8*` (string).
- **Operations**:
    1. Read Key Info.
    2. Read Key Data.
    3. Write Key Data.

### Known Keys (Examples)
- `RPlt`: Platform name (e.g., "J293").
- `B0RM`: Battery Remaining (mAh).
- `SBAV`: Battery Voltage (mV).
- `MSLD`: Lid Switch (1=Closed, 0=Open).
- `CLBT`: Boot time.
- `aDC*`: ADC channels.

### Quirks
- `gP??` GPIO access has latching weirdness.
- Some keys reversed byte order.

## Explicit Non-Facts / Unknowns
- Thousands (1400+) keys exist, most unknown.
- Exact MMIO mailbox address/interrupt mechanism not detailed here (drivers source linked).

## Notes for Future Phases
- Stubbing mechanism: Allow generic Read/Write to arbitrary 4-char keys.
- Return logical defaults (e.g. Lid Open, Battery 100%) to specific known keys if guest blocks on them.
