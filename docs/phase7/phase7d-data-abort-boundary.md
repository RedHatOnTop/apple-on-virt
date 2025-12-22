# Phase 7d: Post-HVC Data Abort Boundary (Classification)

## Question
Is the post-HVC Data Abort observed in Phase 7c:
- (A) an MMU-required continuation point, **or**
- (B) an expected terminal fault without MMU?

## Evidence (from Phase 7c logs)
Source log (representative; all 3 are identical by hash):
- `output/phase7/phase7c_run1.qemu.log`

The HVC trap/return completes first:
- Undefined exception at the HVC site:
  - `Taking exception 1 [Undefined Instruction]`
  - `ELR = 0x8010000cc` (the `hvc #0` instruction)
  - vectors to `PC = 0x801000a00` (EL1 sync+SPx)
- The vector stub returns (`eret`) and execution resumes at:
  - `Exception return from AArch64 EL1 to AArch64 EL1 PC 0x8010000d0`

The **post-HVC** Data Abort is then:
- `Taking exception 4 [Data Abort] on CPU 0`
- `ESR = 0x25/0x96000000`
- `FAR = 0xffff000000000000`
- `ELR = 0x801000150`
- vectors to `PC = 0x801000a00` (EL1 sync+SPx)

The faulting instruction at `ELR 0x801000150` is:
- `0x801000150:  ldr x6, [x5]` with `x5` previously set to `0xffff000000000000`

This address (`0xffff000000000000`) is a high VA-range address that is **not valid in the current no-MMU / identity-only bring-up** environment.

## Classification
**(B) Expected terminal fault without MMU.**

Reasoning (evidence-backed):
- The Data Abort is caused by an explicit load from `FAR = 0xffff000000000000` (confirmed in the trace by `ELR = 0x801000150` pointing at the `ldr` and the immediately preceding construction of `x5`).
- This is not a “page-table missing” continuation point of kernel init; it is a direct access to an unmapped high virtual address range.
- Therefore, without enabling MMU + establishing translations, this access is expected to fault and is terminal in the current environment.

## Determinism
All runs are deterministic:
- `output/phase7/phase7c_run{1,2,3}.qemu.log` have identical SHA256 hashes.
- The exception sequence is stable: HVC UNDEF → returns → Data Abort at the same FAR/ELR.
