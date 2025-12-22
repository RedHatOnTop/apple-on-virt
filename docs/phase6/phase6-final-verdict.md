# Phase 6 Final Verdict: OS Expectation Boundary

## 1. Executive summary
Phase 6 shows the emulator’s Phase 5 hardware contract is sufficient to execute kernel-side code and to observe the kernel’s early initialization *intent* (MMU enable sequence, vector setup, per-CPU and timer probes). The remaining blockers are not missing Phase 5 hardware devices; they are primarily **boot-chain execution-environment mismatches** (notably running/handling exceptions at **EL3** with `VBAR_EL3=0x0`) and **OS/boot strategy choices** (eg requiring a working PSCI conduit).

**Phase 6 confirms the emulator meets OS expectations up to the
kernel initialization boundary.**

## 2. Expectation vs reality table
| Expectation (observed) | Evidence | Reality in this environment | Status |
|---|---|---|---|
| Kernel attempts MMU setup via EL1 sysregs (`TTBR*`, `TCR`, `MAIR`, `SCTLR.M`) | Phase 6a: `msr ttbr0_el1` @ `PC=0x801000024`; `msr sctlr_el1, #1` @ `PC=0x801000054` | Sysreg writes are observed and logged; MMU remains intentionally disabled (RAZ/WI) | **Observed / not satisfied (by design)** |
| Kernel attempts to install EL1 exception vectors (`VBAR_EL1`) | Phase 6b: `MSR VBAR_EL1 value=0x80100200 pc=0x801000024` | Exceptions are taken **EL3→EL3**, and vectors use `VBAR_EL3` | **Observed / unmet** |
| Synchronous abort handling should vector to a valid handler | Phase 6b: Data Abort with `FAR=0xffff000000000000`, vector to `EL3 PC=0x200` | `VBAR_EL3=0x0` → vector target `0x200`, which is unmapped → repeated Prefetch Aborts | **Observed / unmet** |
| Per-CPU identification and per-CPU pointer setup | Phase 6c: `MRS MPIDR_EL1`; `MSR TPIDR_EL1` | Reads/writes occur and are observable | **Observed / satisfied (observability)** |
| Timer/scheduler timebase probes (`CNTFRQ_EL0`, `CNTVCT_EL0`) | Phase 6c: `MRS CNTFRQ_EL0`, `MRS CNTVCT_EL0` | Reads occur and are observable | **Observed / satisfied (observability)** |
| Platform interrupt plumbing touch (Apple AIC MMIO existence) | Phase 6c log: `AIC R ...`, `AIC W ...` | AIC MMIO region exists and accepts accesses | **Observed / satisfied (existence only)** |
| Apple implementation-defined sysreg space present | Phase 6c: `MRS S3_5_C15_C0_0` logged as `APPLE_IMPL_SYSREG` | Access is observed (and stubbed), showing OS expects this space | **Observed / satisfied (existence/RAZ)** |
| Secondary CPU bring-up conduit (PSCI/HVC path) | Phase 6c: `hvc #0` at `PC=0x801000078` → `Undefined Instruction` | No working PSCI conduit in this bring-up environment; traps at EL3 | **Observed / unmet** |

## 3. Responsibility classification
### Unmet expectations **NOT attributable to Phase 5 hardware**
1) **Correct execution level for kernel init (EL1 vs EL3)**
- Evidence: exceptions log `...from EL3 to EL3` and `...with VBAR_EL3 0x0` (Phase 6b).
- Classification: **Boot-chain responsibility** (handoff/entry conditions).

2) **Valid exception vector base and handler availability at the active EL**
- Evidence: exceptions vector to `EL3 PC=0x200` with `VBAR_EL3=0x0` (Phase 6b), leading to repeated Prefetch Aborts.
- Classification: **Boot-chain responsibility** (vector base and exception environment preparation).

3) **MMU translation and exception-driven page fault handling**
- Evidence: MMU enable attempt via `SCTLR_EL1=0x1` followed by Data Abort on high VA access (Phase 6a/6b).
- Classification: **Boot-chain responsibility** (if the intent is “enter kernel with MMU off but valid vectors/EL”), and/or **OS design choice** (kernel requiring translation enabled early).

4) **Secondary CPU bring-up via PSCI/HVC**
- Evidence: `hvc #0` results in `Undefined Instruction` at `ELR=0x801000078` (Phase 6c).
- Classification: **OS design choice / boot-chain responsibility** (depends on whether the OS expects PSCI, SMC, spin-tables, etc; not a Phase 5 hardware device gap).

### Confirmed satisfied expectations (Phase 5 hardware contract)
- Memory placement and execution (kernel-side code observed executing).
- UART output for markers (Phase 6 probes emit `M`, `V`, `C`).
- Timer sysregs readable (Phase 6c).
- AIC MMIO region exists and is safely accessible (Phase 6c).
- Apple implementation-defined sysreg space can be probed without crashing (Phase 6c).

## 4. Final verdict
Phase 6 demonstrates that the emulator’s Phase 5 hardware contract is not the limiting factor for forward progress. The limiting factors are the **boot-chain execution environment** (EL and vector base) and **OS/boot strategy assumptions** (MMU + exception handling + PSCI conduit), which define the boundary where “hardware emulation” ends and “OS interaction/boot-chain correctness” begins.

**Phase 6 confirms the emulator meets OS expectations up to the
kernel initialization boundary.**
