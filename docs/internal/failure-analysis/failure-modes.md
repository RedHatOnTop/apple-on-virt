# Failure Mode Inventory

This document catalogs expected failure modes during Apple-on-Virt bring-up. Each entry describes symptoms, likely layer, and observability without proposing fixes.

## Failure Classification

### Symptom Categories

- **Silent Hang**: Execution stops with no output.
- **Panic**: Kernel panic with error message and stack trace.
- **Abort**: Emulator aborts with error message.
- **Loop**: Infinite loop with repeating log output.
- **Partial Boot**: Boot progresses but stops at specific stage.

### Layer Attribution

- **Platform Boot Layer**: Failure during platform synthesis before iBoot.
- **Machine Model**: Failure during initialization coordination.
- **CPU Model**: Failure during instruction execution or exception handling.
- **Device Layer**: Failure in device emulation or interaction.
- **Boot Chain**: Failure in iBoot, boot.efi, or kernelcache execution.

### Observability Levels

- **High**: Clear error messages, logs, and diagnostic output.
- **Medium**: Some indication of failure point through serial or logs.
- **Low**: Minimal output, requires debugging tools.
- **None**: Complete silence, only detectable through lack of progress.

## Platform Boot Layer Failures

### FM-PBL-001: Invalid Memory Map

**Symptom:**
- Silent hang immediately after emulator start.
- No serial output.
- CPU never begins execution.

**Likely Layer:**
Platform Boot Layer - Memory Map Construction

**Observability:**
None - Emulator fails silently without reaching any guest code.

**Diagnostic Approach:**
- GDB attachment to check if CPU PC is set.
- Emulator log inspection (if logging enabled).
- Memory map dump from emulator state.

### FM-PBL-002: Malformed Device Tree

**Symptom:**
- iBoot starts but hangs during hardware discovery.
- Serial output shows iBoot entry.
- No progress beyond "Initializing hardware".

**Likely Layer:**
Platform Boot Layer - Device Tree Generation

**Observability:**
Medium - iBoot serial output indicates entry but no further progress.

**Diagnostic Approach:**
- Dump generated device tree blob.
- Validate device tree format with dtc tool.
- Check required node presence.

### FM-PBL-003: Incorrect Secure Boot Context

**Symptom:**
- iBoot panics with "Security verification failed".
- Panic message indicates untrusted boot path.
- Stack trace shows security check function.

**Likely Layer:**
Platform Boot Layer - Secure Boot Context Synthesis

**Observability:**
High - Clear panic message and stack trace.

**Diagnostic Approach:**
- Read panic message for specific security check.
- Inspect secure boot register values.
- Compare with expected secure boot state.

### FM-PBL-004: Inconsistent Platform Identity

**Symptom:**
- Boot progresses to boot.efi then panics.
- Panic message: "Platform ID mismatch".
- Device tree shows one identity, registers show another.

**Likely Layer:**
Platform Boot Layer - Platform Identity Initialization

**Observability:**
High - Explicit panic about identity mismatch.

**Diagnostic Approach:**
- Compare platform ID in device tree and registers.
- Check all platform identity query points.
- Verify consistency across sources.

## Machine Model Failures

### FM-MM-001: Initialization Order Violation

**Symptom:**
- Emulator crashes with segmentation fault.
- Crash occurs during startup.
- No guest code executes.

**Likely Layer:**
Machine Model - Initialization Sequence Coordination

**Observability:**
High - Emulator crash with stack trace.

**Diagnostic Approach:**
- Check emulator crash backtrace.
- Identify which component accessed before initialization.
- Review initialization order in machine model.

### FM-MM-002: CPU Not Created

**Symptom:**
- Emulator starts but no execution occurs.
- PC remains at 0x0.
- No interrupts or exceptions.

**Likely Layer:**
Machine Model - CPU Instance Creation

**Observability:**
Low - Silent failure, requires GDB to observe.

**Diagnostic Approach:**
- Attach GDB and check CPU state.
- Verify CPU instance exists in emulator state.
- Check CPU realization status.

### FM-MM-003: iBoot Load Failure

**Symptom:**
- Emulator starts but CPU executes zeros.
- Invalid instruction exceptions.
- PC at iBoot address but no valid code.

