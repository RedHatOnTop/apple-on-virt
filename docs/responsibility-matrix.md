# Responsibility Matrix

This document defines the responsibility assignment for all major components in Apple-on-Virt. Every responsibility belongs to exactly one component to prevent architectural drift and ambiguity.

## Matrix Overview

The matrix uses the following notation:
- **R** - Responsible: This component owns and implements this responsibility.
- **I** - Informed: This component is notified of actions but does not participate.
- **-** - Not involved: This component has no role in this responsibility.

## Component Definitions

- **Platform Boot Layer**: Synthesizes platform state before boot.
- **Machine Model**: Coordinates platform initialization and configuration.
- **CPU Model**: Executes instructions and manages processor state.
- **Device Layer**: Provides hardware interfaces to macOS.
- **Kernel Interface**: Mediates between emulator and executing kernel (if accommodations needed).

## Core Responsibilities Matrix

| Responsibility | Platform Boot Layer | Machine Model | CPU Model | Device Layer | Kernel Interface |
|----------------|---------------------|---------------|-----------|--------------|------------------|
| Memory Map Construction | R | I | - | - | - |
| Device Tree Generation | R | I | - | I | - |
| Secure Boot Context Synthesis | R | I | - | - | - |
| Platform Identity Initialization | R | I | - | - | - |
| CPU Instance Creation | - | R | I | - | - |
| Device Instance Creation | - | R | - | I | - |
| Initialization Sequence Coordination | - | R | I | I | - |
| iBoot Binary Loading | - | R | - | - | - |
| Instruction Execution | - | - | R | - | - |
| Exception Level Management | - | - | R | - | - |
| PAC Instruction Implementation | - | - | R | - | - |
| System Register Access | - | - | R | - | - |
| Memory Translation (MMU) | - | - | R | - | - |
| Device Register Access Handling | - | - | R | I | - |
| Timer Device Implementation | - | - | - | R | - |
| Interrupt Controller Implementation | - | - | - | R | - |
| Storage Device Implementation | - | - | - | R | - |
| Serial Device Implementation | - | - | - | R | - |
| Interrupt Delivery to CPU | - | - | I | R | - |
| DMA Operations | - | - | I | R | - |
| Kernel Accommodation Implementation | - | - | - | - | R |
| Failure Point Interception | - | - | - | - | R |

## Detailed Responsibility Assignments

### Platform Boot Layer Responsibilities

**R - Memory Map Construction**
- Define DRAM region boundaries.
- Define MMIO region boundaries.
- Define reserved region boundaries.
- Ensure no overlapping regions.
- Follow Apple Silicon memory conventions.

**R - Device Tree Generation**
- Create root node with platform properties.
- Add device nodes for all devices.
- Set compatible strings for driver matching.
- Populate register addresses and interrupt assignments.
- Include Apple-specific security nodes.

**R - Secure Boot Context Synthesis**
- Set secure boot state registers.
- Initialize boot stage flags.
- Create trusted execution indicators.
- Synthesize verification status.

**R - Platform Identity Initialization**
- Set platform ID value.
- Set board ID value.
- Set chip ID value.
- Ensure consistency across all queries.

**Non-Responsibilities:**
- Does not execute any macOS code.
- Does not modify boot binaries.
- Does not handle runtime operations.
- Does not manage devices during execution.

### Machine Model Responsibilities

**R - CPU Instance Creation**
- Instantiate apple-arm64e CPU Model.
- Configure CPU with platform parameters.
- Connect CPU to memory system.
- Set CPU entry point.

**R - Device Instance Creation**
- Instantiate all required devices.
- Configure device parameters.
- Register devices with memory system.
- Connect device interrupts.

**R - Initialization Sequence Coordination**
- Invoke Platform Boot Layer synthesis first.
- Create CPU Model after platform state ready.
- Create Device Layer after CPU exists.
- Generate Device Tree after all components ready.
- Load iBoot as final initialization step.

**R - iBoot Binary Loading**
- Read iBoot binary from file.
- Place iBoot at correct memory address.
- Verify basic binary sanity.
- Set CPU PC to iBoot entry point.

**Non-Responsibilities:**
- Does not synthesize platform state (Platform Boot Layer does this).
- Does not execute instructions (CPU Model does this).
- Does not implement device behavior (Device Layer does this).
- Does not accommodate kernel issues (Kernel Interface does this).

### CPU Model Responsibilities

