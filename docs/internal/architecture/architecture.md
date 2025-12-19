# Architecture Overview

This document describes the full emulator architecture for Apple-on-Virt, a purpose-built Apple Silicon arm64e platform emulator.

## Implementation Substrate

This emulator is built on a private QEMU fork (version 9.2.4). QEMU is used as an implementation substrate, not as a generic emulator. See [qemu-as-substrate.md](qemu/qemu-as-substrate.md) and [fork-policy.md](policies/fork-policy.md) for details.

**Key points:**
- No upstream compatibility
- No generic ARM support
- Single machine only
- TCG (software) emulation only

## Design Principles

### Purpose-Built Platform Reconstruction

Apple-on-Virt reconstructs the specific platform context that macOS expects from Apple Silicon hardware. It is not a generic ARM64 emulator or virtual machine. Every component exists to satisfy a specific macOS platform assumption.

### Single Configuration

The architecture defines exactly one machine model and one CPU model. There are no variants, no user-configurable hardware options, and no fallback paths. This constraint ensures that all development effort serves the singular goal of macOS arm64e boot chain execution.

### Layered Trust Synthesis

Rather than attempting to prove trustworthiness through cryptographic verification, the emulator synthesizes the platform state that Apple's boot components expect to find after successful hardware trust establishment. The Platform Boot Layer provides this synthetic trust context.

## High-Level Architecture

```
+===========================================================================+
|                              HOST SYSTEM                                   |
+===========================================================================+
                                    |
                                    v
+===========================================================================+
|                         EMULATOR CORE                                      |
|  +---------------------------------------------------------------------+  |
|  |                    Platform Boot Layer                               |  |
|  |  +---------------+  +----------------+  +-------------------------+  |  |
|  |  | Memory Map    |  | Device Tree    |  | Secure Boot Context     |  |  |
|  |  | Synthesis     |  | Generation     |  | Synthesis               |  |  |
|  |  +---------------+  +----------------+  +-------------------------+  |  |
|  +---------------------------------------------------------------------+  |
|                                    |                                       |
|                                    v                                       |
|  +---------------------------------------------------------------------+  |
|  |                    Machine Model                                     |  |
|  |                 (apple-silicon-bringup)                              |  |
|  |  +---------------+  +----------------+  +-------------------------+  |  |
|  |  | Platform      |  | Hardware       |  | Device                  |  |  |
|  |  | Identity      |  | State Init     |  | Topology                |  |  |
|  |  +---------------+  +----------------+  +-------------------------+  |  |
|  +---------------------------------------------------------------------+  |
|                                    |                                       |
|                                    v                                       |
|  +---------------------------------------------------------------------+  |
|  |                       CPU Model                                      |  |
|  |                     (apple-arm64e)                                   |  |
|  |  +---------------+  +----------------+  +-------------------------+  |  |
|  |  | arm64e ISA    |  | PAC Semantics  |  | Exception Level         |  |  |
|  |  | Execution     |  | (Semantic)     |  | Management              |  |  |
|  +---------------+  +----------------+  +-------------------------+  |  |
|  +---------------------------------------------------------------------+  |
|                                    |                                       |
|                                    v                                       |
|  +---------------------------------------------------------------------+  |
|  |                     Device Layer                                     |  |
|  |  +---------------+  +----------------+  +-------------------------+  |  |
|  |  | Storage       |  | Serial/Console |  | Timer/Interrupt         |  |  |
|  |  | Interface     |  | Interface      |  | Controllers             |  |  |
|  +---------------+  +----------------+  +-------------------------+  |  |
|  +---------------------------------------------------------------------+  |
+===========================================================================+
                                    |
                                    v
+===========================================================================+
|                         GUEST EXECUTION                                    |
|  +---------------------------------------------------------------------+  |
|  |  iBoot (Unmodified) -> boot.efi (Unmodified) -> kernelcache (arm64e)|  |
|  +---------------------------------------------------------------------+  |
+===========================================================================+
```

