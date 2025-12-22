# Phase 8b: Validation — Minimal MMU Acceptance Layer (Phase 8a) (Observation Only)

## Purpose
Validate that the **Phase 8a Minimal MMU Acceptance Layer**:
- eliminates the Phase 7d terminal high-VA abort,
- enables forward execution after `SCTLR_EL1.M = 1`, and
- deterministically reaches a **new** fault boundary.

## Configuration (unchanged from Phase 8a)
- Emulator: `qemu-system-apple64e -M apple-silicon-bringup`
- Boot shim: `output/phase7/phase7a_handoff_el1.bin`
- Probe payload (same as Phase 8a): `scripts/phase8/phase8a_mmu_acceptance_probe.s`
  - Loaded via `-initrd` at `0x801000000`.

## Runs / determinism
Two independent boots were executed with identical settings.

| Run | Log | SHA256 |
|---:|---|---|
| 1 | `output/phase8/phase8b_validate_run1.qemu.log` | `3fd587f17930de2001f340e0c34c8a1b369eac90a69b21103a650206adac0417` |
| 2 | `output/phase8/phase8b_validate_run2.qemu.log` | `3fd587f17930de2001f340e0c34c8a1b369eac90a69b21103a650206adac0417` |

Result: **deterministic** (byte-identical hashes).

## Evidence: Phase 7d terminal fault does NOT recur
In both runs, after `SCTLR_EL1.M=1` the layer **accepts** the prior terminal high VA access:
- `Phase8a: SCTLR_EL1.M=1 observed at pc=0x80100007c; enabling minimal MMU acceptance layer`
- `Phase8a: accept VA 0xffff000000000000 -> PA 0x800000000 (load, high-va)`
- `Phase8a: first accepted high-VA access VA 0xffff000000000000 -> PA 0x800000000 (high-va)`

This demonstrates the Phase 7d terminal high-VA abort is removed (that load no longer aborts).

## New fault boundary (post-forward-progress)
A **new** deterministic Data Abort occurs after forward progress:
- Exception: `Taking exception 4 [Data Abort]`
- `ESR = 0x25/0x96000010`
- `FAR = 0x0`
- `ELR = 0x8010000d8`

### Faulting instruction (disassembly at ELR)
From `-d in_asm` in the same log:
- `0x8010000d4: movz x6, #0`
- `0x8010000d8: ldr  x7, [x6]`  ⟵ aborts with `FAR=0x0`

## Phase 8b result
PASS.
- Old Phase 7d terminal fault does not recur (high-VA access is accepted).
- Execution continues and reaches a new fault boundary.
- Behavior is deterministic and reproducible.