**R - Instruction Execution**
- Decode arm64e instructions.
- Execute instructions with correct semantics.
- Update architectural state appropriately.
- Handle undefined instructions.

**R - Exception Level Management**
- Maintain current Exception Level (EL).
- Handle exception entry transitions.
- Handle exception return (ERET) transitions.
- Enforce privilege restrictions per EL.

**R - PAC Instruction Implementation**
- Implement PACIA, PACIB, PACDA, PACDB (signing).
- Implement AUTIA, AUTIB, AUTDA, AUTDB (verification).
- Implement XPACI, XPACD (stripping).
- Maintain PAC key registers.
- Provide semantic correctness for PAC operations.

**R - System Register Access**
- Implement MSR/MRS instructions.
- Provide register storage.
- Enforce access permissions per EL.
- Return macOS-expected values for feature registers.

**R - Memory Translation (MMU)**
- Parse translation table entries.
- Perform address translation.
- Check memory permissions.
- Generate faults for invalid accesses.

**R - Device Register Access Handling**
- Decode MMIO addresses.
- Route to appropriate device.
- Enforce memory attributes.
- Handle access size requirements.

**Non-Responsibilities:**
- Does not create platform state (Platform Boot Layer does this).
- Does not implement device functionality (Device Layer does this).
- Does not coordinate initialization (Machine Model does this).
- Does not intervene in kernel execution (Kernel Interface does this).

### Device Layer Responsibilities

**R - Timer Device Implementation**
- Provide timer counter registers.
- Implement compare and interrupt generation.
- Respond to configuration writes.
- Report timer properties via Device Tree.

**R - Interrupt Controller Implementation**
- Accept interrupt assertions from devices.
- Maintain interrupt pending state.
- Provide acknowledgment and completion registers.
- Route interrupts to CPU Model.
- Support interrupt enable/disable per source.

**R - Storage Device Implementation**
- Provide block device interface.
- Implement read/write commands.
- Generate completion interrupts.
- Access host storage backing.
- Report capacity and properties.

**R - Serial Device Implementation**
- Provide UART register interface.
- Implement transmit and receive.
- Generate receive interrupts.
- Connect to host console.
- Support configuration.

**R - Interrupt Delivery to CPU**
- Assert interrupt signal to CPU Model.
- Follow interrupt controller priority.
- Handle interrupt acknowledgment.
- Clear interrupt conditions appropriately.

**R - DMA Operations**
- Initiate device-driven memory access.
- Respect memory permissions.
- Notify on completion.
- Handle errors.

**Non-Responsibilities:**
- Does not synthesize platform identity (Platform Boot Layer does this).
- Does not coordinate initialization (Machine Model does this).
- Does not execute instructions (CPU Model does this).
- Does not accommodate kernel issues (Kernel Interface does this).

### Kernel Interface Responsibilities

**R - Kernel Accommodation Implementation**
- Intercept specific failure points.
- Provide platform state at failure points.
- Return synthesized values when appropriate.
- Log accommodation invocations.

**R - Failure Point Interception**
- Detect documented failure conditions.
- Pause kernel execution temporarily.
- Provide necessary state.
- Resume kernel execution.

**Non-Responsibilities:**
- Does not modify kernel code.
- Does not disable security features.
- Does not handle general device operations (Device Layer does this).
- Does not execute kernel instructions (CPU Model does this).
- Does not create platform state (Platform Boot Layer does this).

## Boundary Rules

### No Overlap Policy

Each responsibility must have exactly one owner. If a responsibility seems to belong to multiple components, decompose it further:

**Example - "Device Setup":**
- Too broad. Decompose into:
  - Device Instance Creation (Machine Model)
  - Device Functionality Implementation (Device Layer)
  - Device Node in Device Tree (Platform Boot Layer)

### Cross-Component Communication

When components must interact:

1. **Data flow**: Component with information provides data structure; receiving component consumes it.
2. **Control flow**: Coordinator component (usually Machine Model) invokes methods in order.
3. **Event notification**: Originating component signals; informed component reacts.

**Example - Device Tree:**
- Platform Boot Layer generates Device Tree (R).
- Machine Model receives Device Tree and places in memory (I).
- Device Layer provides device information to Platform Boot Layer during generation (I).

### Responsibility Evolution

When adding new functionality:

1. Identify which existing component's scope naturally includes the responsibility.
2. If no component fits, justify why a new component is needed.
3. Update this matrix to reflect the assignment.
4. Ensure no overlap with existing responsibilities.

