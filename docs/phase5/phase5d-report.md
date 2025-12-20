# Phase 5d Report: Interrupt Controller Contract (Existence Only)

## Scope (Phase 5d)
Establish the **existence** of an interrupt controller concept only.

Non-goals (explicitly not implemented):
- No interrupt delivery
- No interrupt routing/priority logic
- No IRQ/FIQ scheduling

## MMIO region (AIC stub)
- **Base:** `0x2_3b10_0000` (`APPLE_AIC_BASE = 0x23b100000`)
- **Size:** `48 KB` (`APPLE_AIC_SIZE = 0x0000C000`)

### Stub behavior
Implemented in `hw/apple/apple_machine.c`:
- Region is mapped as an MMIO `MemoryRegion` (`apple.aic`).
- All offsets are handled.
- **Reads:** return stored value (default 0).
- **Writes:** update stored value (last-write-wins).
- No side effects beyond storage.

### Registers observed (Phase 5d smoke test)
From `output/phase5d_evidence.txt`:
- Writes:
  - `AIC[0x0] = 0x1`
  - `AIC[0x4] = 0x0`
- Reads:
  - `AIC[0x0] -> 0x1`
  - `AIC[0x4] -> 0x0`

## Sysreg behavior (interrupt-related stubs)
Implemented in `target/arm/tcg/translate-a64.c` as **RAZ/WI** fallbacks for unknown sysregs in interrupt-probe paths:

### Apple implementation-defined sysreg space
- Any unknown sysreg with encoding: `op0=3, op1=5, crn=15` is treated as **RAZ/WI**.

### Common GICv3 ICC sysregs (probe-only)
If not otherwise registered, the following encodings are treated as **RAZ/WI**:
- `ICC_PMR_EL1` (`SYSREG(3,0,4,6,0)`)
- `ICC_SRE_EL1` (`SYSREG(3,0,12,12,5)`)
- Basic `ICC_{IAR,EOIR}{0,1}_EL1`, `ICC_CTLR_EL1`, `ICC_IGRPEN{0,1}_EL1` encodings

This satisfies the Phase 5d requirement that interrupt-related sysreg accesses **do not trap unexpectedly** while still not implementing interrupts.

## Evidence (log excerpt)
The Phase 5d smoke test binary `output/phase5d_interrupt_smoketest.bin` performs:
1) UART marker prints
2) AIC MMIO read/write
3) ICC + Apple sysreg probes
4) Controlled unmapped read at `0x900000000`

Excerpt (`output/phase5d_evidence.txt`):

```
AIC W off=0x0 size=4 val=0x1
AIC W off=0x4 size=4 val=0x0
AIC R off=0x0 size=4 -> 0x1
AIC R off=0x4 size=4 -> 0x0
Invalid read at addr 0x900000000, size 8, region '(null)', reason: rejected
```

The controlled failure at `0x900000000` demonstrates the run progressed past the interrupt-controller MMIO + sysreg probes, and the failure category is now **unmapped access** (not interrupt-related).

## Why Phase 5d is complete
Quality gates:
- **Gate 1:** Interrupt-related MMIO access does not crash (AIC region mapped; reads/writes succeed).
- **Gate 2:** Interrupt-related sysreg probes do not trap (handled as RAZ/WI).
- **Gate 3:** Failure point changes category to deterministic unmapped access (`0x900000000`).
- **Gate 4:** Deterministic and reproducible (fixed stub values; no interrupt timing).
