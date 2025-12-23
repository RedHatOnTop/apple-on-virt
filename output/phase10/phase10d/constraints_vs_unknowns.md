# Phase 10d — Constraints vs Unknowns

## Proven constraints (static)
### Kernelcache artifact (Phase 10a)
- Entry metadata exists (`LC_UNIXTHREAD`):
  - `entry_pc = 0xfffffe0007d44528` (see `output/phase10/phase10a/summary.txt`)
- Entry is within `__TEXT_EXEC` (same summary).
- Segment VM layout is a contiguous high-VA span:
  - `min_va = 0xfffffe0007004000`
  - `max_va = 0xfffffe000d0cc000`

### Boot-chain (iBoot vma2) static facts (Phase 10c + Phase 10d excerpts)
- Kernelcache path strings are used and referenced in code:
  - `0x00002b6c` (system kernelcache path)
  - `0x00002ee4` (boot kernelcache path)
- Placement arithmetic includes:
  - 16KB alignment mask (`0xffffffffffffc000`) at `0x000089d8` and `0x00008acc`.
  - 2MB granule start (`0x200000`) and doubling loop (`0x000089e8..0x000089f8`).
  - bounds check vs `x25` (`0x00008ae0..0x00008ae4`).
- A delta is stored globally:
  - `0x00008b5c: sub x8, x8, x26`
  - `0x00008b64: str x8, [x9, #0x218]`
- An EL1-context restore + `eret` primitive exists:
  - loads ELR_EL1 from `[sp+#0x108]` then `eret` at `0x000101f4`.

## Unproven assumptions (do not treat as facts)
- That the stored delta is *specifically* the kernel slide.
- That the EL1 `eret` restore routine is the final boot→kernel transfer.
- That the kernel entry is used directly from `LC_UNIXTHREAD` vs rebased.

## Explicit unknowns (cannot be proven from current artifacts)
- `kernel_entry_runtime_va` computation at the true handoff boundary.
- Register roles at kernel entry (x0–xN semantics) and SP value.
- Whether and where dyld chained fixups are applied to the kernelcache by iBoot.
- Exact MMU/TTBR/TCR values in effect at kernel entry.

## Phase 10d classification
**B) Entry contract partially reconstructible, boot-feasible with constraints.**
