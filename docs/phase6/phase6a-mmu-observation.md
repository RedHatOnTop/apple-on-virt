# Phase 6a: MMU Transition Observation

## Goal
Observe when OS-side code attempts to configure/enable MMU-related state, and capture the first translation-related failure that follows.

This phase is **observation only**:
- No MMU implementation was added.
- No address translation was enabled by the emulator.
- Only sysreg-write logging was added for the already-stubbed EL1 MMU control path.

## Test setup
- QEMU: `emulator/qemu-apple-silicon/build/qemu-system-apple64e`
- Machine: `-M apple-silicon-bringup`
- DTB: `output/minimal_adt_with_placeholders.bin`
- iBoot surrogate / handoff: `output/phase5f_handoff.bin`
- Phase 6a payload (OS-side probe):
  - Source: `scripts/phase6/phase6a_mmu_probe.s`
  - Binary: `output/phase6/phase6a_mmu_probe.bin`

Evidence logs:
- `output/phase6/phase6a_run2.qemu.log`
- `output/phase6/phase6a_run3.qemu.log`

## Timeline of MMU-related actions (first occurrence)
All addresses below are guest PCs.

### 0) OS code begins executing
- PC `0x801000000`: payload entry (UART marker `M` emitted)

### 1) First MMU-related sysreg write (TTBR)
From `output/phase6/phase6a_run2.qemu.log`:
- **PC:** `0x801000024`
- **Instruction:** `msr ttbr0_el1, x0`
- **Write:** `TTBR0_EL1 = 0x0000000080001000`

### 2) Additional MMU configuration writes (TTBR/TCR/MAIR)
From `output/phase6/phase6a_run2.qemu.log`:
- PC `0x801000028`: `TTBR1_EL1 = 0x0000000080001000`
- PC `0x801000030`: `TCR_EL1 = 0x0000000000003520`
- PC `0x801000044`: `MAIR_EL1 = 0xffffffffffffffff`

### 3) MMU enable attempt (SCTLR.M)
From `output/phase6/phase6a_run2.qemu.log`:
- PC `0x80100004c`: `SCTLR_EL1 = 0x0`
- **PC `0x801000054`: `SCTLR_EL1 = 0x1`**  (attempt to set `M=1`)

Note: these EL1 MMU sysregs are intentionally treated as **RAZ/WI** by the Phase 5e contract (to prevent accidental page-table walks). Phase 6a adds logging only; behavior remains unchanged.

## First translation-related failure after MMU actions
Immediately after the SCTLR write sequence, the payload performs a load from a high VA:
- PC `0x801000060`: `ldr x5, [x4]` with `x4 = 0xffff000000000000`

Observed in `output/phase6/phase6a_run2.qemu.log`:
- **Failure type:** synchronous exception (exception-driven)
- **Exception:** `Taking exception 4 [Data Abort]`
- **FAR:** `0xffff000000000000`
- **ELR:** `0x801000060`
- **Vector target:** `...to EL3 PC 0x200`

Follow-on behavior:
- The CPU then repeatedly takes `Prefetch Abort` exceptions while trying to fetch from the EL3 vector at `PC=0x200`, producing repeated `Invalid read at addr 0x200` lines.

## Repeatability
The key markers are repeatable across runs (compare `phase6a_run2.qemu.log` and `phase6a_run3.qemu.log`):
- First MMU-related write remains `PC=0x801000024` (`TTBR0_EL1 = 0x80001000`)
- MMU-enable attempt remains `PC=0x801000054` (`SCTLR_EL1 = 0x1`)
- First failure remains `Data Abort` at `ELR=0x801000060` with `FAR=0xffff000000000000`, then vector fetch at `PC=0x200`

## Classification
**MMU-enable**

Rationale: the OS-side code explicitly attempts the standard MMU enable sequence (TTBR/TCR/MAIR followed by SCTLR.M=1), and the first subsequent failure is an exception-driven abort associated with the first post-configuration high-address access.
