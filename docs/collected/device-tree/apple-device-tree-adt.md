---
title: Apple Device Tree (ADT) Structure
derived-from:
  - docs/external/Asahi Linux Docs/docs/fw/adt.md
project-relevance:
  Emulator must generate or pass through a compatible ADT for the guest OS to discover hardware.
confidence: high
---

## Extracted Facts

### Structure
- Hierarchy of nodes with untyped byte array properties.
- **Byte Order**: Properties are untyped; endianness is implicitly defined by the reader/producer (mixed). This differs from Linux DT (always Big Endian).
- format is "very similar to, but different from" Open Firmware standard.

### Content
- Describes available hardware.
- Includes identifying info (Serial Numbers).
- Includes secret info (WiFi keys).
- Passed by firmware to kernel in binary format.

### Mappings
- `DeviceTree` binary is memory mapped:
    - `/chosen/memory-map.DeviceTree` in the boot description.
- Can be extracted/viewed via:
    - m1n1 `adt.py`.
    - macOS `ioreg -p IODeviceTree`.
    - Preboot volume `DeviceTree.{model}.im4p` (needs `img4tool` to extract).

## Explicit Non-Facts / Unknowns
- Exact binary format spec (headers, node structure) is not detailed in the text, only how to extract it.
- "Missing details filled in by iBoot during boot" - The file on disk (`.im4p`) is NOT the final ADT passed to kernel.

## Notes for Future Phases
- We cannot simply pass a static `.im4p` extracted file; the emulator likely needs to modify it (dynamically fill details) or generate one.
- Requires a parser/builder for the ADT binary format (project likely needs an ADT library).