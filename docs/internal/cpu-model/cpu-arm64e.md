# arm64e CPU Semantics

This document describes the apple-arm64e CPU model behavior, explaining why macOS accepts this CPU as valid and how semantic correctness is achieved.

## CPU Model Identity

### What apple-arm64e Is

The apple-arm64e CPU model is a purpose-built implementation of ARM64 instruction semantics as required by macOS arm64e binaries. It provides:

- Correct observable behavior for instructions executed during macOS boot.
- Pointer authentication (PAC) semantics that satisfy kernel expectations.
- Exception level management matching Apple Silicon behavior.
- System register values that macOS recognizes as valid.

### What apple-arm64e Is Not

The apple-arm64e CPU model is not:

- A generic ARMv8-A or ARMv8.3-A implementation.
- A cycle-accurate hardware simulator.
- A complete implementation of all ARM architectural extensions.
- A performance-equivalent representation of Apple Silicon.

## Architectural Assumptions

### macOS arm64e Expectations

macOS arm64e binaries assume they are running on Apple Silicon with specific capabilities:

**Instruction Set:**
- Full AArch64 base instruction set.
- Pointer authentication instructions (PAC).
- Memory barrier and synchronization instructions.
- System register access instructions.

**Exception Model:**
- Four exception levels (EL0, EL1, EL2, EL3).
- Proper exception entry and return behavior.
- Correct vector table layout and dispatch.
- Interrupt handling through exception vectors.

**Memory Model:**
- Virtual memory with page table translation.
- Memory attributes and permissions.
- Cache coherency semantics (even if caches not modeled).
- Proper address translation fault handling.

**Security Features:**
- Pointer authentication codes on function returns.
- PAC key registers initialized and accessible.
- Execution permission controls.
- Privilege level enforcement.

### Emulator Fulfillment

The apple-arm64e CPU satisfies these assumptions by:

- Implementing instruction semantics that produce correct results.
- Managing exception levels with proper privilege transitions.
- Providing MMU operations that maintain memory isolation.
- Supporting PAC instructions with semantic correctness.

## Required Semantics

### Instruction Execution

**Base Instructions:**

All instructions in the AArch64 base instruction set execute with correct observable effects:

- Arithmetic operations produce correct results.
- Logical operations follow ARM specifications.
- Memory operations access correct addresses.
- Control flow instructions change execution appropriately.

**PAC Instructions:**

Pointer authentication instructions execute with semantic correctness:

```
PACIA, PACIB, PACDA, PACDB:
    - Generate authenticated pointers.
    - Result contains pointer with authentication code.
    - Semantic: pointer is marked as "signed by this context."

AUTIA, AUTIB, AUTDA, AUTDB:
    - Verify and strip authentication codes.
    - Semantic: pointer is verified as "signed by expected context."
    - On semantic match: return original pointer.
    - On semantic mismatch: fault or return poisoned pointer.

XPACI, XPACD:
    - Strip authentication codes without verification.
    - Return original pointer value.
```

**System Instructions:**

System instructions that affect CPU state execute correctly:

- MSR/MRS for system register access.
- Exception-generating instructions (SVC, HVC, SMC).
- Memory barrier instructions (DMB, DSB, ISB).
- Cache maintenance instructions (behavior may be stubbed).

### Exception Level Behavior

**EL Transitions:**

Exception level transitions follow ARM architecture rules:

```
Exception Entry:
    - Save PSTATE to SPSR_ELx.
    - Save return address to ELR_ELx.
    - Set PSTATE to exception handler mode.
    - Branch to vector table entry.

Exception Return (ERET):
    - Restore PSTATE from SPSR_ELx.
    - Branch to address in ELR_ELx.
    - Continue at target exception level.
```

**Supported Transitions:**

- EL0 to EL1 (syscall, exceptions).
- EL1 to EL1 (kernel exceptions).
- EL1 to EL2 (hypervisor calls, if used).
- Returns from any higher EL to lower EL.

**Boot-Time Transitions:**

During boot, the kernel may execute from EL2 and transition to EL1:

