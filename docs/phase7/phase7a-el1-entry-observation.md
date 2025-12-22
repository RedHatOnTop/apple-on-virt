# Phase 7a: EL1 Entry Environment Observation

## 1) Entry conditions (EL, PSTATE)
This phase introduces a **boot-chain simulation** shim (`scripts/phase7/phase7a_handoff_el1.s`) which transitions from EL3 to **EL1** via `ERET` before jumping to the kernel payload.

Observed evidence (run1, Phase 7a):
- First EL-tagged sysreg log after entry shows **EL=1**:
  - `Phase6b: MSR VBAR_EL1 value=0x80100200 pc=0x801000024 EL=1` (from `output/phase7/phase7a_run1.qemu.log`)
- Exception log confirms EL1 exception routing:
  - `...from EL1 to EL1`
- Exception log shows PSTATE at vector entry:
  - `...to EL1 PC 0x80100400 PSTATE 0x3c5`

## 2) Behavioral differences vs Phase 6 (measurable)
### Difference A: sysreg access now occurs at EL1 (not EL3)
Phase 6c (baseline) showed EL3 execution during early init probes:
- `Phase6c: MRS MPIDR_EL1 ... EL=3`

Phase 7a shows the same probes now occur at **EL=1**:
- `Phase6c: MRS MPIDR_EL1 pc=0x801000028 EL=1`
- `Phase6c: MSR TPIDR_EL1 value=0x80003000 pc=0x801000034 EL=1`
- `Phase6c: MRS CNTFRQ_EL0 ... EL=1`

### Difference B: exception vector base used is EL1, not EL3
Phase 6c baseline exception routing:
- `...from EL3 to EL3`
- `...with VBAR_EL3 0x0`
- `...to EL3 PC 0x200`

Phase 7a exception routing:
- `...from EL1 to EL1`
- `...with VBAR_EL1 0x80100200`
- `...to EL1 PC 0x80100400 PSTATE 0x3c5`

This is a direct change in exception classification and target vectoring solely from changing the active EL.

## 3) New progression or new failure
### New progression
The system now reaches a state where:
- The OS-side code’s attempt to set `VBAR_EL1` is *actually used* for exception delivery.
- Exceptions are delivered at EL1 (matching the OS’s expected operating EL).

### New failure mode
After an `hvc #0` (PSCI-style call) at `ELR=0x801000078`, the guest takes:
- `Taking exception 1 [Undefined Instruction]` (still occurs)
- then the CPU attempts to fetch the EL1 vector entry at `PC=0x80100400` and logs:
  - `Invalid read at addr 0x80100400, size 4, region '(null)', reason: rejected`
  - followed by repeated `Prefetch Abort` exceptions with `FAR=0x80100400`

This differs from Phase 6, where failures immediately vectored to `EL3 PC=0x200` due to `VBAR_EL3=0x0`.

## 4) What changed ONLY because EL changed
Only the **boot-chain simulation** of entering EL1 changed.

As a result:
- All subsequent sysreg probes are executed at EL1.
- Exception routing uses `VBAR_EL1` and targets an EL1 vector offset (`0x80100400` here), rather than using EL3 vectors (`0x200`).

No Phase 5 hardware contract was modified, and no MMU/exception handling implementation was added.
