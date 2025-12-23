# Phase 9b: Kernel Natural Forward-Progress Observation (no intervention)

## Scope / constraints
This phase is observation-only.
- Phase 8b’s deliberate out-of-contract NULL dereference in the probe payload was removed.
- No MMU behavior changes, no new VA acceptance rules, no new devices/MMIO, and no boot-chain changes were introduced.

## What changed (required)
Removed the deliberate NULL dereference from the **probe payload**:
- File: `scripts/phase8/phase8a_mmu_acceptance_probe.s`
- Removed sequence:
  - `movz x6, #0`
  - `ldr  x7, [x6]`  (previously produced `FAR=0x0`, `ELR=0x8010000d8`)

## Test setup (same environment as Phase 8b)
- Emulator: `emulator/qemu-apple-silicon/build/qemu-system-apple64e`
- Machine: `-M apple-silicon-bringup -m 256M`
- DTB: `output/minimal_adt_with_placeholders.bin`
- EL1 entry shim: `output/phase7/phase7a_handoff_el1.bin`
- Payload loaded at `APPLE_KERNEL_BASE (0x801000000)` via `-initrd`:
  - `output/phase9/phase9b/phase9b_mmu_acceptance_probe.bin`
- Logging (maximal, existing): `-d guest_errors,in_asm,int,unimp`

## Runs / determinism
Two independent boots were executed with identical settings.

| Run | Log | SHA256 |
|---:|---|---|
| 1 | `output/phase9/phase9b/phase9b_run1.qemu.log` | `14cb12db12f5f865ef215b86720435fe03164d62cb695cf0a81c49d93c50f571` |
| 2 | `output/phase9/phase9b/phase9b_run2.qemu.log` | `14cb12db12f5f865ef215b86720435fe03164d62cb695cf0a81c49d93c50f571` |

Result: deterministic (byte-identical hashes).

## Timeline of execution (observed)
From `output/phase9/phase9b/phase9b_run1.qemu.log`:

1) EL3 → EL1 handoff completes
- `Exception return from AArch64 EL3 to AArch64 EL1 PC 0x801000000`

2) MMU enable attempt observed; Phase 8a acceptance layer enables
- `Phase8a: SCTLR_EL1.M=1 observed at pc=0x80100007c; enabling minimal MMU acceptance layer`

3) High kernel VA access accepted (same as Phase 8b)
- `Phase8a: accept VA 0xffff000000000000 -> PA 0x800000000 (load, high-va)`
- `Phase8a: first accepted high-VA access VA 0xffff000000000000 -> PA 0x800000000`

4) First new stop boundary (post-Phase-8b boundary)
The payload reaches and remains in a `wfi` loop:
- `0x8010000d4:  wfi`
- The log shows repeated execution reaching `0x8010000d4:  wfi` with no exceptions taken.

UART progress markers observed on stdout during the run boundary (not probes beyond phase boundaries):
- `H` (handoff)
- `E1` (EL1)
- `8A` (probe start)
- `P1` (post-MMU enable)
- `P2` (post high-VA load)

## Faults / exceptions (observed)
None after the removal of the deliberate NULL dereference.
- No `Taking exception ... [Data Abort]` occurs at `FAR=0x0`.
- No new FAR/ESR/ELR tuple was observed.

## Source-path attribution (probe vs kernel)
The observed stop point is in the **probe payload**, not macOS kernel code:
- Executing code region: `0x801000000..` (loaded from `output/phase9/phase9b/phase9b_mmu_acceptance_probe.bin`)
- The repeating instruction is `wfi` at `0x8010000d4`, corresponding to the `hang:` loop in `scripts/phase8/phase8a_mmu_acceptance_probe.s`.

## Classification + STOP decision
**Classification: D) Ambiguous — insufficient evidence (STOP).**

Rationale (evidence-backed):
- With the intentional fault removed, execution reaches the probe’s explicit `hang:` loop and stops producing new behavior.
- Determining “where the macOS kernel itself fails next” would require substituting a real macOS kernel payload for this probe (not available/selected in this phase), which is outside the evidence provided by these runs.

Stop condition met: execution is deterministically stuck in the same `wfi` loop with no new information.
