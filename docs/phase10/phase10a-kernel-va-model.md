# Phase 10a: Kernel Virtual Address Space Model Reconstruction (Observation Only)

## Evidence inputs (local, no execution)
Artifacts used (no regeneration, no execution):
- Decompressed kernelcache (MH_FILESET, arm64e):
  - `local_storage/ipsw/extracted_phase9e/kernelcache.release.mac13g.decompressed` *(git-ignored)*
- Extracted segment/entry metadata (generated offline in this phase):
  - `output/phase10/phase10a/summary.txt`
  - `output/phase10/phase10a/segments.csv`

Emulator reference (read-only source):
- `emulator/qemu-apple-silicon/hw/apple/platform/platform_state.h`
- Phase 8 acceptance description + implementation:
  - `docs/phase8/phase8a-mmu-acceptance.md`
  - `emulator/qemu-apple-silicon/target/arm/tcg/tlb_helper.c`

No QEMU runs were performed for this phase.

---

## 1) Kernel VA distribution mapping (segments)
From `output/phase10/phase10a/segments.csv` (sorted by `vmaddr`), the kernel fileset’s Mach-O `LC_SEGMENT_64` regions form a **single contiguous high-VA span**:

**Overall span (from `summary.txt`):**
- `min_va = 0xfffffe0007004000`
- `max_va = 0xfffffe000d0cc000`
- `va_span = 0x060c8000` bytes (`101,482,496` bytes)

### Segment table (vmaddr ranges)
| Segment | vmaddr | vmend | vmsize | init prot |
|---|---:|---:|---:|---|
| __TEXT | 0xfffffe0007004000 | 0xfffffe000700c000 | 0x00008000 | R-- |
| __PRELINK_TEXT | 0xfffffe000700c000 | 0xfffffe0007c70000 | 0x00c64000 | R-- |
| __TEXT_EXEC | 0xfffffe0007c70000 | 0xfffffe000abd0000 | 0x02f60000 | R-X |
| __DATA_CONST | 0xfffffe000abd0000 | 0xfffffe000b790000 | 0x00bc0000 | R-- |
| __PRELINK_INFO | 0xfffffe000b790000 | 0xfffffe000ba60000 | 0x002d0000 | RW- |
| __DATA | 0xfffffe000ba60000 | 0xfffffe000c1a4000 | 0x00744000 | RW- |
| __LINKEDIT | 0xfffffe000c1a4000 | 0xfffffe000d0cc000 | 0x00f28000 | R-- |

**Contiguity check (evidence-backed):** each `vmend` equals the next segment’s `vmaddr` in the table above (no gaps).

### Offsets from HIGH_BASE
Using `HIGH_BASE = 0xffff000000000000` (the Phase 8 high-VA base), the segments sit at large positive offsets (from `segments.csv`, `vmaddr_minus_high_base` column):
- `__TEXT` starts at `0xfe0007004000` above `HIGH_BASE`
- `__LINKEDIT` starts at `0xfe000c1a4000` above `HIGH_BASE`

This is a *numeric* statement only (no implied mapping).

---

## 2) Entry PC contextualization (numeric only)
From `output/phase10/phase10a/summary.txt`:
- `entry_pc = 0xfffffe0007d44528`
- `entry_in = ('__TEXT_EXEC', 869672)`

So:
- Entry lies inside executable text (`__TEXT_EXEC`).
- Offset within `__TEXT_EXEC` is `0x0d44528` (`869,672` decimal) from that segment’s base.

### Bit pattern / canonical form observations
Entry PC top bytes:
- `entry_pc = 0xfffffe0007d44528`
- High bits are all-ones in the upper region (`0xffff...`), i.e. it is in a sign-extended high address form.

Architectural note (ARM64 generic):
- For common AArch64 VA sizes (e.g., 48-bit or 52-bit), canonical high virtual addresses are represented by sign-extension of the top implemented VA bit into the upper bits.
- This entry address matches the *shape* of a canonical high VA (upper bits all 1), without asserting which VA size is active.

### Distance from Phase 8 HIGH_BASE
Also from `summary.txt`:
- `entry_minus_high_base = 0xfe0007d44528`

This exceeds 256MB by orders of magnitude; this matters only for the Phase 8 acceptance bound comparison (below).

---

## 3) arm64e-specific considerations (evidence-limited)
What is directly evidenced from artifacts:
- `file(1)` previously identified the decompressed kernelcache as `Mach-O 64-bit arm64e` (Phase 9e).
- Segment VM addresses and the entry PC are in the `0xfffffe00_...` region.

What is explicitly **not** proven here:
- Whether Top Byte Ignore (TBI) is in effect for this execution context.
  - The top byte here is `0xff`, which is compatible with both “no tag” and “tag ignored” interpretations.
  - No further claim is made without executing or inspecting live system registers.

---

## 4) Emulator alignment gap (descriptive, non-fix)
### Current emulator + Phase 8 acceptance ranges
From `docs/phase8/phase8a-mmu-acceptance.md` and `target/arm/tcg/tlb_helper.c`:
- `HIGH_BASE = 0xffff000000000000`
- High-VA acceptance is **bounded** to DRAM size (`DRAM_SIZE = 0x10000000`), i.e. accepted only when:
  - `off = VA - HIGH_BASE`
  - `off < 0x10000000` (256MB)

Also accepted (identity):
- `VA in [0x800000000, 0x810000000)` (DRAM base + 256MB)

### Kernel’s observed VA span vs acceptance
Kernel span (from artifacts):
- `[0xfffffe0007004000, 0xfffffe000d0cc000)`

Emulator acceptance (high-VA bounded window):
- `[0xffff000000000000, 0xffff000010000000)` (256MB window only)

**Descriptive mismatch statement:**
- The kernel’s entry + text segments are located in `0xfffffe00_...` VA space, while the emulator currently accepts only a 256MB high-VA window starting at `0xffff0000_0000_0000` (plus the low DRAM identity window).

No fixes are proposed in this phase.

---

## Classification (mandatory)
**B) Kernel VA model exists but depends on additional boot-time relocation inputs.**

Evidence-backed basis:
- The artifact encodes a single internally consistent, contiguous high-VA layout (segment table + entry PC within `__TEXT_EXEC`).
- However, this phase cannot prove whether these absolute VM addresses are the *runtime* addresses “at entry” (versus a relocatable layout that could be placed elsewhere by earlier boot stages), because that would require additional boot-time state that is not present in the artifact metadata alone.

## Explicit STOP boundary / unknowns
This phase stops at “artifact-reconstructible layout”:
- It does **not** infer or guess any relocation/slide amount.
- It does **not** assert which TTBR split, VA size, or TBI configuration is active at runtime.
- It does **not** execute or validate any mapping.