- iBoot may start in EL3 or EL2.
- Kernel typically runs in EL1.
- Proper transition handling is critical for boot success.

### System Register Behavior

**Feature Identification Registers:**

These registers report CPU capabilities to software:

```
ID_AA64PFR0_EL1:
    - Reports exception level support.
    - Reports floating-point and SIMD support.
    - Value must indicate EL0-EL2 support.

ID_AA64PFR1_EL1:
    - Reports additional features.
    - PAC support must be indicated.

ID_AA64MMFR0_EL1:
    - Reports memory model features.
    - Physical address range.
    - Granule size support.

ID_AA64ISAR1_EL1:
    - Reports instruction set extensions.
    - PAC algorithm support.
```

**Control Registers:**

Control registers affect CPU behavior:

```
SCTLR_EL1:
    - MMU enable/disable.
    - Cache enable/disable.
    - Endianness control.

TCR_EL1:
    - Translation control.
    - Granule size selection.
    - Address space size.

TTBR0_EL1, TTBR1_EL1:
    - Page table base addresses.
    - ASID for address space tagging.
```

**PAC Key Registers:**

PAC keys must be initialized and accessible:

```
APIAKey, APIBKey:
    - Instruction pointer authentication keys.

APDAKey, APDBKey:
    - Data pointer authentication keys.

APGAKey:
    - Generic authentication key.
```

### Memory Management

**Translation Tables:**

The MMU performs address translation:

- Parse translation table entries.
- Apply correct granule size (4KB, 16KB, 64KB).
- Generate translation faults on invalid entries.
- Respect permission bits.

**Memory Attributes:**

Memory regions have attributes:

- Device memory: non-cacheable, ordered.
- Normal memory: cacheable, may reorder.
- Execute permission: controls instruction fetch.
- Read/write permission: controls data access.

**Fault Handling:**

Memory access faults generate exceptions:

- Translation faults for unmapped addresses.
- Permission faults for access violations.
- Alignment faults for misaligned accesses.

## Abstracted Behaviors

### PAC Cryptographic Operations

**What is abstracted:**

The actual cryptographic computation for pointer authentication is abstracted. Real Apple Silicon uses QARMA or similar algorithms with hardware keys.

**Semantic replacement:**

Instead of cryptographic computation:

```
Sign Operation:
    - Mark pointer as "authenticated" with context.
    - Store context identifier in unused pointer bits.
    - No cryptographic transformation.

Verify Operation:
    - Check that context identifier matches expected.
    - If match: return original pointer.
    - If mismatch: generate fault or poisoned pointer.
```

**Why this works:**

macOS kernel code signs and verifies its own pointers. During boot:

- Kernel signs return addresses on function entry.
- Kernel verifies return addresses on function exit.
- Context is consistent because same code signs and verifies.
- Semantic verification always succeeds for well-formed code.

**Limitations:**

- Cannot detect actual pointer corruption.
- Does not provide real security against attacks.
- Sufficient for boot but not security validation.

### Cycle-Accurate Timing

**What is abstracted:**

Instruction timing is not modeled:

- No pipeline simulation.
- No cache latency modeling.
- No memory access timing.
- No branch prediction effects.

**Why this works:**

macOS boot code does not depend on precise timing:

- No busy-wait loops calibrated to cycle counts.
- Timeout loops use timer registers, not cycle counting.
- Performance monitoring not required for boot.

**Limitations:**

- Cannot measure actual performance.
- Time-sensitive code may behave differently.
- Performance counters return synthetic values.

### Speculative Execution

**What is abstracted:**

Speculative execution is not modeled:

- No branch prediction.
- No speculative memory access.
- No out-of-order execution effects.

**Why this works:**

Speculative execution affects performance and security side-channels but not functional correctness:

- Correct program behavior is the same with or without speculation.
- Security side-channels are not emulator requirements.

**Limitations:**

- Cannot study speculative execution vulnerabilities.
- Performance characteristics differ from hardware.

### Power Management

**What is abstracted:**

CPU power states are not implemented:

- No deep sleep states.
- No frequency scaling.
- No power gating.

