# Emulator Responsibility Classification

**Purpose**: Determine what the emulator MUST provide vs what is boot software responsibility

**Date**: 2025-12-18

---

## Classification Methodology

**EMULATOR MUST**: Hardware-level features the emulator must simulate

**EMULATOR MUST NOT**: Software-level features that are boot software responsibility

**SHARED**: Features requiring both emulator and software cooperation

**UNKNOWN**: Insufficient information to classify

---

## DRAM Requirements

### Requirement: DRAM at 0x8_0000_0000

**Classification**: EMULATOR MUST

**Reasoning**:
- Physical memory mapping is hardware responsibility
- Guest software cannot create physical memory
- Emulator provides physical address space

**Responsibility Boundary**:
- Emulator: Map guest physical address to host memory
- Software: Cannot control physical memory existence

**Confidence**: HIGH

---

### Requirement: DRAM size reporting

**Classification**: SHARED

**Reasoning**:
- Emulator: Provides actual memory backing
- iBoot: Detects size and populates boot_args->mem_size
- Guest: Reads from boot_args

**Responsibility Boundary**:
- Emulator: Provide physical memory
- iBoot: Probe and report size
- boot_args: Communication mechanism

**Confidence**: MEDIUM (iBoot probing mechanism unknown)

---

## Device Tree Requirements

### Requirement: ADT structure in memory

**Classification**: EMULATOR MUST NOT (iBoot responsibility)

**Reasoning**:
- Phase 3b: "ADT dynamically modified by iBoot during boot"
- ADT generation: Boot software responsibility
- Emulator: Only provides memory to hold it

**Responsibility Boundary**:
- Emulator: Provide memory region
- iBoot: Generate/modify ADT
- Guest kernel: Consume ADT

**Evidence**: Phase 3b device-tree-observations.md states iBoot modifies ADT

**Confidence**: HIGH

---

### Requirement: ADT pointer in x0

**Classification**: EMULATOR MUST NOT (iBoot responsibility)

**Reasoning**:
- Register state at guest entry: Set by previous boot stage
- Emulator transfers control to iBoot
- iBoot sets x0 before jumping to kernel/m1n1

**Responsibility Boundary**:
- Emulator → iBoot: Some initial state (undefined in Phase 3b)
- iBoot → Kernel: x0 = boot_args pointer

**Confidence**: HIGH

---

## CPU State Requirements

### Requirement: MMU OFF at entry

**Classification**: EMULATOR MUST (initial), EMULATOR MUST NOT (maintain)

**Reasoning**:
- Emulator must initialize CPU with MMU disabled
- Once guest software enables MMU, emulator must support it
- MMU state is guest-controlled after initialization

**Responsibility Boundary**:
- Emulator: Initialize MMU disabled, provide MMU emulation
- Guest: Enable/configure MMU as needed

**Confidence**: HIGH

---

### Requirement: Entry at 0x800 offset

**Classification**: EMULATOR MUST NOT (iBoot responsibility)

**Reasoning**:
- 0x800 is entry point for kernel/m1n1 payload
- iBoot loads payload and jumps to +0x800
- Emulator loads iBoot, not final payload

**Responsibility Boundary**:
- Emulator: Load iBoot at its entry point
- iBoot: Load kernel/m1n1, jump to +0x800

**Evidence**: m1n1 dev guide states "entry point is at 0x800"—this is m1n1's entry, not iBoot's

**Confidence**: HIGH

---

### Requirement: RVBAR locked

**Classification**: EMULATOR MUST (if implementing)

**Reasoning**:
- RVBAR locking: Hardware behavior
- iBoot performs the lock (software action)
- Emulator must honor lock semantics if RVBAR is accessed

**Responsibility Boundary**:
- Emulator: Provide RVBAR register, enforce lock semantics
- iBoot: Write lock bit
- Hardware: Prevent further changes

**Note**: Lock enforcement is hardware behavior (emulator responsibility)

**Confidence**: MEDIUM (importance unclear)

---

### Requirement: Exception Level at entry

**Classification**: EMULATOR MUST (initial state)

**Reasoning**:
- CPU reset state: Hardware-defined
- Emulator must initialize CPU at correct EL
- Guest software changes EL via exception entry/return

**Responsibility Boundary**:
- Emulator: Set initial EL, provide EL transitions
- Guest: Use exception model as needed

**Note**: Specific EL unknown from Phase 3b

**Confidence**: HIGH (emulator responsibility), UNKNOWN (which EL)

---

## Platform Device Requirements

### Requirement: UART at 0x2_3520_0000

**Classification**: EMULATOR MUST

