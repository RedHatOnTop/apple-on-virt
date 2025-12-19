# Phase 3a Observation Setup

**Date**: 2025-12-18  
**Purpose**: Extract and test real iBoot binary

## Available IPSW Files

1. `UniversalMac_11.0.1_20B29_Restore.ipsw` (macOS 11.0.1 Big Sur)
2. `UniversalMac_12.1_21C52_Restore.ipsw` (macOS 12.1 Monterey)

## Extraction Process

IPSW files are ZIP archives containing:
- iBoot firmware
- Device Tree files
- Kernelcache
- Other system files

Target: Extract iBoot binary for observation testing.

## Observation Goals

1. Determine where iBoot expects DRAM
2. Determine if iBoot reads FDT or ADT
3. Identify first MMIO accesses
4. Identify earliest fatal failure

## Test Configuration

- Emulator: qemu-system-apple64e
- Machine: apple-silicon-bringup
- Current DRAM: 0x40000000 (Phase 2 configuration)
- Current DT: 0x40000000 (FDT format)

## Hypotheses to Test

1. H1: iBoot expects DRAM at 0x8_0000_0000 (per documentation)
2. H2: iBoot expects ADT format, not FDT
3. H3: iBoot will access AIC registers early
4. H4: iBoot will access UART for output
