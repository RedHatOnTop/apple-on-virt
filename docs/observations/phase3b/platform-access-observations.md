# Platform Access Observations - Phase 3b

**Question**: Which platform components are accessed unconditionally?

---

## Observation 1: UART Access by m1n1

**Source**: `docs/collected/platform-architecture/uart-debug.md`

**Observed Fact**:
```
Device: UART0 (Debug Console)
Address: 0x2_3520_0000
Usage: m1n1 uses this port for output
```

**Context**: m1n1 bootloader accesses UART0 for console output immediately upon execution.

**Confidence**: HIGH
- Documented m1n1 behavior
- Used for serial console on real hardware

---

## Observation 2: Memory Access Pattern

**Source**: `docs/collected/boot-chain/macho-boot-interface.md`

**Observed Fact**:
```
Accessed regions at boot:
1. boot_args structure (via x0 pointer)
2. Device Tree (referenced in boot_args)
3. Kernel image region
4. Top of kernel data (boot_args->top_of_kdata)
```

**Context**: These memory regions are accessed immediately by any bootloader/kernel to discover platform.

**Confidence**: HIGH
- Required by boot protocol
- Accessed before any device initialization

---

## Observation 3: Interrupt Controller (AIC)

**Source**: `docs/collected/platform-architecture/interrupt-controller-aic.md`

**Observed Fact**:
```
Device: Apple Interrupt Controller (AIC)
Address: 0x2_3b10_0000
Size: 48 KB

Key registers:
- 0x2004: IRQ_REASON (read to identify interrupt)
- 0x4100: IRQ_MASK_SET/CLR

Protocol: Auto-masking on IRQ assertion
```

**Context**: AIC must be accessible for interrupt handling. However, timing of first access not explicitly documented.

**Confidence**: MEDIUM
- Address documented
- Used by Linux kernel
- Early vs late access: UNKNOWN

---

## Observation 4: Timer Access

**Source**: `docs/collected/platform-architecture/interrupt-controller-aic.md`

**Observed Fact**:
```
System timer: Bypasses AIC, wires directly to FIQ

AIC Timer registers:
- 0x8020: Timer (Low)
- 0x8028: Timer (High)
- Mirrors CNTPCT_EL0
```

**Context**: Timer may be accessed via system registers (CNTPCT_EL0) or MMIO.

**Confidence**: MEDIUM
- Timer exists
- Multiple access paths
- Which path used first: UNKNOWN

---

## Observation 5: Watchdog Timer

**Source**: `docs/collected/platform-architecture/watchdog-timer.md`

**Observed Fact**:
```
Device: Watchdog Timer (WDT)
Address: 0x2_3d2b_0000

Registers:
- +0x10: Timer Count (Read)
- +0x14: Compare Value (R/W)
- +0x1c: Control (Enable/Disable)

Default behavior: 120 second timeout enabled
```

**Context**: WDT may be running by default, requiring early interaction to prevent reboot.

**Confidence**: MEDIUM
- Address documented
- Default timeout mentioned
- Early access requirement: UNKNOWN

---

## Observation 6: Power Manager (PMGR)

**Source**: `docs/collected/memory-model/soc-address-map.md`

**Observed Fact**:
```
Device: PMGR (Power Manager)
Address: 0x2_3b70_0000
Size: 1 MB

Note: "Power domains in PMGR often need to be enabled before MMIO is accessible"
```

**Context**: PMGR controls power to other devices. May need early access to enable peripherals.

**Confidence**: HIGH for existence, LOW for access timing
- Critical for device power
- Access order implications
- Exact boot-time behavior: UNKNOWN

---

## Observation 7: System Register Access

**Source**: `docs/collected/cpu-arm64e/system-registers.md`

**Observed Fact**:
```
Apple-specific system registers (EL1):
- MIDR_EL1: CPU identification (read for core type detection)
- MPIDR_EL1: CPU topology (Cluster, Core ID)
- Various HID registers for CPU features
```

**Context**: These registers are likely read early to detect CPU configuration.

**Confidence**: MEDIUM
- Registers documented
- Required for SMP
- Boot-time access: PROBABLE but not explicit

---

## UNKNOWN

### Unconditional vs Conditional Access

**Question**: Which devices MUST be accessed vs MAY be accessed?

**Evidence**:
- UART: Used by m1n1 (but is it required?)
- AIC: Required for interrupts (but when?)
- PMGR: Required to power on devices (but order?)
- Exact requirements: UNKNOWN

### Access Order

**Question**: In what order are devices first accessed?

**Evidence**:
- boot_args first (passed in x0)
- Device Tree next (referenced by boot_args)
- UART used by m1n1 early
- Other device order: UNKNOWN

### MMIO vs System Register Preference

**Question**: When both MMIO and system register access exists, which is used?

**Evidence**:
- Timer: Both MMIO (AIC) and sysreg (CNTPCT_EL0) exist
- IPI: Both MMIO (AIC) and sysreg (IPI_RR_EL1) exist
- Preference: UNKNOWN

### Minimal Boot Set

**Question**: What is the absolute minimum set of platform components needed to boot?

**Evidence**:
- Memory (DRAM): YES (obvious)
- Device Tree: YES (boot protocol)
- UART: NO (m1n1 uses it, but required?)
- AIC: NO (required for interrupts, but before interrupts enabled?)
- Minimal set: UNKNOWN

### Probing Behavior

**Question**: Do bootloaders probe for device presence?

**Evidence**:
- Documentation mentions "probing" MMIO ranges
- Access faults noted
- Systematic probing: UNKNOWN

---

## Observation 8: Error Handling

**Source**: `docs/collected/memory-model/soc-address-map.md`

**Observed Fact**:
```
"Emulator must handle Access Faults for unmapped regions (SERror or ignore)"
```

**Context**: Accessing unmapped MMIO generates faults. System must handle gracefully.

**Confidence**: HIGH
- Explicit statement
- Necessary for robustness

---

## Summary

**CONFIRMED**:
1. UART0 at 0x2_3520_0000 is accessed by m1n1
2. boot_args and Device Tree are accessed first (boot protocol requirement)
3. AIC at 0x2_3b10_0000 exists and is used for interrupts
4. PMGR at 0x2_3b70_0000 controls device power
5. Unmapped MMIO generates access faults

**CONFIDENCE**: 
- HIGH: UART, boot_args, DT, addresses
- MEDIUM: Device access order, timing
- LOW: Minimal required set

**PREVIOUSLY UNKNOWN → NOW OBSERVED**:
- UART address and m1n1 usage confirmed
- boot_args/DT access pattern documented
- PMGR power dependency noted

**CRITICAL UNKNOWN**:
- Unconditional vs conditional device access
- Access order and timing
- Minimal boot configuration
- Probing behavior

---

## Note on Methodology

These observations are based on:
1. m1n1 documented behavior (HIGH confidence)
2. Asahi Linux documentation (HIGH confidence)
3. Inference from device existence (MEDIUM-LOW confidence)

Actual access patterns would require:
- Tracing m1n1 execution on real hardware
- Monitoring MMIO accesses during boot
- Analyzing m1n1 source code

These observations represent "what exists" not "what is mandatory."

---

**Observation Date**: 2025-12-18  
**Sources**: Asahi Linux Docs (uart-debug.md, soc-address-map.md, interrupt-controller-aic.md)  
**Validation**: Devices documented, m1n1 UART usage confirmed
