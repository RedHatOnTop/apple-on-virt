---
title: Security Extensions (SPRR & GXF)
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/cpu/sprr-gxf.md
project-relevance:
  Emulator needs to support or mask these features if the guest OS attempts to enable them.
confidence: high
---

## Extracted Facts

### GXF (Guarded Execution Framework)
- Lateral exception levels: GL1 (next to EL1) and GL2 (next to EL2).
- Enabled via bit 1 in `S3_6_C15_1_2`.
- Uses same page tables as ELx but different permissions (via SPRR).
- **Registers**:
    - Has own set of ELR, FAR, ESR, SPSR, VBAR, TPIDR (`SYS_xxx_GL1`).
    - `SYS_ASPSR_GL1`: Indicates if `gexit` returns to GL or EL.

### SPRR (Silicon Permission Reroll/Remap?)
- Remaps standard page table permissions (AP, UXN, PXN) into a 4-bit index.
- **Mechanism**:
    1.  Convert PT bits (AP[1:0], UXN, PXN) to 4-bit index. (Note: UXN/PXN flipped compared to APRR).
    2.  Index looks up entry in `SYS_SPRR_PERM_ELx`.
    3.  Entry contains 4 bits: `GL[1:0]` and `EL[1:0]`.
    4.  Result defines actual R/W/X permissions for EL and GL modes.
- **Registers**:
    - `SYS_SPRR_CONFIG_EL1` (`S3_6_C15_1_0`): Enable [0], Lock Config [1], Lock Perms [4,5].
    - `SYS_SPRR_PERM_EL0`: Permissions for EL0.
    - `SYS_SPRR_PERM_EL1`: Permissions for EL1/GL1.

## Explicit Non-Facts / Unknowns
- "Some of these are guesses" (Glossary/general caveat).

## Notes for Future Phases
- If emulator supports EL1/EL0, it may need to implement SPRR permission checks if the OS enables it.
- GXF `genter`/`gexit` flow control must be handled if GL execution is supported.