## Component Responsibilities

### Platform Boot Layer

The Platform Boot Layer is the foundational component that establishes the synthetic hardware environment before any macOS code executes.

**Responsibilities:**

- Construct Apple-style memory map with region types matching Apple Silicon conventions.
- Generate Apple-format device tree containing platform identity, CPU description, and boot arguments.
- Synthesize secure boot context state that indicates successful trust chain validation.
- Initialize hardware identity registers with consistent values.
- Prepare the execution environment for iBoot entry.

**Boundaries:**

- Does not execute any macOS code.
- Does not modify any boot binaries.
- Does not provide firmware services after boot handoff.
- Completes before iBoot begins execution.

### Machine Model (apple-silicon-bringup)

The machine model represents the complete Apple Silicon platform as a single, fixed configuration.

**Responsibilities:**

- Instantiate the Platform Boot Layer and coordinate initialization sequence.
- Create the apple-arm64e CPU instance and connect it to the memory system.
- Define the physical address space layout for DRAM, MMIO, and reserved regions.
- Generate and place the device tree at the expected memory location.
- Initialize platform-level registers and state.
- Load the iBoot binary and set the CPU entry point.
- Expose emulated devices with Apple-compatible interfaces.

**Boundaries:**

- Does not support multiple configurations.
- Does not provide user-facing hardware selection.
- Does not implement standard ARM platform interfaces (no SBSA, no UEFI).
- Does not dynamically adjust to guest requirements.

### CPU Model (apple-arm64e)

The CPU model implements arm64e instruction semantics as required by macOS.

**Responsibilities:**

- Execute arm64e instructions with correct observable behavior.
- Implement pointer authentication (PAC) instructions with semantic correctness.
- Manage exception levels (EL3, EL2, EL1, EL0) with proper transitions.
- Provide system register access with macOS-expected values.
- Handle exceptions and route interrupts through the correct vectors.
- Support memory management unit operations for translation and protection.

**Boundaries:**

- Does not provide performance parity with hardware.
- Does not implement speculative execution or branch prediction.
- Does not model power states or frequency scaling.
- Does not support non-arm64e instruction sets.

### Device Layer

The device layer exposes hardware interfaces that macOS expects to find on Apple Silicon.

**Responsibilities:**

- Present storage devices with Apple-compatible interfaces.
- Provide serial console for kernel debugging output.
- Implement timer and interrupt controllers for scheduling.
- Report device presence through device tree nodes.

**Boundaries:**

- Does not expose transport-layer details to the guest.
- Does not implement Linux-style device discovery.
- Does not provide generic virtio device identity.
- Does not support hotplug or dynamic device changes.

## Data Flow

### Initialization Flow

```
1. Emulator Start
       |
       v
2. Machine Model Initialization
       |
       +---> Platform Boot Layer Setup
       |         |
       |         +---> Memory Map Construction
       |         +---> Device Tree Generation
       |         +---> Secure Boot Context Synthesis
       |
       +---> CPU Model Creation
       |         |
       |         +---> Register Initialization
       |         +---> PAC Key Setup
       |         +---> Exception Vector Configuration
       |
       +---> Device Layer Setup
       |         |
       |         +---> Storage Device Registration
       |         +---> Console Device Registration
       |         +---> Timer/Interrupt Registration
       |
       v
3. iBoot Binary Loading
       |
       v
4. CPU Entry Point Set to iBoot
       |
       v
5. Emulation Begins
```

### Control Flow During Boot

```
Platform Boot Layer      Machine Model      CPU Model      Guest Code
        |                     |                |               |
        |---(State Synth)---->|                |               |
        |                     |---(CPU Init)-->|               |
        |                     |                |               |
        |                     |---(Entry Pt)-->|               |
        |                     |                |---(Execute)-->|
        |                     |                |               | iBoot
        |                     |                |<--(DevTree)---|
        |                     |                |               |
        |                     |                |---(Execute)-->|
        |                     |                |               | boot.efi
        |                     |                |               |
        |                     |                |---(Execute)-->|
        |                     |                |               | kernelcache
```

