---
title: SoC Address Map (Memory Map)
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/soc/memmap.md
project-relevance:
  Defines the physical memory layout the emulator must implement.
confidence: high
---

## Extracted Facts

### M1 (T8103) Layout

| Region | Start Address | Size | Description |
| :--- | :--- | :--- | :--- |
| **DRAM** | `0x8_0000_0000` | 8/16 GB | Main Memory |
| **USB-C I2C** | `0x2_3501_0000` | 16 KB | I2C0 (Type C) |
| **Speaker I2C** | `0x2_3501_4000` | 16 KB | I2C1 |
| **Audio I2C** | `0x2_3501_8000` | 16 KB | I2C2 |
| **UART0** | `0x2_3520_0000` | 16 KB | Debug Console |
| **UART2** | `0x2_3520_8000` | 16 KB | WLAN Debug |
| **AIC** | `0x2_3b10_0000` | 48 KB | Interrupt Controller |
| **PMGR** | `0x2_3b70_0000` | 1 MB | Power Manager |
| **GPIO** | `0x2_3c10_0000` | 1 MB | GPIO Controller |
| **WDT** | `0x2_3d2b_0000` | 16 KB | Watchdog Timer |
| **SMC CPU** | `0x2_3e00_0000` | 5 MB | SMC Area? (Ref `23e000000` SMC_CPU) |
| **Spin-Tables**| `0x2_1005_0000` | -- | CPU Implementation Registers (E-Core Cluster) |
| **Spin-Tables**| `0x2_1105_0000` | -- | CPU Implementation Registers (P-Core Cluster) |

### Probing Notes
- Various MMIO ranges respond to probe reads (listed in source `MMIO ranges` table).
- Power domains in PMGR often need to be enabled before MMIO is accessible.

## Explicit Non-Facts / Unknowns
- "Incomplete" explicitly stated in source.
- Exact sizes of some regions differ between ADT and RE ("size probably wrong in adt").
- CPU Implementation Register offsets are approximated (`10x50000`).

## Notes for Future Phases
- Emulator must handle Access Faults for unmapped regions (SERror or ignore).
- Critical to map AIC and UART addresses correctly.