## Validation Checklist

When implementing or reviewing code:

- [ ] Is this responsibility assigned in the matrix?
- [ ] Is the implementing component marked 'R' for this responsibility?
- [ ] Are other components only marked 'I' or '-'?
- [ ] Does the implementation respect component boundaries?
- [ ] Are cross-component interactions properly mediated?

## Anti-Patterns to Avoid

### Platform State in Multiple Places

**Wrong:**
- CPU Model generates part of Device Tree.
- Device Layer synthesizes Secure Boot Context.

**Right:**
- Platform Boot Layer exclusively generates Device Tree.
- Platform Boot Layer exclusively synthesizes Secure Boot Context.
- Other components provide information to Platform Boot Layer.

### Initialization Order Confusion

**Wrong:**
- Device Layer calls Machine Model to get CPU instance.
- CPU Model loads iBoot binary.

**Right:**
- Machine Model creates CPU Model first.
- Machine Model creates Device Layer second.
- Machine Model loads iBoot last.

### Responsibility Leakage

**Wrong:**
- Device Layer detects kernel panic and provides accommodation.
- Platform Boot Layer modifies device behavior during runtime.

**Right:**
- Device Layer implements device interface consistently.
- Kernel Interface handles accommodation if needed.
- Platform Boot Layer completes before boot chain starts.

### Circular Dependencies

**Wrong:**
- Platform Boot Layer needs CPU Model to generate Device Tree.
- CPU Model needs Device Tree from Platform Boot Layer to initialize.

**Right:**
- Platform Boot Layer generates Device Tree independently.
- CPU Model receives configuration from Machine Model.
- No circular information flow.

## Responsibility Assignment Principles

### Single Owner Principle

Each responsibility has exactly one owner. The owner:
- Implements the functionality.
- Maintains the code.
- Decides implementation approach.
- Documents the behavior.

### Information Provider Principle

Components marked 'I' (Informed) may:
- Provide input data to the responsible component.
- Receive notification of completion.
- Read result data structures.

Components marked 'I' may NOT:
- Implement any part of the responsibility.
- Modify data structures owned by responsible component.
- Override decisions made by responsible component.

### Clean Interface Principle

Cross-component interaction occurs through:
- Well-defined function calls.
- Data structure passing.
- Event notifications.

Cross-component interaction does NOT occur through:
- Shared global state (except well-defined structures).
- Direct memory access to other component's data.
- Callbacks that violate responsibility boundaries.

## Component Autonomy

### Platform Boot Layer Autonomy

Platform Boot Layer has complete autonomy over:
- Platform state representation.
- Synthesis algorithms.
- Memory Map layout choices.
- Device Tree format and content.
- Secure Boot Context values.

Other components may not:
- Override platform state after synthesis.
- Second-guess Memory Map layout.
- Modify Device Tree after generation.
- Change Secure Boot Context during boot.

### Machine Model Autonomy

Machine Model has complete autonomy over:
- Initialization sequence order.
- Component instantiation timing.
- Resource allocation strategy.
- Binary loading approach.

Other components may not:
- Change initialization order.
- Create instances independently.
- Load binaries themselves.
- Coordinate their own setup.

### CPU Model Autonomy

CPU Model has complete autonomy over:
- Instruction execution strategy.
- Register storage approach.
- Exception handling implementation.
- PAC algorithm choice (within semantic correctness).

Other components may not:
- Execute instructions.
- Modify CPU registers directly.
- Handle exceptions.
- Implement alternative instruction semantics.

### Device Layer Autonomy

Device Layer has complete autonomy over:
- Device implementation approach.
- Internal device state management.
- Host resource access method.
- Performance optimization strategy.

Other components may not:
- Implement device functionality.
- Access device internal state.
- Bypass device interfaces.
- Override device behavior.

### Kernel Interface Autonomy

Kernel Interface has complete autonomy over:
- Accommodation detection strategy.
- Failure point identification.
- Response synthesis approach.
- Logging and debugging methodology.

Other components may not:
- Intercept kernel execution independently.
- Provide accommodations through other paths.
- Override accommodation decisions.
- Implement alternative accommodation mechanisms.

## Matrix Maintenance

This matrix is a living document. When responsibilities change:

1. Propose changes with justification.
2. Ensure no overlaps in new assignment.
3. Update all affected component documentation.
4. Verify no code violates new assignment.
5. Commit matrix changes with code changes together.
