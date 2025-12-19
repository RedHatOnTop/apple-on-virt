# Phase 5a Report: Memory Contract

## Scope
This phase implements the minimal memory/address-space behavior required to avoid memory-map related failures.

## Final Memory Map (guest physical)

| Region | Base | Size | Notes |
|---|---:|---:|---|
| DRAM | `0x0000_0008_0000_0000` | `0x1000_0000` (256MB) | Single RAM region (`apple.ram`) |
| DT blob (ADT bytes) | `0x0000_0008_0000_0000` | `<= 0x0001_0000` (64KB reserved) | Loaded via `-dtb` into DRAM |
| Boot payload | `0x0000_0008_0010_0000` | (file size) | Loaded via `-kernel` as raw bytes |
| Unmapped | everything else | N/A | Access logs as rejected (see evidence) |

Non-overlap guarantee: DRAM is at `0x8_0000_0000+`, while the documented MMIO window (not mapped in QEMU) is `0x2000_0000..0x3FFF_FFFF`.

## Changes Made (minimal)

### 1) DRAM base/size moved to required contract
* File: `emulator/qemu-apple-silicon/hw/apple/platform/platform_state.h`
  * `APPLE_DRAM_BASE = 0x800000000`
  * `APPLE_DRAM_SIZE = 0x10000000` (256MB)

### 2) DT blob loading path (opaque bytes)
* File: `emulator/qemu-apple-silicon/hw/apple/apple_machine.c`
  * If `-dtb <file>` is provided, it is loaded verbatim at `APPLE_DT_BASE` using `load_image_targphys()`.
  * This is used to place the Phase 4 ADT binary without modifying ADT format.

### 3) Minimal ADT updated with `/memory.reg`
* File: `scripts/phase4/minimal_adt_gen.py`
  * New option `--with-memory-reg` produces an ADT that includes:
    * Root: `#address-cells = <2>` and `#size-cells = <2>` (u32 LE)
    * `/memory`: `reg` encoded as 4x u32 LE cells: `[addr_lo, addr_hi, size_lo, size_hi]`
* Output artifact used in tests: `output/minimal_adt_with_memory.bin`

## Evidence (logs)

### Test A: DRAM exists at `0x8_0000_0000` and is R/W
Command:
```
qemu-system-aarch64 \
  -M apple-silicon-bringup -m 256M \
  -nographic -monitor none -serial none \
  -dtb output/minimal_adt_with_memory.bin \
  -kernel output/phase5a_memtest_apple.bin \
  -d cpu,guest_errors
```
Key log lines:
```
Device Tree (X0): 0x800000000
Entry Point (PC): 0x800100000
...
X20=000000000001beef
```
Interpretation for this phase: `X20=0x0001BEEF` is the in-payload marker for successful write/read at `0x8_0000_0000`.

### Test B: Unmapped accesses fail gracefully
Command:
```
qemu-system-aarch64 \
  -M apple-silicon-bringup -m 256M \
  -nographic -monitor none -serial none \
  -dtb output/minimal_adt_with_memory.bin \
  -kernel output/phase5a_unmapped.bin \
  -d guest_errors,cpu
```
Key log lines:
```
Invalid read at addr 0x900000000, size 8, region '(null)', reason: rejected
```
This demonstrates a deterministic, logged failure on access to an unmapped region.

## Why Phase 5a is complete
* DRAM is mapped at the required base `0x8_0000_0000`.
* DRAM size is consistent (`256MB`) and exposed via `/memory.reg` in the ADT blob placed at `X0`.
* There is no MMIO region overlapping DRAM.
* Accesses to unmapped regions are rejected and logged.

Next failures after this point (e.g., exception-vector behavior at low addresses) are not memory-map contract issues.
