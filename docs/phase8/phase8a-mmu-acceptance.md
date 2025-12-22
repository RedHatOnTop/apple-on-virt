# Phase 8a: Minimal MMU Acceptance Layer (forward progress)

## What this is
A **minimal MMU acceptance layer** that lies just enough to allow continued execution **after the guest attempts to set `SCTLR_EL1.M = 1`**.

This is **not** a real MMU:
- no page table walk
- no permissions
- no TLB model / caching model
- no page fault handling

## Trigger
The layer is enabled when the guest executes an `MSR SCTLR_EL1, <Xt>` where the written value has bit0 (`M`) set.

Evidence (run1):
- `Phase8a: SCTLR_EL1.M=1 observed at pc=0x80100007c; enabling minimal MMU acceptance layer`

## Allowed address model (strict)
Once enabled, address translation accepts **only**:

1) **Kernel high VA window**
- VA: `0xffff_0000_0000_0000` .. `0xffff_ffff_ffff_ffff`
- PA: `0x8000_0000_00 + (VA - 0xffff_0000_0000_0000)`
- bounded to the configured DRAM size (256MB)

2) **Current execution region**
- VA: `0x8000_0000_00` .. `0x8000_0000_00 + 256MB`
- PA: identity-mapped

Everything else is left to fault as before.

## Where it is implemented
- Sysreg write observation trigger:
  - `emulator/qemu-apple-silicon/target/arm/tcg/op_helper.c` (`HELPER(apple_log_mmu_sysreg)`)
- Acceptance mapping in the TLB fill path:
  - `emulator/qemu-apple-silicon/target/arm/tcg/tlb_helper.c` (`arm_cpu_tlb_fill_align`)
- Per-CPU state:
  - `emulator/qemu-apple-silicon/target/arm/cpu.h` (`CPUARMState`)

## Observability (required logs)
### VA→PA translation decisions
Example (run1):
- `Phase8a: accept VA 0xffff000000000000 -> PA 0x800000000 (load, high-va)`

### First accepted high-VA access
(run1):
- `Phase8a: first accepted high-VA access VA 0xffff000000000000 -> PA 0x800000000`

### First instruction executed after MMU enable
- Enable PC logged:
  - `Phase8a: SCTLR_EL1.M=1 observed at pc=0x80100007c ...`
- First observed post-MMU instruction fetch logged during exception entry:
  - `Phase8a: first observed post-MMU instruction fetch VA 0x801000a00 -> PA 0x801000a00`

## Success condition check
### Forward progress after `SCTLR_EL1.M = 1`
Using probe payload `scripts/phase8/phase8a_mmu_acceptance_probe.s`:
- After the enable write, the probe executes past the formerly-terminal high-VA load and emits markers:
  - `8A` → `P1` (post-enable) → **high-VA load succeeds** → `P2`

### Failure point moves (new FAR/ELR)
Without the acceptance layer, the first high-VA access would fault (Phase 7d terminal pattern: FAR in the high VA range).

With Phase 8a enabled, the next (intentional) out-of-contract access faults instead:
- `Taking exception 4 [Data Abort]`
- `FAR = 0x0`
- `ELR = 0x8010000d8`

This is a different failure point than the Phase 7d terminal high-VA abort.

## Repeatability
The run is deterministic:
- `sha256(output/phase8/phase8a_run1.qemu.log) == sha256(output/phase8/phase8a_run2.qemu.log)`

## Artifacts
- Probe payload: `output/phase8/phase8a_mmu_acceptance_probe.bin`
- Logs: `output/phase8/phase8a_run{1,2}.qemu.log`
