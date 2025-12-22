# Phase 8 Final: Minimal MMU Acceptance Layer — Results and Closure

## What Phase 8 proved
Phase 8 implemented and validated a **Minimal MMU Acceptance Layer** whose only goal is to allow **instruction forward progress** after `SCTLR_EL1.M = 1` by accepting a very limited set of virtual addresses.

Evidence (Phase 8b validation):
- `SCTLR_EL1.M=1` is observed and explicitly enables the acceptance layer.
- The prior Phase 7d terminal high-VA access no longer aborts:
  - `Phase8a: accept VA 0xffff000000000000 -> PA 0x800000000 (load, high-va)`
  - `Phase8a: first accepted high-VA access ...`
- Execution continues and reaches a **new deterministic fault boundary** (not the old one).

This establishes that Phase 8 successfully moved the system from
"MMU enable immediately kills execution" → "MMU enable allows progress until a new boundary".

## Why Phase 8c correctly STOPPED
Phase 8c is defined as **one-step-only VA acceptance expansion**, justified strictly by *observed faults*.

The new deterministic fault reached in Phase 8b is:
- Data Abort with `FAR = 0x0` (NULL), `ELR = 0x8010000d8`.
- Faulting instruction (from disassembly): `ldr x7, [x6]` with `x6 = 0`.

Because the faulting address is **VA=0**, this boundary is not explained by missing high-VA acceptance.
Adding new high-VA windows cannot change the outcome of a NULL dereference.

Therefore Phase 8c correctly STOPPED: any further VA expansion would be unjustified (i.e., guessing) and would violate the phase’s controlled-scope rules.

## Why the NULL dereference (FAR=0x0) is NOT a translation problem
The acceptance layer only affects translation/acceptance decisions for *specific* virtual address ranges.
A fault at `FAR=0x0` indicates that the guest attempted to dereference a NULL pointer (or otherwise access address 0).

Key point:
- This is a **semantic failure boundary** (invalid pointer / missing initialization), not a missing mapping of a high kernel VA window.

## Phase 8 closure declaration
Phase 8 is CLOSED.
- Minimal post-`SCTLR_EL1.M=1` forward progress was achieved.
- The next blocker is a semantic boundary (NULL dereference), not address translation acceptance.
- Further work must move to observation/classification of kernel-side assumptions (Phase 9), not continued VA acceptance expansion.
