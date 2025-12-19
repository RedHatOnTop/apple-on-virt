---
title: Hardware Quirks & Constraints
derived-from:
  - docs/external/Asahi Linux Docs/docs/platform/quirks.md
  - docs/external/Asahi Linux Docs/docs/platform/stock-partition-layout.md
project-relevance:
  Emulator limitations and environment expectations for guests.
confidence: high
---

## Extracted Facts

### UEFI / Firmware
- **No Native UEFI**: Platform uses iBoot. UEFI (U-Boot) is a second-stage bridge.
- **No UEFI Variables**: Hardware has no store for them. U-Boot simulates them or relies on defaults.
- **Multiple ESPs**:
    - **System ESP**: Internal NVMe, contains U-Boot, m1n1 stage 2, vendor firewall.
    - **OS ESP**: Where OS bootloader lives (e.g. `/boot/efi`).
- **Firmware Loading**:
    - **System-Global**: Loaded by iBoot (from `iSCPreboot`?).
    - **OS-Paired**: Installed in Stub APFS, loaded by iBoot.
    - **Extracted**: `vendorfw.cpio` in System ESP, loaded by U-Boot/Linux into RAM.

### Partitioning
- **GPT Support**: Yes.
- **Containers**:
    1.  `iBoot System Container` (Config, Policies, Stage 1 FW).
    2.  `OS Container` (macOS, Asahi Stub).
    3.  `Recovery Container`.

### Boot Limits
- Only ONE OS can "own" the System ESP (m1n1 stage 2).
- Mismatched Device Trees (from System ESP) and Kernels (from OS ESP) can break boot.

## Explicit Non-Facts / Unknowns
- "Future features, like SEP support... may further depend on this pairing".

## Notes for Future Phases
- Emulator file system image should respect the multiple-ESP structure if emulating the full Asahi boot chain.
- If emulating raw kernel boot, these constraints are bypassed, but guest expectations (like finding `vendorfw.cpio`) must be met.
