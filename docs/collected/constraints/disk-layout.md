---
title: Stock Disk Partition Layout
derived-from:
  - docs/external/Asahi Linux Docs/docs/platform/stock-partition-layout.md
project-relevance:
  Reference for creating compatible disk images for the emulator.
confidence: high
---

## Extracted Facts

### Partition Table (GPT)
- **disk0s1** (index 1): iBoot System Container (`Apple_APFS_ISC`).
- **disk0s2** (index 2): OS Container (`Apple_APFS`).
- **disk0s3** (index 3): Recovery OS (`Apple_APFS_Recovery`).

### iBoot System Container (disk0s1)
- Subvolumes:
    - `iSCPreboot` (Role: Preboot): Boot policies (`LocalPolicy/*.img4`), Firmware versions.
    - `xART` (Role: xART): SEP trusted storage.
    - `Hardware` (Role: Hardware): Logs, Factory Data.
    - `Recovery`: Empty.

### OS Container (disk0s2)
- Subvolumes (macOS Standard):
    - `System` (Macintosh HD): Sealed root.
    - `Preboot`: iBoot2 (OS Loader), Kernel Cache, Device Tree.
        - Path: `/(Data UUID)/boot/(Hash)/usr/standalone/firmware/iBoot.img4`.
    - `Recovery`: Paired RecoveryOS.
    - `Data`: User data.
    - `VM`: Swap.

### Boot Discovery
- Stage 1 (iBoot1) looks in `disk0s1` (iSCPreboot) for Local Policy.
- Policy points to `Preboot` volume in `disk0s2` (OS Container) to load Stage 2.

## Explicit Non-Facts / Unknowns
- Exact binary contents of `xART` or `FactoryData` are dynamic/device-specific.

## Notes for Future Phases
- To boot a guest via iBoot flow, emulator storage must replicate this APFS container structure.
- `iSCPreboot` is critical for the boot chain startup.