**Likely Layer:**
Machine Model - iBoot Binary Loading

**Observability:**
Medium - Invalid instruction exceptions indicate problem.

**Diagnostic Approach:**
- Dump memory at iBoot load address.
- Verify iBoot binary file exists and is readable.
- Check file size matches expected range.

### FM-MM-004: Entry Point Incorrect

**Symptom:**
- CPU executes but not iBoot code.
- Executes random memory location.
- Immediate exception or hang.

**Likely Layer:**
Machine Model - Entry Point Setting

**Observability:**
Low - Requires GDB to observe PC value.

**Diagnostic Approach:**
- Check CPU PC value at start.
- Verify against expected iBoot entry point.
- Confirm entry point calculation.

## CPU Model Failures

### FM-CPU-001: PAC Instruction Fault

**Symptom:**
- Kernel panic during early initialization.
- Panic message: "Illegal instruction" or similar.
- Stack trace shows PAC instruction use.

**Likely Layer:**
CPU Model - PAC Instruction Implementation

**Observability:**
High - Kernel panic with clear indication.

**Diagnostic Approach:**
- Identify faulting instruction from panic.
- Verify PAC instruction is implemented.
- Check PAC key register initialization.

### FM-CPU-002: Exception Level Transition Hang

**Symptom:**
- Silent hang during boot chain.
- Last serial output: "Entering EL1" or similar.
- No further progress.

**Likely Layer:**
CPU Model - Exception Level Management

**Observability:**
Low - Last message may indicate stage, but hang is silent.

**Diagnostic Approach:**
- Attach GDB and check current EL.
- Inspect SPSR, ELR registers.
- Single-step through exception transition.

### FM-CPU-003: System Register Access Fault

**Symptom:**
- Kernel panic: "Undefined system register".
- Panic shows MSR/MRS instruction.
- Register name in error message.

**Likely Layer:**
CPU Model - System Register Access

**Observability:**
High - Clear panic with register name.

**Diagnostic Approach:**
- Note missing register from panic.
- Check if register is implemented in CPU model.
- Verify register accessibility from current EL.

### FM-CPU-004: MMU Translation Failure

**Symptom:**
- Kernel panic: "Data abort" or "Instruction abort".
- Panic during page table setup.
- Address shown in panic message.

**Likely Layer:**
CPU Model - Memory Translation (MMU)

**Observability:**
High - Data/instruction abort with address.

**Diagnostic Approach:**
- Note faulting address from panic.
- Inspect page table entries for that address.
- Verify translation table walk logic.

### FM-CPU-005: Incorrect Feature Register Values

**Symptom:**
- Kernel panic: "Unsupported CPU".
- Panic during CPU feature detection.
- Specific feature check mentioned.

**Likely Layer:**
CPU Model - Feature Register Reporting

**Observability:**
High - Panic indicates which feature check failed.

**Diagnostic Approach:**
- Identify which feature register was checked.
- Verify reported value matches Apple Silicon expectations.
- Check if feature is actually unsupported or misreported.

## Device Layer Failures

### FM-DEV-001: Timer Not Functioning

**Symptom:**
- Boot hangs after "Initializing timers".
- Serial output stops at timer init.
- No timer interrupts delivered.

**Likely Layer:**
Device Layer - Timer Device Implementation

**Observability:**
Medium - Last message indicates timer initialization stage.

**Diagnostic Approach:**
- Check if timer device is instantiated.
- Verify timer registers are accessible.
- Confirm interrupt routing from timer to CPU.

### FM-DEV-002: Interrupt Controller Not Responding

**Symptom:**
- Boot progresses but hangs waiting for interrupt.
- "Waiting for device" message loops.
- Interrupt never acknowledged.

**Likely Layer:**
Device Layer - Interrupt Controller Implementation

**Observability:**
Medium - Waiting message indicates expected interrupt.

**Diagnostic Approach:**
- Check interrupt controller register access.
- Verify interrupt assertion mechanism.
- Trace interrupt path from device to CPU.

### FM-DEV-003: Storage Device Not Found

**Symptom:**
- boot.efi panic: "No boot device".
- Panic after iBoot completes.
- Device tree shows storage device.

**Likely Layer:**
Device Layer - Storage Device Implementation

**Observability:**
High - Clear panic about missing storage.