**Reasoning**:
- MMIO devices: Hardware responsibility
- Guest software cannot create hardware
- m1n1 immediately accesses UART (Phase 3b)

**Responsibility Boundary**:
- Emulator: Provide UART device at specified address
- Guest: Access UART for I/O

**Confidence**: HIGH

---

### Requirement: AIC at 0x2_3b10_0000

**Classification**: EMULATOR MUST

**Reasoning**:
- Interrupt controller: Core hardware component
- Required for interrupt delivery
- Guest software configures but cannot create

**Responsibility Boundary**:
- Emulator: Provide AIC hardware, deliver interrupts
- Guest: Configure AIC, handle interrupts

**Confidence**: HIGH

---

### Requirement: Watchdog at 0x2_3d2b_0000

**Classification**: EMULATOR MUST (if enforcing timeout)

**Reasoning**:
- Watchdog: Hardware component
- Guest must be able to disable/pet watchdog
- If emulator enforces timeout, must provide device

**Responsibility Boundary**:
- Emulator: Provide watchdog registers, enforce timeout
- Guest: Disable or service watchdog

**Note**: Emulator could stub watchdog (no-op) for simplicity

**Confidence**: MEDIUM (depends on enforcement choice)

---

### Requirement: PMGR at 0x2_3b70_0000

**Classification**: EMULATOR MUST (if device dependencies exist)

**Reasoning**:
- Power management: Hardware responsibility
- Phase 3b: "PMGR must be enabled before MMIO accessible"
- If devices require power-on, emulator must provide PMGR

**Responsibility Boundary**:
- Emulator: Provide PMGR, gate device access by power state
- Guest: Enable power domains before accessing devices

**Note**: Emulator could simplify (all devices always powered)

**Confidence**: MEDIUM (depends on device dependency enforcement)

---

### Requirement: Generic Timer (CNTPCT_EL0)

**Classification**: EMULATOR MUST

**Reasoning**:
- ARM architectural requirement
- System registers: Hardware responsibility
- Required for timing operations

**Responsibility Boundary**:
- Emulator: Provide timer registers, advance timer value
- Guest: Read timer, configure timer interrupts

**Confidence**: HIGH

---

### Requirement: Apple system registers (HID, IPI, etc.)

**Classification**: EMULATOR MUST (provide registers), MAY STUB (functionality)

**Reasoning**:
- System registers: Hardware feature
- Guest software may read/write these
- Emulator must not crash on access

**Responsibility Boundary**:
- Emulator: Provide register storage, accept writes
- Guest: Configure CPU features via these registers

**Note**: Emulator can implement as RAZ/WI (Read As Zero, Write Ignored) initially

**Confidence**: HIGH (must exist), MEDIUM (functionality depth)

---

## Memory Layout Requirements

### Requirement: Physical address space layout

**Classification**: EMULATOR MUST

**Reasoning**:
- Physical memory map: Hardware definition
- MMIO vs DRAM regions: Hardware responsibility
- Guest discovers via probing or device tree

**Responsibility Boundary**:
- Emulator: Define and enforce physical address space
- iBoot: Probe or read from hardware info
- ADT: Documents layout

**Confidence**: HIGH

---

### Requirement: boot_args structure

**Classification**: EMULATOR MUST NOT (iBoot responsibility)

**Reasoning**:
- boot_args: Software-defined structure
- Populated by iBoot before kernel entry
- Emulator never touches boot_args

**Responsibility Boundary**:
- Emulator: Provide memory
- iBoot: Create and populate boot_args
- Kernel: Consume boot_args

**Confidence**: HIGH

---

### Requirement: kASLR slide

**Classification**: EMULATOR MUST NOT (iBoot responsibility)

**Reasoning**:
- kASLR: Software security feature
- Randomization performed by bootloader
- Emulator provides memory, software chooses layout

**Responsibility Boundary**:
- Emulator: Provide sufficient memory space
- iBoot: Randomize kernel placement
- Kernel: Execute at randomized address

**Confidence**: HIGH

---

## Access Pattern Requirements

### Requirement: boot_args accessed first

**Classification**: EMULATOR MUST NOT (software behavior)

**Reasoning**:
- Access order: Software decision
- Emulator provides devices, software chooses access order
- Not hardware-enforced

**Responsibility Boundary**:
- Emulator: Provide all devices
- Guest: Choose access order

**Confidence**: HIGH

---

### Requirement: Device power-on sequence

**Classification**: SHARED (if enforced)

**Reasoning**:
- Power-on requirement: Hardware behavior
- Enforcement: Emulator could enforce or ignore
- Access pattern: Software responsibility

