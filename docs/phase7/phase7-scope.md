# Phase 7 Scope (PRE): Boot-chain and Execution-Environment Research

## 1) Purpose of Phase 7
Phase 7 exists to explore and explicitly model **boot-chain / execution-environment assumptions** that the OS expects (as observed in Phase 6), without claiming any additional Phase 5 hardware responsibility.

Phase 7 is **not** “making the OS boot.” It is controlled research to answer:
- What execution environment (EL, vectors, PSCI conduit, MMU expectations) does the OS *assume* at the kernel initialization boundary?
- Which minimal, explicitly-declared *boot-chain scaffolding* is required to reproduce those assumptions?

## 2) What Phase 7 intentionally violates (relative to the current bring-up environment)
Phase 6 observed an EL/vector mismatch (exceptions taken at EL3 with `VBAR_EL3=0x0`, while OS attempts `VBAR_EL1`). Phase 7 may introduce **shims** that deliberately alter the execution environment to match expected boot conditions.

Phase 7 MAY intentionally change (explicitly and transparently):
- **Execution level / entry mode** (eg ensuring kernel entry at EL1 instead of EL3)
- **Exception vector base configuration** (eg setting a synthetic vector base, or installing minimal vector stubs)
- **PSCI conduit behavior** (eg explicit emulation of “firmware provides PSCI via HVC/SMC” as scaffolding)
- **Boot-time register preconditioning** (eg SCR/HCR/SPSR/DAIF state), but only as part of a declared boot-chain shim

All such changes must be labeled as **boot-chain simulation**, not “hardware emulation.”

## 3) What remains fixed from Phase 5 (immutable contract)
Phase 7 MUST treat Phase 5 as immutable. In particular, Phase 7 MUST NOT:
- Add or change devices
- Change MMIO mappings
- Change the ADT blob or boot_args contract
- Add sysreg *feature* implementations as hardware devices
- Claim missing Phase 5 hardware responsibility

Phase 7 assumes the Phase 5 contract remains the stable baseline:
- DRAM mapping is valid
- UART output exists
- Monotonic timer exists
- AIC exists (existence-only)
- Sysreg sanity stubs (RAZ/WI) remain the safety baseline unless explicitly superseded by a boot-chain shim
- ADT delivery and boot_args handoff remain unchanged

## 4) Success and failure definitions
### Success (Phase 7)
Phase 7 is successful if it:
- Produces a clear, evidence-backed description of **which boot-chain conditions** are required for kernel initialization to proceed past the Phase 6 boundary
- Demonstrates (via logs) that the OS progresses further *because the execution environment matches expectations*, not because new hardware exists

### Failure (Phase 7)
Phase 7 is considered failed/invalid if it:
- Modifies or weakens any Phase 5 hardware contract
- Reinterprets Phase 6 conclusions to imply new hardware responsibility
- Introduces unbounded “best-effort” hardware growth under the label of boot-chain work

## 5) Optionality and safe abandonment
**Phase 7 success is OPTIONAL.**

Phase 7 may be safely abandoned at any time if:
- The required execution-environment shims become too invasive to remain honest “boot-chain simulation”
- The OS still fails for reasons that clearly require a full MMU/exception subsystem implementation (out of project scope)
- The resulting environment diverges too far from the project’s single-purpose identity

In all abandonment cases, Phase 5 and Phase 6 remain correct and closed; Phase 7 does not retroactively change their verdicts.