**Diagnostic Approach:**
- Verify storage device in device tree.
- Check storage device register accessibility.
- Confirm storage device response to probe.

### FM-DEV-004: Serial Console Silent

**Symptom:**
- No serial output at all.
- Emulator appears to run.
- No indication of boot progress.

**Likely Layer:**
Device Layer - Serial Device Implementation

**Observability:**
None - No output to observe.

**Diagnostic Approach:**
- Check serial device instantiation.
- Verify serial register address mapping.
- Test with GDB to see if writes occur.

### FM-DEV-005: Device Identity Mismatch

**Symptom:**
- Kernel panic: "Unknown device".
- Panic during driver loading.
- Device tree shows Apple device but driver doesn't match.

**Likely Layer:**
Device Layer - Device Identity Presentation

**Observability:**
High - Panic names specific device.

**Diagnostic Approach:**
- Check device tree compatible string.
- Verify compatible string matches Apple driver expectations.
- Confirm device registers match expected layout.

## Boot Chain Failures

### FM-BC-001: iBoot Entry Failure

**Symptom:**
- Silent hang immediately after CPU starts.
- No serial output from iBoot.
- PC at iBoot address but no progress.

**Likely Layer:**
Boot Chain - iBoot Execution

**Observability:**
None - No output, only detectable via GDB.

**Diagnostic Approach:**
- Attach GDB and single-step from entry.
- Check first few instructions execute correctly.
- Verify stack pointer and CPU state.

### FM-BC-002: iBoot Device Tree Parse Failure

**Symptom:**
- iBoot outputs: "Device tree invalid".
- Stops after attempting device tree parse.
- May show offset or error code.

**Likely Layer:**
Boot Chain - iBoot Execution

**Observability:**
High - iBoot error message indicates problem.

**Diagnostic Approach:**
- Validate device tree format.
- Check device tree magic number and version.
- Verify device tree placement in memory.

### FM-BC-003: boot.efi Not Found

**Symptom:**
- iBoot panic: "Cannot load boot.efi".
- Panic after storage device initialization.
- iBoot unable to locate boot.efi on disk.

**Likely Layer:**
Boot Chain - iBoot to boot.efi Transition

**Observability:**
High - iBoot panic message is clear.

**Diagnostic Approach:**
- Verify boot.efi exists in expected location on disk.
- Check disk image format is correct.
- Confirm storage device reads data correctly.

### FM-BC-004: boot.efi Security Check Failure

**Symptom:**
- boot.efi panic: "Verification failed".
- Panic immediately after boot.efi starts.
- Security context check failed.

**Likely Layer:**
Boot Chain - boot.efi Execution

**Observability:**
High - boot.efi panic with security message.

**Diagnostic Approach:**
- Check secure boot context values.
- Verify security state consistency from iBoot handoff.
- Review boot.efi security expectations.

### FM-BC-005: Kernelcache Load Failure

**Symptom:**
- boot.efi panic: "Cannot load kernel".
- Panic after attempting kernelcache load.
- May indicate insufficient memory or file not found.

**Likely Layer:**
Boot Chain - boot.efi to Kernel Transition

**Observability:**
High - boot.efi panic indicates specific issue.

**Diagnostic Approach:**
- Verify kernelcache file exists on disk.
- Check available memory for kernel load.
- Confirm kernelcache format is valid.

### FM-BC-006: Kernel Entry Point Invalid

**Symptom:**
- Silent hang after boot.efi completes.
- "Kernel started" message but no kernel output.
- No panic, no progress.

**Likely Layer:**
Boot Chain - Kernel Entry

**Observability:**
Low - Last message from boot.efi, then silence.

**Diagnostic Approach:**
- Attach GDB and check kernel entry point.
- Verify kernel PC value.
- Single-step first kernel instructions.

### FM-BC-007: Kernel Panic During Early Init

**Symptom:**
- Kernel panic with stack trace.
- Panic during "Initializing" messages.
- Specific subsystem mentioned in panic.

**Likely Layer:**
Boot Chain - Kernel Initialization

**Observability:**
High - Full kernel panic output.

**Diagnostic Approach:**
- Read panic message for specific failure.
- Check stack trace for failing function.
- Identify what platform assumption was violated.

