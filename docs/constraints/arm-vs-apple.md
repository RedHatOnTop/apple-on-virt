# ARM-Generic vs Apple-Specific Requirements

**Purpose**: Classify Phase 3b observations as ARM-generic or Apple-specific

**Date**: 2025-12-18

---

## Classification Methodology

**ARM-Generic**: Behavior required by ARM Architecture Reference Manual or standard ARM64 boot practices

**Apple-Specific**: Behavior unique to Apple Silicon platforms, not required by ARM architecture

**Evidence Sources**:
- ARM Architecture Reference Manual (ARM ARM)
- Standard ARM64 boot protocols
- Phase 3b observations
- Asahi Linux documentation

---

## DRAM Observations

### Observation: DRAM at 0x8_0000_0000

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- ARM architecture does NOT mandate specific DRAM addresses
- DRAM placement is platform-dependent
- Other ARM64 platforms use different addresses:
  - QEMU virt: 0x4000_0000
  - Raspberry Pi 4: 0x0000_0000
  - Server systems: various

**Evidence**: ARM ARM allows any valid physical address for memory

**Confidence**: HIGH

---

### Observation: DRAM size (8/16 GB)

**Classification**: APPLE-SPECIFIC (values), ARM-GENERIC (concept)

**Reasoning**:
- Presence of DRAM: ARM-generic requirement
- Specific sizes: Apple platform choice
- Size detection mechanism: Platform-specific

**Evidence**: ARM architecture requires memory, but not specific amounts

**Confidence**: HIGH

---

## Device Tree Observations

### Observation: ADT (Apple Device Tree) format

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- ARM architecture does NOT mandate device tree format
- Standard ARM64 uses FDT (Flattened Device Tree) via Device Tree Specification
- ADT is Apple's proprietary format
- Binary structure differs from Open Firmware/FDT

**Evidence**: 
- ARM64 Linux boot protocol specifies FDT
- ACPI is alternative on ARM servers
- ADT documented as Apple-specific

**Confidence**: HIGH

---

### Observation: Device tree passed via boot_args in x0

**Classification**: ARM-GENERIC (x0 usage), APPLE-SPECIFIC (boot_args structure)

**Reasoning**:
- ARM64 Linux boot protocol: x0 = device tree pointer (ARM-generic)
- boot_args structure: Apple-specific (XNU boot protocol)
- Mechanism concept: ARM-generic
- Structure format: Apple-specific

**Evidence**: 
- ARM64 Linux boot protocol (documented)
- XNU boot protocol (Apple-specific)

**Confidence**: HIGH

---

### Observation: ADT dynamically modified by iBoot

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- Dynamic device tree modification: Platform bootloader choice
- Not required by ARM architecture
- Specific to Apple boot chain

**Evidence**: Phase 3b observation, no ARM equivalent requirement

**Confidence**: HIGH

---

## CPU State Observations

### Observation: MMU OFF at entry

**Classification**: ARM-GENERIC

**Reasoning**:
- Standard ARM64 boot protocol requires MMU disabled
- Documented in ARM64 Linux boot protocol
- Physical addressing at boot: ARM-generic practice

**Evidence**: ARM64 Linux boot protocol explicitly requires MMU=OFF

**Confidence**: HIGH

---

### Observation: Entry point at 0x800 offset

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- ARM architecture does NOT mandate entry point offset
- Linux ARM64 boot: entry at image start
- UEFI: entry at specified address
- 0x800 offset: Apple convention

**Evidence**: m1n1 documentation, no ARM equivalent

**Confidence**: HIGH

---

### Observation: x0 contains boot_args/device tree pointer

**Classification**: ARM-GENERIC (concept), APPLE-SPECIFIC (boot_args structure)

**Reasoning**:
- x0 for platform info: ARM-generic boot protocol
- boot_args structure: Apple-specific
- ARM64 Linux: x0 = FDT pointer
- UEFI: x0 = EFI system table

**Evidence**: Multiple ARM64 boot protocols use x0 for platform data

**Confidence**: HIGH

---

### Observation: RVBAR locked by iBoot

**Classification**: ARM-GENERIC (RVBAR register), APPLE-SPECIFIC (locking behavior)

**Reasoning**:
- RVBAR_ELx: ARM architecture-defined register
- Locking mechanism: Implementation-defined (Apple choice)
- Purpose (sleep resume): Platform-specific

**Evidence**: 
- ARM ARM defines RVBAR
- Locking behavior: Platform implementation choice

**Confidence**: MEDIUM (locking is implementation-defined)

---

### Observation: Exception Level (implied EL1/EL2)

**Classification**: ARM-GENERIC (EL concept), APPLE-SPECIFIC (entry EL choice)

**Reasoning**:
- Exception Levels: ARM architecture-defined
- Which EL to enter at: Platform bootloader choice
- ARM64 Linux typically enters at EL2 or EL1
- Apple-specific choice: Not definitively observed

**Evidence**: ARM ARM defines ELs, boot EL is platform choice

**Confidence**: HIGH (classification), LOW (specific EL unknown)

---

## Platform Access Observations

### Observation: UART at 0x2_3520_0000

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- UART existence: ARM-generic concept
- Specific address: Apple platform choice
- ARM architecture does NOT specify UART addresses

**Evidence**: MMIO addresses are platform-defined

**Confidence**: HIGH

---

### Observation: AIC (Apple Interrupt Controller) at 0x2_3b10_0000

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- Interrupt controller: ARM-generic requirement
- AIC design: Apple-specific (not GIC)
- Address: Apple platform choice
- Protocol (auto-masking): Apple-specific

**Evidence**: 
- ARM architecture defines GIC (Generic Interrupt Controller)
- AIC is non-standard interrupt controller

