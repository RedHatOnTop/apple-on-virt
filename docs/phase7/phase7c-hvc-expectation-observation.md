# Phase 7c: HVC/PSCI Conduit Expectation (Observation)

## Scope note (boot-chain simulation)
This phase adds a **boot-chain simulation** EL1 synchronous exception vector stub that recognizes the `HVC #0` instruction and returns a fixed value with **no side effects**.

- No PSCI semantics are implemented.
- No secondary CPUs are started.
- No MMU or exception “handling” is implemented beyond the minimal HVC skip-and-return.

Artifacts:
- EL1 entry shim (from Phase 7a): `output/phase7/phase7a_handoff_el1.bin`
- Phase 7c payload: `scripts/phase7/phase7c_hvc_conduit_probe.s` → `output/phase7/phase7c_hvc_conduit_probe.bin`
- Logs: `output/phase7/phase7c_run{1,2,3}.qemu.log`

## 1) HVC arguments observed
Arguments are established immediately before the HVC call (same across all runs), evidenced by the instruction stream in the QEMU trace:
- `x0 = 0x84000003` (constructed via `movz`/`movk`)
- `x1 = 0x1`
- `x2 = 0x0000000080100000`
- `x3 = 0x0`

The HVC instruction faults at:
- `ELR = 0x8010000cc` (run1: `Taking exception 1 [Undefined Instruction] ... with ELR 0x8010000cc`)

Console markers (run1–run3) also show:
- `HV` (about to call)
- `SX` then `A0` (entered sync+SPx vector, arguments sampled)

## 2) Return value used
The vector stub returns a constant:
- `x0 = -1` (PSCI_NOT_SUPPORTED)

Caller-side reaction is deterministic (run1–run3):
- prints `RT` (execution resumed after the HVC)
- prints `NS` (caller observed `x0 == -1`)

## 3) Kernel behavior difference vs Phase 7b
Phase 7b:
- `HVC #0` led to repeated re-entry into the EL1 sync vector (`SX` loop) because the exception path had no conduit return semantics.

Phase 7c:
- The system **still takes a synchronous exception at the HVC**, but the vector stub:
  - recognizes the HVC instruction
  - advances `ELR_EL1` by 4 (skips the HVC)
  - returns `x0 = -1`
- Execution continues past the HVC (`RT` marker), and the next deterministic fault is a **Data Abort** (evidence below).

Evidence (run1):
- `Taking exception 1 [Undefined Instruction] ... ELR 0x8010000cc ... to EL1 PC 0x801000a00`
- later: `Taking exception 4 [Data Abort] ... to EL1 PC 0x801000a00`

## 4) What the kernel assumes about PSCI
Observed assumption boundary:
- The code path requires a **callable conduit** (an exception path that can return to the caller and provide a status code in `x0`).
- Full PSCI behavior (CPU_ON actually starting a CPU, powering states, etc.) is **not** required to progress past the immediate HVC site.

In other words: Phase 7c demonstrates that the minimal requirement is *conduit semantics* (trap → return), not PSCI feature completeness.

## Repeatability
All three runs are byte-identical at the log level:
- `sha256(output/phase7/phase7c_run1.qemu.log) == sha256(run2) == sha256(run3)`

And the console marker sequence is the same:
`7C → HV → SX → A0 → RT → NS → SX → ??`