## Multi-Layer Failures

### FM-ML-001: Timing-Related Hang

**Symptom:**
- Hang at various boot stages.
- Sometimes progresses further, sometimes fails earlier.
- Non-deterministic behavior.

**Likely Layer:**
CPU Model or Device Layer - Timer/Interrupt Timing

**Observability:**
Low - Hang location varies, hard to reproduce consistently.

**Diagnostic Approach:**
- Check timer frequency configuration.
- Verify interrupt delivery timing.
- Look for race conditions in device emulation.

### FM-ML-002: Memory Corruption

**Symptom:**
- Kernel panic with corrupted data structures.
- Panic message about invalid pointers.
- Random crashes at different points.

**Likely Layer:**
CPU Model (MMU) or Device Layer (DMA)

**Observability:**
Medium - Panic shows corruption but not cause.

**Diagnostic Approach:**
- Check MMU permission enforcement.
- Verify DMA operations respect boundaries.
- Look for memory aliasing issues.

### FM-ML-003: Interrupt Storm

**Symptom:**
- System becomes unresponsive.
- Serial output shows repeated interrupt messages.
- CPU spending all time in interrupt handlers.

**Likely Layer:**
Device Layer (Interrupt Controller or Device)

**Observability:**
High - Repeated interrupt messages visible.

**Diagnostic Approach:**
- Identify interrupt source from messages.
- Check if interrupt is being acknowledged properly.
- Verify interrupt masking works correctly.

## Observability Strategies

### High Observability Failures

Failures with clear diagnostic output:
- Review error messages and stack traces.
- Note exact failure point and context.
- Cross-reference with platform assumptions.

### Medium Observability Failures

Failures with partial output:
- Note last successful message.
- Identify stage where failure occurs.
- Use GDB to inspect state at hang point.

### Low Observability Failures

Failures with minimal output:
- Attach GDB immediately at start.
- Single-step through critical sections.
- Enable emulator debug logging.
- Add instrumentation to suspected code.

### No Observability Failures

Silent failures requiring investigation:
- Use GDB to check if any execution occurred.
- Verify emulator initialization completed.
- Check if CPU state was set up.
- Instrument emulator code to add logging.

## Failure Documentation Template

When encountering a new failure mode:

```
### FM-XXX-NNN: Descriptive Name

**Symptom:**
- Observable behavior
- What the user sees
- Messages or output

**Likely Layer:**
Component where failure originates

**Observability:**
High/Medium/Low/None - Description of available diagnostics

**Diagnostic Approach:**
- Steps to investigate
- Tools to use
- What to check

**Notes:**
- Additional context
- Similar failures
- Known variations
```

## Failure Priority

### Critical Failures

Prevent any boot progress:
- Platform Boot Layer failures preventing iBoot entry
- CPU Model failures causing immediate exceptions
- Missing essential devices

### Major Failures

Allow partial boot but prevent completion:
- Device identity mismatches
- Kernel panics during initialization
- Boot chain verification failures

### Minor Failures

Allow boot to progress significantly:
- Non-critical device missing
- Optional feature unavailable
- Performance degradation

## Debugging Tool Reference

### GDB Commands for Failure Investigation

```
# Check CPU state
info registers

# View current exception level
p/x $PSTATE

# Examine memory at address
x/16x 0xaddress

# View stack trace
bt

# Single-step instruction
si

# Continue to address
advance *0xaddress
```

### Emulator Debug Options

- Enable instruction tracing
- Enable device register access logging
- Enable interrupt delivery tracing
- Enable MMU translation logging

## Failure Pattern Recognition

### Common Patterns

**Silent Hang Pattern:**
- No output, no error
- Usually Platform Boot Layer or entry point issue
- Check initialization and CPU state setup

**Panic Pattern:**
- Clear error message
- Usually platform assumption violation
- Read message carefully for specific requirement

**Loop Pattern:**
- Repeated messages
- Usually interrupt or timing issue
- Check device acknowledgment and interrupt masking

**Progressive Failure Pattern:**
- Gets further with each fix
- Multiple platform assumptions missing
- Address one at a time in boot order

## Summary

This inventory catalogs failure modes expected during bring-up without proposing solutions. Identification and proper diagnosis are the first steps to systematic platform fidelity improvement.