**Responsibility Boundary**:
- Emulator: Optionally enforce power dependencies
- Guest: Enable power before accessing devices

**Note**: Simplification possible (no enforcement)

**Confidence**: MEDIUM

---

## Summary Tables

### EMULATOR MUST Provide

| Requirement | Priority | Complexity |
|------------|----------|------------|
| DRAM at 0x8_0000_0000 | CRITICAL | Low |
| MMU emulation (initial OFF) | CRITICAL | Medium |
| UART at 0x2_3520_0000 | HIGH | Low |
| AIC at 0x2_3b10_0000 | HIGH | High |
| Generic Timer (CNTPCT_EL0) | HIGH | Low |
| Physical address space | CRITICAL | Low |
| Apple system registers (stubs) | MEDIUM | Low |
| Exception Level transitions | CRITICAL | Medium |
| RVBAR register | LOW | Low |

### EMULATOR MUST NOT Provide

| Requirement | Responsibility |
|------------|----------------|
| ADT generation/modification | iBoot |
| boot_args structure | iBoot |
| boot_args pointer in x0 | iBoot |
| kASLR randomization | iBoot |
| Entry at 0x800 (final payload) | iBoot |
| Device access ordering | Guest software |

### SHARED Responsibilities

| Requirement | Emulator Part | Software Part |
|------------|---------------|---------------|
| DRAM size | Provide memory | Detect and report |
| PMGR | Provide device | Enable power domains |
| Watchdog | Provide device | Disable/service |
| Device power sequence | Enforce (optional) | Follow sequence |

### MAY SIMPLIFY (Not Strictly Required)

| Requirement | Simplification Option |
|------------|----------------------|
| RVBAR locking | Ignore (not critical for boot) |
| Watchdog enforcement | Stub (no timeout) |
| PMGR enforcement | All devices always on |
| Apple sysregs functionality | RAZ/WI (stub) |

---

## Critical Boundaries

### Emulator ↔ iBoot Boundary

**Emulator provides**:
- Physical memory
- CPU initial state
- MMIO devices
- iBoot binary in memory

**iBoot provides**:
- ADT generation
- boot_args structure
- Kernel loading
- boot_args pointer in x0

### iBoot ↔ Kernel Boundary

**iBoot provides**:
- ADT with hardware info
- boot_args with memory layout
- Kernel loaded in memory
- x0 = boot_args pointer
- MMU OFF, entry at +0x800

**Kernel provides**:
- MMU configuration
- Interrupt handling
- Device drivers

---

## Unknown Boundaries

### Question: Who initializes x0 for iBoot?

**Current State**: UNKNOWN

**Evidence**: Phase 3b documents iBoot→Kernel transition (x0=boot_args), but not Emulator→iBoot

**Impact**: Affects initial CPU state setup

---

### Question: Who sets stack pointer for iBoot?

**Current State**: UNKNOWN

**Evidence**: Not documented in Phase 3b

**Impact**: Affects initial CPU state setup

---

### Question: Does iBoot require initial device state?

**Current State**: UNKNOWN

**Evidence**: Phase 3b documents kernel requirements, not iBoot requirements

**Impact**: Affects what emulator must initialize before iBoot runs

---

### Question: How does iBoot detect DRAM size?

**Current State**: UNKNOWN

**Evidence**: Phase 3b mentions boot_args->mem_size but not detection mechanism

**Impact**: May require additional emulator features (probe-able hardware info)

---

## Implementation Priorities

### Phase 1 (Minimum for iBoot execution)

EMULATOR MUST:
1. DRAM at 0x8_0000_0000
2. MMU disabled initial state
3. Physical address space defined
4. CPU at correct initial EL
5. iBoot binary loaded

EMULATOR MAY DEFER:
- Devices (if iBoot doesn't immediately access)
- ADT (iBoot generates)
- Complex features

### Phase 2 (Minimum for kernel boot)

ADDITIONAL EMULATOR MUST:
1. UART (kernel console)
2. AIC (interrupts)
3. Generic Timer
4. Devices accessed by kernel

STILL NOT EMULATOR:
- boot_args (iBoot creates)
- ADT final form (iBoot modifies)

---

## Validation Criteria

### For Emulator Hardware

**Test**: Does guest software see expected hardware?
- Memory at correct addresses
- Devices at correct addresses
- Registers behave correctly

### For Software Responsibilities

**Test**: Does boot software correctly:
- Generate ADT?
- Populate boot_args?
- Configure hardware?

**Not Emulator's Job**: If boot software fails these, emulator is not at fault

---

**Classification Date**: 2025-12-18  
**Source**: Phase 3b observations  
**Methodology**: Hardware vs software responsibility analysis
