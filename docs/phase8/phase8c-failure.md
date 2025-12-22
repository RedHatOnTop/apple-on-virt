# Phase 8c: STOP — single-rule acceptance did not advance execution

## Entry (from Phase 8b PASS)
Phase 8b validated Phase 8a minimal MMU acceptance (high-VA access no longer aborts; new deterministic fault reached).

New deterministic fault boundary (Phase 8b):
- Exception: Data Abort
- `ESR = 0x25/0x96000010`
- `FAR = 0x0`
- `ELR = 0x8010000d8`
- Faulting instruction (from `-d in_asm`): `0x8010000d8: ldr x7, [x6]` with `x6=0`

## Phase 8c attempt
A single additional VA acceptance rule was tried (a high KVA-base window).

## Result
FAILURE (no forward progress).

Evidence (`output/phase8/phase8c_run1.qemu.log`):
- Still aborts at the same boundary:
  - `FAR = 0x0`
  - `ELR = 0x8010000d8`
  - same instruction `ldr x7, [x6]`.

## Why this cannot be solved by VA acceptance
The fault is a **NULL dereference** (`FAR=0x0`), not a missing high-VA translation.
Accepting additional high virtual address windows does not affect accesses to VA 0.

Per Phase 8c rules:
- The attempted acceptance rule was removed.
- No further retries are performed without new evidence indicating a required VA range.

## Status
Phase 8c is STOPPED at this boundary.
