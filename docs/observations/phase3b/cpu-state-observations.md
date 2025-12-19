# CPU State Observations - Phase 3b

**Question**: What CPU execution level and state is observed after early boot?

---

## Observation 1: Entry Point Execution Level

**Source**: `docs/external/Asahi Linux Docs/docs/sw/m1n1-dev-guide.md`

**Observed Fact**:
```
Entry point: 0x800 offset
Translation: DISABLED (MMU off)
Register x0: Physical address to boot_args structure
```

**Context**: When iBoot transfers control to next stage (m1n1/kernel), CPU state is:
- MMU disabled
- Physical addressing mode
- boot_args pointer in x0

**Confidence**: HIGH
- m1n1 boots successfully with this assumption
- Documented in boot protocol

---

## Observation 2: MMU State

**Source**: `docs/collected/boot-chain/macho-boot-interface.md`

**Observed Fact**:
```
"MMU: OFF at entry"

Physical addressing active at kernel entry point
Virtual addressing must be enabled by kernel itself
```

**Context**: Boot protocol explicitly states MMU is disabled when control transfers.

**Confidence**: HIGH
- Explicit statement in boot protocol
- Consistent with m1n1 behavior

---

## Observation 3: RVBAR Locking

**Source**: `docs/collected/boot-chain/macho-boot-interface.md`

**Observed Fact**:
```
"RVBAR: Locked by iBoot to the top of the entry page (cannot be changed after boot)"

Purpose: Resume from deep sleep likely restarts execution here
```

**Context**: iBoot locks RVBAR_ELx register before transferring control.

**Confidence**: MEDIUM
- Documented behavior
- Purpose stated as "likely" for sleep resume
- Not directly tested in available sources

---

## Observation 4: Exception Level (Implicit)

**Source**: Multiple system register references in `docs/collected/cpu-arm64e/`

**Observed Fact**:
```
System registers accessible:
- SYS_APL_*_EL1 registers documented
- EL1 register access implied by kernel operation
- No explicit EL2/EL3 operation documented for kernel entry
```

**Context**: Documentation focuses on EL1 system registers, kernel operates in EL1.

**Confidence**: MEDIUM
- Implicit from register naming (EL1)
- No explicit statement of entry EL
- Standard ARM64 Linux practice is EL1 entry

---

## Observation 5: Register State Beyond x0

**Source**: `docs/external/Asahi Linux Docs/docs/sw/m1n1-dev-guide.md`

**Observed Fact**:
```
Documented: x0 = boot_args physical address
Other registers: NOT SPECIFIED
```

**Context**: Only x0 is explicitly documented in boot protocol.

**Confidence**: HIGH (for x0), UNKNOWN (for others)

---

## UNKNOWN

### Exception Level at Entry

**Question**: Is kernel entered at EL1 or EL2?

**Evidence**:
- System registers are EL1-named
- m1n1 hypervisor exists (implies EL2 capability)
- Explicit entry EL: UNKNOWN

### Stack Pointer Initialization

**Question**: Is stack pointer (SP) set by iBoot?

**Evidence**:
- Not mentioned in boot protocol
- m1n1 must initialize its own stack
- iBoot behavior: UNKNOWN

### Register State x1-x30

**Question**: What values do x1-x30 contain at entry?

**Evidence**:
- Only x0 specified
- Others: UNKNOWN

### CPU Feature State

**Question**: Are PAC/MTE/other features enabled at entry?

**Evidence**:
- Not specified in boot protocol
- Apple-specific features documented separately
- Entry state: UNKNOWN

### PSTATE Flags

**Question**: What are the processor state flags (DAIF, etc.) at entry?

**Evidence**:
- Not specified
- Interrupts presumably disabled
- Exact PSTATE: UNKNOWN

### Cache State

**Question**: Are caches enabled or disabled at entry?

**Evidence**:
- Not specified
- MMU disabled, implies D-cache likely off
- Exact state: UNKNOWN

---

## Observation 6: m1n1 Hypervisor Implications

**Source**: `docs/external/Asahi Linux Docs/docs/sw/m1n1-hypervisor.md`

**Observed Fact**:
```
m1n1 includes hypervisor functionality
Can run macOS or Linux as guest
Provides virtual UART over USB
Traces hardware accesses
```

**Context**: m1n1 operating as hypervisor implies:
- m1n1 runs at EL2
- Guest runs at EL1
- Hypervisor mode is accessible

**Confidence**: MEDIUM
- m1n1 hypervisor demonstrably works
- Implies EL2 access
- Entry point EL still not explicit

---

## UNKNOWN (Continued)

### Hypervisor Entry vs Normal Entry

**Question**: Does iBoot enter at different ELs for different boot modes?

**Evidence**:
- m1n1 can operate as hypervisor (EL2)
- Standard kernel operation (EL1)
- Entry point variation: UNKNOWN

---

## Summary

**CONFIRMED**:
1. MMU is OFF (translation disabled) at entry
2. x0 contains physical address to boot_args structure
3. Entry point is at offset 0x800
4. RVBAR is locked by iBoot
5. Physical addressing mode active

**CONFIDENCE**: HIGH for MMU state and x0 register, MEDIUM for RVBAR locking

**PREVIOUSLY UNKNOWN → NOW OBSERVED**:
- MMU state: OFF (not assumed to be on)
- Register x0: boot_args pointer (not arbitrary)
- Entry offset: 0x800 (not 0x0)

**CRITICAL UNKNOWN**: 
- Exact Exception Level at entry (EL1 vs EL2)
- Stack pointer initialization
- Other register states (x1-x30)
- PSTATE flags
- Cache state

---

**Observation Date**: 2025-12-18  
**Sources**: Asahi Linux Docs (m1n1-dev-guide.md, macho-boot-protocol.md)  
**Validation**: m1n1 boots successfully on real Apple Silicon with these assumptions
