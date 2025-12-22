# Phase 6c: Early Kernel Subsystem Expectations

## Goal
Identify which early-kernel subsystems OS-side code attempts to touch immediately after MMU/vector setup, assuming its expected execution environment.

This phase is **observation only**:
- No MMU implementation was added.
- No exception delivery was fixed.
- No EL mismatch was corrected.
- Only additional **logging** was added, and an OS-side *probe payload* was used to exercise the expected access patterns.

## Test setup
- QEMU: `emulator/qemu-apple-silicon/build/qemu-system-apple64e`
- Machine: `-M apple-silicon-bringup`
- DTB: `output/minimal_adt_with_placeholders.bin`
- iBoot surrogate / handoff: `output/phase5f_handoff.bin`
- Phase 6c probe payload:
  - Source: `scripts/phase6/phase6c_subsystem_probe.s`
  - Binary: `output/phase6/phase6c_subsystem_probe.bin`
- Logging enabled: `-d guest_errors,in_asm,int,unimp` (logs captured to `output/phase6/phase6c_run{1,2,3}.qemu.log`)

Evidence logs:
- `output/phase6/phase6c_run1.qemu.log`
- `output/phase6/phase6c_run2.qemu.log`
- `output/phase6/phase6c_run3.qemu.log`

## Ordered list of attempted subsystems (with evidence + classification)

### 1) Exception vector installation (EL1)
**Observed action**: write `VBAR_EL1`.
- Evidence (run1):
  - `Phase6b: MSR VBAR_EL1 value=0x80100200 pc=0x801000024 EL=3`
- Classification: **ARM-generic**

### 2) Per-CPU identity and per-CPU data base
**Observed actions**:
- Read `MPIDR_EL1` (CPU identity)
- Write `TPIDR_EL1` (per-CPU base pointer)

Evidence (run1):
- `Phase6c: MRS MPIDR_EL1 pc=0x801000028 EL=3`
- `Phase6c: MSR TPIDR_EL1 value=0x80003000 pc=0x801000034 EL=3`

Classification: **ARM-generic**

### 3) Timer/scheduler timebase initialization probes
**Observed actions**:
- Read `CNTFRQ_EL0` (timer frequency)
- Read `CNTVCT_EL0` (virtual counter)

Evidence (run1):
- `Phase6c: MRS CNTFRQ_EL0 pc=0x801000038 EL=3`
- `Phase6c: MRS CNTVCT_EL0 pc=0x80100003c EL=3`

Classification: **ARM-generic**

### 4) Interrupt controller / platform interrupt plumbing
**Observed actions**:
- MMIO read/write to AIC base (`0x23b100000`)

Evidence (run1):
- `AIC R off=0x0 size=4 -> 0x0`
- `AIC W off=0x8 size=4 val=0x1`

Classification: **Apple-specific**

### 5) Apple implementation-defined sysreg space
**Observed action**: `MRS S3_5_C15_C0_0` (Apple sysreg space; used for things like IPIs / platform coordination).

Evidence (run1):
- `Phase6c: MRS APPLE_IMPL_SYSREG pc=0x80100005c EL=3`
- `Phase6c: APPLE_IMPL_SYSREG encoding=0x35f000`

Classification: **Apple-specific**

### 6) Secondary CPU bring-up attempt (PSCI / hypervisor interface)
**Observed action**: `hvc #0` with arguments matching PSCI-style calling convention.

Evidence (run1):
- Instruction stream:
  - `0x801000078:  d4000002  hvc      #0`
- Resulting exception:
  - `Taking exception 1 [Undefined Instruction] on CPU 0`
  - `...with ELR 0x801000078`
  - `...to EL3 PC 0x200 ...` (vector base still `VBAR_EL3=0x0`)

Classification: **ARM-generic** (PSCI concept), but the specific expectation of a working HVC/SMC conduit is an **OS-design-choice** dependent on boot environment.

## Repeatability
The access pattern above is repeatable in all three runs:
- Run2/run3 show the same key markers at the same PCs:
  - `VBAR_EL1` write at `0x801000024`
  - `MPIDR_EL1` read at `0x801000028`
  - `TPIDR_EL1` write at `0x801000034`
  - `CNTFRQ_EL0` / `CNTVCT_EL0` reads at `0x801000038` / `0x80100003c`
  - AIC MMIO read/write
  - Apple sysreg space read
  - `hvc #0` at `0x801000078` and the resulting UNDEF exception

## OS assumptions (explicitly labeled assumptions)
- **Assumption:** in a correctly configured environment (expected EL + vectors), the OS would proceed from vector installation and MMU configuration into per-CPU setup, timebase init, interrupt plumbing, and (potentially) secondary CPU bring-up.
- **Assumption:** the presence of an Apple implementation-defined sysreg space suggests the OS expects Apple-specific platform coordination registers beyond ARM-generic facilities.

These are supported by the concrete access attempts logged above, but they remain assumptions about *why* the OS would do this.
