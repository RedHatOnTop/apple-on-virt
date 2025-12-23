# Phase 9f: Kernel Entry Metadata vs Emulator Reality (Non-Execution Alignment Check)

## Scope
Alignment check only (no execution).
- No QEMU runs.
- No jumping to entry PC.
- No MMU/VA acceptance changes.
- No boot-chain changes.

## Inputs (from Phase 9e; not regenerated)
- Decompressed kernelcache (ignored path):
  - `local_storage/ipsw/extracted_phase9e/kernelcache.release.mac13g.decompressed`
- Proven Mach-O type: `MH_FILESET` (filetype=12)
- Proven entry metadata source: `LC_UNIXTHREAD`

## Step 1 — Mach-O VM layout observation
Segment/entry evidence was produced by offline parsing (saved log):
- `output/phase9/phase9f/segments_and_entry.txt`

### Entry metadata (from bytes)
From `segments_and_entry.txt`:
- `entry_pc=0xfffffe0007d44528`
- `entry_in_segment=('__TEXT_EXEC', 0xfffffe0007c70000, 0x2f60000, 0xd44528-0xc70000 = 0xd44528?)` (see exact tuple in file)

### Segment table (from bytes)
From `segments_and_entry.txt`:
| Segment | vmaddr | vmsize | init/max prot |
|---|---:|---:|---|
| __TEXT | 0xfffffe0007004000 | 0x0000000000008000 | R / R |
| __PRELINK_TEXT | 0xfffffe000700c000 | 0x0000000000c64000 | R / R |
| __TEXT_EXEC | 0xfffffe0007c70000 | 0x0000000002f60000 | RX / RX |
| __DATA_CONST | 0xfffffe000abd0000 | 0x0000000000bc0000 | R / R |
| __PRELINK_INFO | 0xfffffe000b790000 | 0x00000000002d0000 | RW / RW |
| __DATA | 0xfffffe000ba60000 | 0x0000000000744000 | RW / RW |
| __LINKEDIT | 0xfffffe000c1a4000 | 0x0000000000f28000 | R / R |

**Conclusion (Step 1):** The entry PC **does** lie within a declared VM segment: `__TEXT_EXEC`.

## Step 2 — Emulator alignment comparison
### Emulator memory constants (from source)
From `emulator/qemu-apple-silicon/hw/apple/platform/platform_state.h`:
- `APPLE_DRAM_BASE = 0x800000000`
- `APPLE_DRAM_SIZE = 0x10000000` (256MB)
- `APPLE_KERNEL_BASE = APPLE_DRAM_BASE + 0x01000000 = 0x801000000`

### Phase 8 accepted VA windows (from docs)
From `docs/phase8/phase8a-mmu-acceptance.md`:
1) High VA window:
- `VA: 0xffff_0000_0000_0000 .. 0xffff_ffff_ffff_ffff`
- `PA: 0x8000_0000_00 + (VA - 0xffff_0000_0000_0000)`
- **bounded to DRAM size (256MB)**

2) Current execution region:
- `VA: 0x8000_0000_00 .. 0x8000_0000_00 + 256MB` (identity)

### Phase 8 acceptance implementation (proves the bound)
From `emulator/qemu-apple-silicon/target/arm/tcg/tlb_helper.c`:
- `HIGH_BASE = 0xffff000000000000ULL`
- `DRAM_SIZE = 0x10000000ULL`
- High-VA acceptance requires: `off = va - HIGH_BASE; off < DRAM_SIZE`

### Entry PC vs acceptance windows
Entry PC:
- `entry_pc = 0xfffffe0007d44528`

It is **numerically within** the “high VA window” (`>= 0xffff000000000000`), but the acceptance mapping is bounded by `off < DRAM_SIZE`.

Computed offset (evidence from calculation):
- `off = entry_pc - HIGH_BASE = 0xfe0007d44528`
- `DRAM_SIZE = 0x10000000`
- `off < DRAM_SIZE` is **false**

Therefore:
- Entry PC is **NOT** within the *accepted* portion of the high-VA mapping (it would not translate via the Phase 8 acceptance rule as implemented).
- Entry PC is also **NOT** within the “current execution region” (`0x800000000..0x810000000`).

## Step 3 — Classification
**B) Entry PC lies within a kernel VM segment BUT outside acceptance.**

Evidence summary:
- Entry PC is inside `__TEXT_EXEC` (segment table + `entry_in_segment=...`).
- Phase 8 acceptance for high-VA is bounded by `off < 0x10000000` (code).
- Entry PC’s offset from `HIGH_BASE` is `0xfe0007d44528`, far exceeding `0x10000000`.

## Explicit UNKNOWNs (do not guess)
- Whether the emulator’s non-MMU execution path would reach any of these addresses without additional boot-chain setup.
- Whether other Mach-O fileset entries imply additional indirections at runtime (not analyzed here beyond segment listing).

## Statement on theoretical plausibility (non-execution)
Given only the established Phase 8 acceptance behavior, the kernel’s entry PC VM address range **does not structurally align** with the accepted translation window (bounded 256MB window from `0xffff000000000000`).
This is an observation about address-range alignment only; it does not propose fixes or execute code.