### Memory Access Flow

```
Guest Code (iBoot/boot.efi/kernel)
        |
        | Virtual Address
        v
   CPU Model (MMU)
        |
        | Physical Address
        v
   Machine Model (Address Decode)
        |
        +---> DRAM Region ---> Memory Backend
        |
        +---> MMIO Region ---> Device Layer
        |
        +---> Reserved Region ---> Handled/Ignored
```

## Component Interactions

### Platform Boot Layer to Machine Model

The Platform Boot Layer provides synthesized state to the Machine Model:

- Memory map definition with region boundaries and attributes.
- Device tree blob ready for placement in guest memory.
- Secure boot context values for platform registers.
- Hardware identity values for consistent reporting.

### Machine Model to CPU Model

The Machine Model configures the CPU Model:

- Initial register values including stack pointer and program counter.
- Memory system connection for address translation.
- Interrupt controller binding for exception routing.
- Platform-specific CPU feature configuration.

### CPU Model to Device Layer

The CPU Model interacts with devices through memory-mapped I/O:

- Device register reads and writes via physical addresses.
- Interrupt assertions from devices to CPU.
- DMA operations (device-initiated memory access).

### Device Layer to Guest

Devices appear to the guest through:

- Device tree nodes describing device presence and properties.
- Memory-mapped register interfaces at fixed addresses.
- Interrupt lines connected to the interrupt controller.

## Trust Model

### Synthesized Trust

The emulator does not cryptographically verify boot components. Instead, it synthesizes the platform state that would exist after successful verification on genuine hardware.

**Trust Assumptions:**

- The Platform Boot Layer sets secure boot context to indicate trusted state.
- Boot components execute without verification because the platform reports trusted status.
- The kernel trusts platform-reported security state.

**Trust Boundaries:**

- The emulator trusts the binaries provided to it.
- The guest trusts the platform state synthesized by the emulator.
- No runtime verification occurs between host and guest.

### Security Semantics Preservation

While cryptographic verification is not performed, security semantics are preserved:

- PAC operations execute with correct instruction behavior.
- Exception levels maintain proper privilege separation.
- Memory protection attributes are enforced by the MMU.
- Secure boot context indicates enabled (not bypassed) security.

## Scalability Across macOS Versions

### Version-Agnostic Design

The architecture achieves version independence through platform fidelity:

- Device tree format follows Apple conventions stable across releases.
- Platform identity values remain consistent.
- CPU feature reporting matches expected Apple Silicon capabilities.
- Secure boot context represents standard trusted state.

### Adaptation Points

When a new macOS version introduces new platform requirements:

- Platform Boot Layer may require additional state synthesis.
- Device tree may need new properties or nodes.
- CPU model may need additional register implementations.

These are additive changes to platform fidelity, not version-specific patches.

## Explicit Non-Architecture

The following are explicitly not part of the architecture:

- **BIOS/UEFI firmware interfaces**: Apple Silicon does not use these standards.
- **SBSA/Server Base System Architecture**: Not applicable to Apple platforms.
- **Generic ARM64 machine definitions**: Would introduce incorrect platform assumptions.
- **PCI bus topology**: Apple Silicon uses proprietary interconnects.
- **ACPI tables**: Apple uses device tree exclusively.
- **VirtIO device identity**: Devices present Apple-compatible interfaces.

## Quality Criteria

A new contributor should understand from this document:

1. The emulator has four main components: Platform Boot Layer, Machine Model, CPU Model, and Device Layer.
2. Each component has specific responsibilities and explicit boundaries.
3. Data flows from Platform Boot Layer through Machine Model to CPU Model during initialization.
4. Control flows from CPU Model to guest code after initialization completes.
5. Trust is synthesized rather than verified, preserving security semantics without cryptographic proof.
6. The architecture supports multiple macOS versions through platform fidelity, not version-specific code.