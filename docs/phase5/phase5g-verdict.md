# Phase 5g Verdict: Final Verification (Hardware Responsibility Exhaustion)

## 1) Executive Summary (non-technical)
Across three independent boots, the emulator reaches the same point: it successfully hands off control to the “OS code” payload (kernel stub), which immediately performs a deliberate access to an unmapped address and triggers a deterministic fault. There is no evidence that any missing device/MMIO/sysreg handling causes this failure; the failure is caused by code executing from the kernel-stub region itself. Therefore, additional hardware stubs would not change the outcome of this phase.

## 2) Evidence Table
| Boot attempt # | Last successful marker | Failure address | Failure cause |
|---:|---|---:|---|
| 1 | UART prints `H`, `J`, `K` | `0x0000000000000200` | Unmapped memory read: `ldr w1, [x0]` with `x0=0x200` |
| 2 | UART prints `H`, `J`, `K` | `0x0000000000000200` | Unmapped memory read: `ldr w1, [x0]` with `x0=0x200` |
| 3 | UART prints `H`, `J`, `K` | `0x0000000000000200` | Unmapped memory read: `ldr w1, [x0]` with `x0=0x200` |

Primary evidence files:
- Determinism prefix logs (stop at first failure):
  - `output/phase5g_ge_run1.firstfail.txt`
  - `output/phase5g_ge_run2.firstfail.txt`
  - `output/phase5g_ge_run3.firstfail.txt`
- Instruction-level trace showing the faulting instruction in OS code:
  - `output/phase5g_in_asm.log`

## 3) Determinism Analysis
### Method
Booted the same configuration three times using the Phase 5f handoff + kernel stub, with QEMU logging enabled (`-d guest_errors`). For determinism, we compare the log prefix up to and including the first failing access.

### Results
- All three runs reach the same last-successful UART markers (`H` then `J` then `K`).
- All three runs report the first failing access as:
  - `Invalid read at addr 0x200, size 4, region '(null)', reason: rejected`
- The extracted “prefix-to-first-failure” logs are byte-identical across all three runs (same SHA-256):
  - `output/phase5g_ge_run{1,2,3}.firstfail.txt` hashes match.

Conclusion: the failure point is deterministic.

## 4) Hardware Exhaustion Argument
### Negative Capability Test (no missing-hardware access precedes failure)
In the prefix logs up to the first failure (`output/phase5g_ge_run*.firstfail.txt`):
- There are **no** messages indicating unhandled MMIO, unknown sysreg traps, or unimplemented device accesses.
- The **first** fault is the unmapped read at `0x200`.

This demonstrates the emulator does not encounter a missing-device/MMIO/sysreg requirement prior to failure.

### Responsibility Isolation (fault originates from OS code)
From `output/phase5g_in_asm.log`, the trace shows execution in the kernel-stub region at `APPLE_KERNEL_BASE`:
- `0x80100001c: movz x0, #0x200`
- `0x801000020: ldr  w1, [x0]`  ⟵ causes `Invalid read at addr 0x200`

The PC (`0x801000020`) lies within the kernel-stub load region (`0x801000000`), and UART marker `K` confirms the kernel stub is executing. Therefore, the triggering instruction is executed by OS code (the kernel stub), not firmware or emulator initialization.

### Futility: why adding more hardware stubs won’t change the outcome
The failure is a **direct, intentional unmapped memory read** performed by the OS payload (`ldr w1, [x0]` with `x0=0x200`). Adding additional device stubs (UART/AIC/etc.) would not prevent a load from address `0x200`, and mapping/handling address `0x200` would constitute a memory-map/MMIO change (explicitly prohibited for Phase 5g and not a “reasonable” next hardware stub). Therefore, additional hardware emulation work is not meaningful for changing the Phase 5 outcome.

## 5) Final Verdict
All required conditions are satisfied:
- Failures are deterministic (3/3 boots match to first failure).
- Failure occurs inside OS code (PC in kernel-stub region; `K` marker printed).
- No missing hardware access precedes failure (no unhandled MMIO/sysreg prior to first invalid read).
- No reasonable hardware addition would prevent the failure (the OS payload intentionally reads unmapped address `0x200`).

Hardware responsibility is exhausted at Phase 5.
