# Phase 6b: Exception and Vector Expectations Observation

## Goal
Observe how early OS-side code expects exception vectors to be configured and used during the pre-/during-MMU-enable window.

This phase is **observation only**:
- No exception handlers were implemented.
- No vector behavior was changed.
- Only **logging** was added for VBAR writes and for the active VBAR at exception entry.

## Test setup
- QEMU: `emulator/qemu-apple-silicon/build/qemu-system-apple64e`
- Machine: `-M apple-silicon-bringup`
- DTB: `output/minimal_adt_with_placeholders.bin`
- iBoot surrogate / handoff: `output/phase5f_handoff.bin`
- Phase 6b probe payload:
  - Source: `scripts/phase6/phase6b_exception_probe.s`
  - Binary: `output/phase6/phase6b_exception_probe.bin`

Evidence logs:
- `output/phase6/phase6b_run1.qemu.log`
- `output/phase6/phase6b_run2.qemu.log`
- `output/phase6/phase6b_run3.qemu.log`

## Timeline of exception-related actions
All addresses below are guest PCs.

### 0) OS-side vector base configuration attempt
First observed write (run1; same in run2/run3):
- **PC:** `0x801000024`
- **Write:** `VBAR_EL1 = 0x0000000080100200`
- Log line (example):
  - `Phase6b: MSR VBAR_EL1 value=0x80100200 pc=0x801000024 EL=3`

### 1) MMU-enable sequence begins (context)
The probe then performs the Phase 6a-observed MMU sysreg writes (TTBR/TCR/MAIR/SCTLR). These remain **stubbed RAZ/WI** per Phase 5e, but are logged.

### 2) First synchronous abort (primary exception path)
Immediately after MMU-related actions, the probe triggers a load from a high VA (`0xffff000000000000`).

Observed (run1; same in run2/run3):
- **Exception type:** synchronous abort (logged as **Data Abort**)
- **Current EL at exception time:** `EL3` (log: `...from EL3 to EL3`)
- **ELR:** `0x801000064`
- **FAR:** `0xffff000000000000`
- **ESR:** `0x25/0x96000000`
- **Vector base used at exception time:** `VBAR_EL3 = 0x0`
- **Vector target PC:** `0x200` (log: `...to EL3 PC 0x200`)

Example excerpt (run1):
- `Taking exception 4 [Data Abort] on CPU 0`
- `...from EL3 to EL3`
- `...with ESR 0x25/0x96000000`
- `...with VBAR_EL3 0x0`
- `...with FAR 0xffff000000000000`
- `...with ELR 0x801000064`
- `...to EL3 PC 0x200 PSTATE 0x3cd`

### 3) Follow-on exception behavior (secondary path)
After vectoring to `PC=0x200`, repeated **Prefetch Abort** exceptions occur while trying to fetch/execute at `0x200`:
- Exception: `Taking exception 3 [Prefetch Abort]`
- `...with FAR 0x200`
- `...with ELR 0x200`
- `...with VBAR_EL3 0x0`
- `...to EL3 PC 0x200`

## OS expectations (inferred; clearly marked assumptions)
**Assumption A (supported by log evidence):** OS-side code expects to install an EL1 exception vector early via `MSR VBAR_EL1, <addr>`.
- Evidence: the first observed vector-related write is to **VBAR_EL1**.

**Assumption B (supported by exception logs):** OS-side code expects exceptions to be delivered at **EL1**, but the current execution/exception level is **EL3** in this bring-up environment.
- Evidence: exception log shows `...from EL3 to EL3` and the vector base used is **VBAR_EL3**, not VBAR_EL1.

**Assumption C (supported by vector target + base):** the active exception vectors are taken from `VBAR_EL3` (currently `0x0`), producing a vector target of `0x200` (base `0x0` + offset).

## Repeatability
Across the three runs, the *semantic failure point* is stable:
- First `VBAR_EL1` write remains at `PC=0x801000024`.
- First abort remains a **Data Abort** with `ELR=0x801000064` and `FAR=0xffff000000000000`.
- Vectoring remains to **EL3 PC=0x200** with **VBAR_EL3=0x0**.

(Note: full log-file hashes differ due to differing log length/content beyond the first failure, but the key markers above match.)
