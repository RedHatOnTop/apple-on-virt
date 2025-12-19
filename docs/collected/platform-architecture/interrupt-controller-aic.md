---
title: Apple Interrupt Controller (AIC)
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/soc/aic.md
project-relevance:
  Emulator must implement AIC to handle guest interrupts; this is NOT a standard GIC.
confidence: high
---

## Extracted Facts

### Architecture
- Custom Apple design (AIC), distinct from ARM GIC.
- Uses **SET/CLR** register pairs:
    - Write 1 to SET to assert/enable.
    - Write 1 to CLR to deassert/disable.

### Register Map (MMIO Base: `0x2_3b10_0000`)
- **Global**: `0x0000` (Cfg, Count?).
- **Interrupt Events**: `0x2000`+.
    - `0x2004`: `IRQ_REASON` (Current CPU).
    - `0x2008`: `IPI_SEND`.
    - `0x200c`: `IPI_ACK`.
    - `0x2024`: `IPI_MASK_SET`.
    - `0x2028`: `IPI_MASK_CLR`.
- **Target Maps**: `0x3000`+ (CPU bitfields per IRQ).
- **SW Inteerrupts**: `0x4000` (`SW_GEN_SET/CLR`).
- **IRQ Masks**: `0x4100` (`IRQ_MASK_SET/CLR`).
- **Hardware State**: `0x4200` (`HW_IRQ_MON`).
- **Timers**: `0x8020` (Low), `0x8028` (High) - Mirrors `CNTPCT_EL0`?

### Protocols
- **Hardware IRQ Flow**:
    1.  IRQ fires in HW.
    2.  `IRQ_MASK` automatically set by AIC.
    3.  ARM IRQ asserted to CPU.
    4.  CPU reads `IRQ_REASON`.
    5.  CPU handles device.
    6.  CPU writes `IRQ_MASK_CLR` to unmask.
- **IPI Flow**:
    1.  Sender: Write `IPI_SEND`.
    2.  Receiver: ARM IRQ asserted.
    3.  Receiver: Read `IRQ_REASON` (IPI masked in `IPI_MASK`).
    4.  Receiver: Write `IPI_ACK`.
    5.  Receiver: Write `IPI_MASK_CLR` (Unmask).

### Timers
- System timer bypasses AIC and wires directly to FIQ.

## Explicit Non-Facts / Unknowns
- "Some scattered RE notes".
- Exact bit definitions for Global CFG `0x0010`.
- "There are 11 targets? CPUs 0-7 and some auxiliary ones?"

## Notes for Future Phases
- Emulator must perform the auto-masking on IRQ assertion logic.
- Requires mapping standard ARM Timer interrupts to FIQ, distinct from AIC IRQ line.
