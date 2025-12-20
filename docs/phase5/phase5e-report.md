# Phase 5e Report: CPU Sysreg Sanity (No Traps, No Translation)

## Scope
Phase 5e ensures that CPU system register accesses during early boot do **not**:
- trap (UNDEF/sysreg trap)
- cause undefined behavior
- accidentally enable MMU/translation

Correctness is explicitly out of scope.

## Implemented behavior
Implementation is in `emulator/qemu-apple-silicon/target/arm/tcg/translate-a64.c`.

### CPU sysreg stubs (RAZ/WI)
A minimal filter was added so common early-boot configuration/probe sysregs are treated as:
- **Reads:** return `0`
- **Writes:** ignored

This is specifically to keep translation disabled and prevent page table walks.

Sysregs treated as RAZ/WI:
- `SCTLR_EL1` (`S3_0_C1_C0_0`)
- `TTBR0_EL1` (`S3_0_C2_C0_0`)
- `TTBR1_EL1` (`S3_0_C2_C0_1`)
- `TCR_EL1` (`S3_0_C2_C0_2`)
- `MAIR_EL1` (`S3_0_C10_C2_0`)
- `AMAIR_EL1` (`S3_0_C10_C3_0`)
- `ESR_EL1` (`S3_0_C5_C2_0`)
- `FAR_EL1` (`S3_0_C6_C0_0`)

### CurrentEL
`CurrentEL` is left to QEMU’s normal implementation (architected; should not trap).

## Evidence from logs
Payload:
- `output/phase5e_sysreg_smoketest.bin`

The payload:
1) performs reads/writes to the sysregs listed above
2) prints `S` over UART after completing sysreg accesses
3) triggers the prior deterministic unmapped read at `0x900000000`

Evidence excerpt (`output/phase5e_evidence.txt`):

```
Invalid read at addr 0x900000000, size 8, region '(null)', reason: rejected
```

UART markers extracted from the same evidence file show the sysreg sequence completed (`S` printed) without any sysreg trap aborting execution.

## Why Phase 5e is complete
- Sysreg accesses in the targeted set no longer risk UNDEF traps (handled as RAZ/WI).
- Translation is not enabled (MMU-control writes are ignored).
- Execution proceeds to the deterministic unmapped-access failure category, indicating sysregs are no longer the blocker.