**Confidence**: HIGH

---

### Observation: System timers and CNTPCT_EL0

**Classification**: ARM-GENERIC (system registers), APPLE-SPECIFIC (MMIO mirrors)

**Reasoning**:
- CNTPCT_EL0: ARM architecture-defined system register
- Timer system: ARM-generic architectural requirement
- MMIO mirrors in AIC: Apple-specific implementation

**Evidence**: ARM ARM defines Generic Timer system registers

**Confidence**: HIGH

---

### Observation: Watchdog Timer at 0x2_3d2b_0000

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- Watchdog concept: Common but not ARM-mandated
- Address: Apple platform choice
- Default timeout: Apple platform behavior

**Evidence**: ARM architecture does not mandate watchdog

**Confidence**: HIGH

---

### Observation: PMGR (Power Manager) at 0x2_3b70_0000

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- Power management: Platform implementation detail
- PMGR design: Apple-specific
- Address: Apple platform choice
- Device power dependencies: Apple-specific

**Evidence**: ARM architecture does not specify power management

**Confidence**: HIGH

---

### Observation: Apple system registers (HID, IPI, etc.)

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- Implementation-defined system registers: Allowed by ARM
- Specific encodings (SYS_APL_*): Apple-specific
- Functionality: Apple CPU implementation

**Evidence**: 
- ARM ARM allows implementation-defined registers
- SYS_APL namespace: Apple-specific

**Confidence**: HIGH

---

## Memory Layout Observations

### Observation: Physical address space layout

**Classification**: APPLE-SPECIFIC (addresses), ARM-GENERIC (concept)

**Reasoning**:
- Separation of DRAM and MMIO: ARM-generic concept
- Specific address ranges: Apple platform choice
- 0x2_xxxx_xxxx for MMIO: Apple choice
- 0x8_0000_0000 for DRAM: Apple choice

**Evidence**: ARM architecture allows any physical address layout

**Confidence**: HIGH

---

### Observation: kASLR (kernel address randomization)

**Classification**: APPLE-SPECIFIC (implementation), ARM-GENERIC (concept)

**Reasoning**:
- KASLR concept: Security practice, not ARM-mandated
- Implementation in XNU: Apple-specific
- Slide mechanism: Apple boot protocol

**Evidence**: KASLR is OS/platform choice, not architecture requirement

**Confidence**: HIGH

---

### Observation: boot_args structure and memory layout

**Classification**: APPLE-SPECIFIC

**Reasoning**:
- boot_args structure: XNU/Apple-specific
- Fields (phys_base, virt_base, top_of_kdata): Apple-defined
- Memory layout convention: Apple boot protocol

**Evidence**: XNU boot protocol documentation (Apple-specific)

**Confidence**: HIGH

---

## Summary Table

| Observation | Classification | Confidence |
|------------|----------------|------------|
| DRAM at 0x8_0000_0000 | APPLE-SPECIFIC | HIGH |
| ADT format | APPLE-SPECIFIC | HIGH |
| MMU OFF at entry | ARM-GENERIC | HIGH |
| Entry at 0x800 | APPLE-SPECIFIC | HIGH |
| x0 = platform data | ARM-GENERIC (concept) | HIGH |
| boot_args structure | APPLE-SPECIFIC | HIGH |
| RVBAR register | ARM-GENERIC | HIGH |
| RVBAR locking | APPLE-SPECIFIC | MEDIUM |
| Exception Levels | ARM-GENERIC (concept) | HIGH |
| UART address | APPLE-SPECIFIC | HIGH |
| AIC controller | APPLE-SPECIFIC | HIGH |
| Generic Timers | ARM-GENERIC | HIGH |
| AIC timer mirrors | APPLE-SPECIFIC | HIGH |
| Watchdog | APPLE-SPECIFIC | HIGH |
| PMGR | APPLE-SPECIFIC | HIGH |
| Apple sysregs | APPLE-SPECIFIC | HIGH |
| Physical layout | APPLE-SPECIFIC (addresses) | HIGH |
| kASLR mechanism | APPLE-SPECIFIC | HIGH |

---

## Key Findings

### ARM-Generic Requirements (8)

1. MMU OFF at boot
2. x0 for platform data (concept)
3. RVBAR_ELx registers
4. Exception Level system
5. Generic Timer (CNTPCT_EL0, etc.)
6. Physical vs virtual addressing
7. DRAM existence
8. Interrupt controller (concept)

### Apple-Specific Requirements (16)

1. DRAM at 0x8_0000_0000
2. ADT format
3. Entry at 0x800 offset
4. boot_args structure
5. RVBAR locking behavior
6. UART at 0x2_3520_0000
7. AIC (non-GIC) controller
8. AIC timer MMIO mirrors
9. Watchdog at 0x2_3d2b_0000
10. PMGR at 0x2_3b70_0000
11. Apple system registers (HID, IPI, etc.)
12. Specific MMIO address ranges
13. kASLR implementation
14. XNU boot protocol
15. Dynamic ADT modification
16. Power management scheme

---

## Implications

### For Emulator Design

**ARM-Generic aspects**:
- Can leverage existing ARM64 emulation (QEMU)
- Standard ARM features (timers, ELs, MMU) reusable

**Apple-Specific aspects**:
- Require custom implementation
- Cannot assume generic ARM platform compatibility
- Must deviate from standard ARM64 virt machine

### For Validation

**ARM-Generic**: Can be validated against ARM ARM and generic ARM64 behavior

**Apple-Specific**: Requires Apple platform observation (m1n1, real hardware)

---

**Classification Date**: 2025-12-18  
**Source**: Phase 3b observations  
**Methodology**: ARM ARM reference + platform comparison