**Why this works:**

During boot, the CPU is fully powered:

- Boot code assumes CPU is running.
- Power management initialization happens later.
- Emulator runs as if always at full power.

**Limitations:**

- Cannot study power management behavior.
- Later kernel phases may encounter stubs.

### Hardware Performance Counters

**What is abstracted:**

Performance monitoring registers return plausible but non-functional values:

- Cycle counter returns monotonically increasing value.
- Event counters return zero or synthetic values.
- PMU configuration has no effect.

**Why this works:**

Boot code does not require performance data:

- No boot-time performance optimization.
- PMU used for debugging and profiling, not correctness.

**Limitations:**

- Cannot profile emulator performance accurately.
- Performance analysis tools will not work correctly.

## Known Limitations

### Incomplete Instruction Coverage

Not all ARMv8.x instructions may be implemented:

- Advanced SIMD instructions beyond basic needs.
- Cryptographic instructions (AES, SHA).
- Optional architectural extensions.

**Impact:**

- Boot may succeed if unused.
- Later userspace may encounter unimplemented instructions.
- Can be extended incrementally as needed.

### Simplified Exception Model

Exception handling is functionally correct but simplified:

- Nested exception handling may have edge cases.
- Precise exception reporting may differ from hardware.
- Debug exceptions may be incomplete.

**Impact:**

- Boot typically uses straightforward exception patterns.
- Kernel debugging features may not work fully.

### Memory Model Relaxation

Memory ordering may be stricter than hardware:

- Emulator may serialize more than necessary.
- Barrier instructions always fully synchronize.

**Impact:**

- Correct but potentially slower than hardware.
- Race conditions may manifest differently.

### Single-Core Boot

Multi-core behavior is not implemented for initial boot:

- SMP initialization not supported in early phases.
- Core startup sequences not implemented.

**Impact:**

- Boot proceeds on single core.
- Later kernel SMP init will require extension.

## Why macOS Accepts This CPU

### Feature Register Compatibility

macOS queries feature registers during boot:

1. **ID_AA64PFR0_EL1** indicates EL support.
   - Emulator reports EL0, EL1, EL2 support.
   - Matches minimum Apple Silicon capabilities.

2. **ID_AA64ISAR1_EL1** indicates PAC support.
   - Emulator reports PAC implementation.
   - Kernel enables PAC usage.

3. **ID_AA64MMFR0_EL1** indicates memory capabilities.
   - Emulator reports compatible memory model.
   - Kernel configures page tables accordingly.

### Behavioral Compatibility

macOS validates CPU behavior during execution:

1. **PAC Instructions Execute:**
   - Kernel signs return addresses.
   - Semantic PAC produces expected results.
   - No PAC verification failures occur.

2. **Exception Handling Works:**
   - Syscalls transition correctly.
   - Interrupts deliver to proper handlers.
   - Exception return restores state.

3. **Memory Operations Function:**
   - Page table walks succeed.
   - Memory protection enforced.
   - Kernel memory model works.

### Trust Context Alignment

CPU state aligns with secure boot context:

1. **PAC Keys Initialized:**
   - Keys set before kernel entry.
   - Consistent across boot stages.

2. **Exception Level Appropriate:**
   - Kernel enters at expected EL.
   - Privilege transitions legal.

3. **System Registers Consistent:**
   - Control registers in valid state.
   - No conflicting configuration.

## Validation Criteria

### CPU Model Acceptance

The CPU model is accepted by macOS when:

- Feature registers report compatible capabilities.
- PAC instructions execute without faulting.
- Exception handling delivers to correct vectors.
- Memory operations access correct addresses.
- System registers contain expected values.

### Boot Progression

The CPU model supports boot when:

- iBoot executes to completion on this CPU.
- boot.efi executes to completion on this CPU.
- Kernel begins initialization without CPU-related panics.
- Early kernel execution proceeds normally.

### Semantic Correctness

The CPU model is semantically correct when:

- All executed instructions produce correct visible results.
- Abstracted behaviors do not cause incorrect program flow.
- macOS code paths execute as they would on hardware.