# Apple-on-Virt: Apple Silicon arm64e Platform Reconstruction

## Project Identity

Apple-on-Virt reconstructs the Apple Silicon platform to enable macOS arm64e execution. This is not generic ARM64 emulation, not a virtual machine, and not a compatibility layer. It is purpose-built platform reconstruction that synthesizes the exact hardware context, boot state, and platform identity that macOS expects from Apple Silicon.

The emulator's sole purpose is to reconstruct sufficient platform fidelity for the unmodified Apple boot chain (iBoot → boot.efi → kernelcache) to execute as if on genuine hardware. Every component exists to satisfy specific Apple Silicon platform assumptions that macOS makes during boot and initialization.

## Core Principle

**Platform Reconstruction Over Generic Emulation**

This project does not attempt to provide a flexible emulation framework or support multiple operating systems. It reconstructs one specific platform—Apple Silicon—with singular focus on macOS arm64e compatibility. The architecture prioritizes platform accuracy over implementation convenience, version-agnostic design over version-specific patches, and semantic correctness over performance optimization.

## Mission

Reconstruct the minimal Apple Silicon platform environment required for unmodified macOS arm64e boot components to execute without modification, maintaining compatibility across macOS versions through platform fidelity rather than software adaptation.

## Goals

- Reconstruct the Apple Silicon platform context required for native macOS boot chain execution.
- Enable the complete boot sequence (iBoot, boot.efi, kernelcache) without binary modification.
- Provide arm64e CPU semantics sufficient for macOS kernel bring-up.
- Synthesize Apple-style device tree, secure boot context, and hardware identity.
- Support legitimate research into Apple Silicon platform assumptions and security architecture.
- Maintain version-agnostic compatibility across multiple macOS releases through platform fidelity.

## Explicit Non-Goals

This project explicitly does NOT provide:

- Generic ARM64 or ARMv8-A emulation capabilities.
- Virtual machine hypervisor functionality.
- Multi-OS support or guest flexibility.
- Performance benchmarking or optimization focus.
- App Store, iCloud, DRM, or Apple service functionality.
- Binary patching or kernel modification approaches.
- User-configurable hardware or platform variants.
- Multi-board or multi-SoC hardware configurations.
- QEMU upstream compatibility as a design constraint.
- General-purpose ARM server emulation.
- Development convenience over platform accuracy.

## Architecture Philosophy

### Platform Reconstruction as First Principle

Apple-on-Virt reconstructs the Apple Silicon platform, not an abstract computer system that happens to run macOS. Every architectural decision asks: "What does Apple Silicon provide?" rather than "What does macOS need?" This distinction is critical. Generic emulation attempts to satisfy immediate software requirements through minimal implementation. Platform reconstruction builds the underlying platform layer that Apple designed macOS to run on.

The emulator does not simulate transistors or model hardware timing. It reconstructs the platform state—the registers, memory layout, device tree, and boot context—that macOS queries to understand its execution environment. When macOS asks "What platform am I running on?", the answer must be "Apple Silicon" in every observable detail.

### Respect for the Unmodified Boot Chain

The Apple boot sequence represents years of engineering designed around implicit hardware trust. Inspired by projects that work within Apple's boot architecture rather than replacing it, this emulator provides the expected platform environment so that iBoot, boot.efi, and the kernelcache can execute their native code paths. Binary patching is explicitly rejected because it creates version-specific dependencies and undermines the research value of understanding genuine Apple Silicon assumptions.

### Version-Agnostic Compatibility Through Fidelity

Each macOS release makes assumptions about its underlying platform, but these assumptions are remarkably stable across versions because Apple controls both the hardware and software. By reconstructing the platform accurately rather than patching around version-specific checks, this emulator naturally supports multiple macOS versions. When a new release appears, the question is whether the platform layer satisfies its assumptions, not whether patches need updating.

### Minimal Kernel Intervention

While the Platform Boot Layer handles pre-boot environment synthesis, the kernel may encounter runtime conditions that cannot be pre-satisfied. The architecture permits minimal, documented intervention at specific kernel bring-up failure points, but only to fulfill unmet platform assumptions. Security mechanisms are never disabled, userspace is never modified, and interventions are temporary and scoped to early initialization. The long-term goal is eliminating all kernel intervention through improved platform fidelity.

### Single Machine, Single CPU Model

Complexity is the enemy of correctness. This project maintains exactly one machine model (apple-silicon-bringup) and exactly one CPU model (apple-arm64e). There are no board variants, no user-selectable CPU options, and no generic ARM64 fallback paths. This constraint ensures that every line of code serves Apple Silicon platform reconstruction and that testing covers the exact configuration macOS will encounter.

### Rejection of Generic Virtualization Interfaces

Apple Silicon does not use UEFI. It does not use BIOS. It does not conform to SBSA (Server Base System Architecture). It does not provide standard ARM peripherals, standard boot protocols, or standard firmware interfaces. Apple designed a proprietary platform with custom boot sequences, custom device trees, custom secure boot mechanisms, and custom hardware initialization.

Generic ARM64 virtualization assumes standard interfaces. Attempting to retrofit Apple's boot chain onto UEFI firmware or standard ARM platforms requires extensive translation layers, compatibility shims, and version-specific adaptations. This project rejects that approach entirely. There is no UEFI layer, no compatibility translation, no generic ARM fallback. The emulator presents Apple Silicon, and only Apple Silicon, to macOS.

### Research Integrity as a Design Constraint

Every architectural decision must preserve the emulator's value as a research platform. This means maintaining observable equivalence to genuine Apple Silicon behavior wherever macOS can detect differences. Shortcuts that make the emulator "work" while hiding platform assumptions from researchers are explicitly forbidden. The goal is not just to boot macOS, but to understand what makes macOS boot.

## Platform Boot Layer

### Definition

The Platform Boot Layer is the synthetic environment that satisfies Apple Silicon boot and security assumptions before macOS execution begins. It is not a bootloader, not firmware, and not a compatibility shim. It is the reconstructed hardware context that Apple's boot components expect to find when they begin execution. This layer is mandatory for any Apple Silicon platform emulation; without it, the unmodified boot chain cannot proceed.

### Conceptual Boot Flow

```
+---------------------------+
|    Platform Boot Layer    |
|  (Synthetic Environment)  |
+-------------+-------------+
              |
              | Provides: Memory map, Device tree,
              |           Secure boot context,
              |           Hardware identity, CPU state
              v
+-------------+-------------+
|         iBoot             |
|      (Unmodified)         |
+-------------+-------------+
              |
              | Loads and validates boot.efi
              v
+-------------+-------------+
|        boot.efi           |
|      (Unmodified)         |
+-------------+-------------+
              |
              | Prepares and loads kernelcache
              v
+-------------+-------------+
|      kernelcache          |
|     (arm64e, native)      |
+-------------+-------------+
              |
              | Initializes kernel subsystems
              v
+-------------+-------------+
|    macOS Userspace        |
+---------------------------+
```

### Responsibilities

- Construct Apple-style memory map with correct region types and permissions.
- Generate Apple-format device tree with platform identity, CPU topology, and boot arguments.
- Synthesize secure boot context indicating trusted execution path.
- Initialize hardware identity values (platform ID, board ID, chip ID) consistently.
- Prepare CPU state including exception level contexts and PAC key registers.
- Load unmodified iBoot binary and transfer control without modification.
- Ensure all synthesized state remains consistent across boot stages.

## Machine Model: apple-silicon-bringup

### Identity

The apple-silicon-bringup machine is the singular, fixed platform definition for this emulator. It is not one of several machine options. It is not configurable. It is not a generic ARM platform with Apple-specific tweaks. It is a complete, self-contained reconstruction of the Apple Silicon platform as observed by macOS.

This machine model exists to answer one question: "What platform is this?" The answer must always be "Apple Silicon" in every detail macOS can observe.

### Core Responsibilities

**Platform State Synthesis**
- Construct Apple Silicon memory map (DRAM, MMIO, secure regions).
- Generate Apple-format device tree with required platform nodes.
- Synthesize secure boot context matching production Apple Silicon.
- Initialize consistent platform identity (platform ID, board ID, chip ID).

**Boot Chain Support**
- Instantiate and configure Platform Boot Layer.
- Load unmodified iBoot binary at correct address.
- Set CPU to iBoot entry point with correct initial state.
- Ensure platform state consistency from boot through kernel initialization.

**Component Integration**
- Create and connect apple-arm64e CPU model.
- Instantiate Apple-compatible devices.
- Coordinate initialization sequence.

### Architectural Constraints

This machine model does NOT:
- Provide multiple platform configurations or board variants.
- Support user-selectable hardware options.
- Implement UEFI, BIOS, or firmware interfaces.
- Provide PCI topology or standard ARM peripherals.
- Support any operating system except macOS arm64e.
- Emulate generic ARM64 server platforms.

### Why Single Machine Architecture Enables Compatibility

Multiple machine models create divergent platform assumptions. Each variant must be tested against each macOS version, creating a matrix of compatibility concerns. Configuration options introduce variables that cannot be systematically validated.

A single, fixed machine model creates one platform definition. When macOS boots successfully, it validates the platform reconstruction. When it fails, the failure identifies a specific platform assumption that requires correction. Every fix improves the one platform model that all macOS versions encounter.

This constraint transforms compatibility from a configuration management problem into a platform fidelity problem. The question becomes "Is this Apple Silicon?" not "Which combination of options works?"

## CPU Model (apple-arm64e)

### Targeted Semantics

The apple-arm64e CPU model implements the arm64e instruction set architecture with Apple-specific extensions as observed by macOS. This is not a generic ARMv8-A or ARMv8.3-A implementation. The CPU model targets semantic correctness for macOS kernel bring-up, meaning that instruction behavior matches what the kernel expects even when the underlying implementation differs from silicon.

### Required Behaviors

- Decode and execute all arm64e instructions encountered during boot.
- Implement pointer authentication (PAC) instruction semantics.
- Provide correct exception level (EL) transition behavior for EL3, EL2, and EL1.
- Initialize PAC key registers with consistent values.
- Report CPU feature registers with macOS-acceptable values.
- Handle exceptions and interrupts with correct vector layout.
- Support memory management unit (MMU) operations for kernel page tables.

### Explicit Abstractions

The following behaviors are abstracted rather than precisely emulated:

- PAC cryptographic operations: Semantic validity checking replaces actual cryptographic computation. All properly formatted PAC operations succeed during bring-up; this is sufficient because the kernel trusts its own pointers.
- Cycle-accurate timing: Instruction timing is not modeled. The emulator prioritizes correctness over performance fidelity.
- Speculative execution: Branch prediction and speculative behavior are not modeled. These affect performance, not functional correctness for boot.
- Power management states: Deep sleep and power gating are stubbed. The emulator runs as if the CPU is always fully powered.
- Hardware performance counters: Performance monitoring registers return plausible values but do not reflect actual execution metrics.

### Non-Goals

- Performance parity with Apple Silicon hardware.
- Support for non-macOS operating systems.
- Generic ARMv8 compatibility mode.
- Multi-cluster or heterogeneous CPU topology.
- Full cryptographic PAC implementation (planned for future phases).
- Real-time interrupt latency guarantees.

### Why Semantic Correctness Matters More Than Instruction Completeness

The macOS kernel uses a small subset of the arm64e instruction set during early boot. Implementing every ARMv8.x extension perfectly but failing to satisfy the kernel's specific PAC or exception handling expectations would prevent boot entirely. Conversely, a minimal implementation that handles exactly what the kernel does during bring-up enables forward progress. The CPU model can be extended incrementally as later boot stages and userspace reveal additional requirements.

## Project Structure

See [Directory Structure](docs/directory-structure.md) for complete documentation.

### Key Components

- **Platform Boot Layer**: Synthesizes pre-boot environment before iBoot execution.
- **Machine Model (apple-silicon-bringup)**: Single fixed platform configuration.
- **CPU Model (apple-arm64e)**: ARM64e instruction execution with PAC semantics.
- **Device Layer**: Apple-compatible device implementations.

### Source Organization

- `hw/apple/` - Machine model and Platform Boot Layer
- `target/apple-arm64e/` - CPU model and arm64e semantics
- `docs/` - Complete architecture and design documentation
- `scripts/` - Build and testing utilities
- `local_storage/` - Reference materials (m1n1, XNU source)

## Development Status

**Milestone 1**: COMPLETE ([details](docs/milestone-1-completion.md))

The project has completed foundational architecture:

- Project identity and philosophy locked in
- Architecture documentation complete
- Machine and CPU model skeletons defined
- QEMU fork preparation complete

**Current Phase**: Implementation preparation

**Boot Status**: The emulator does not yet boot macOS. Current work focuses on establishing correct architectural foundations before implementing boot functionality.

**Target**: Headless kernel bring-up with unmodified boot chain.

## Documentation

### Architecture and Design

- [Architecture Overview](docs/architecture.md) - Full emulator architecture with component responsibilities and data flow.
- [Boot Chain Analysis](docs/boot-chain.md) - Complete boot flow from emulator start to kernel entry.
- [CPU arm64e Model](docs/cpu-arm64e.md) - arm64e CPU semantics, required behaviors, and abstractions.
- [Security Model](docs/security-model.md) - Security assumption adaptation and preservation.
- [Kernel Policy](docs/kernel-policy.md) - Kernel accommodation rules and version-agnostic principles.
- [Device Model](docs/device-model.md) - Device exposure philosophy and identity over transport.

### Implementation Guides

- [Terminology](docs/terminology.md) - Canonical terminology definitions for consistent usage across the project.
- [Responsibility Matrix](docs/responsibility-matrix.md) - Component responsibility assignments to prevent architectural drift.
- [Version Compatibility](docs/versioning.md) - Strategy for macOS version-agnostic design through platform fidelity.
- [QEMU Decomposition](docs/qemu-decomposition.md) - Analysis of QEMU subsystems retained, modified, or removed.
- [Failure Modes](docs/failure-modes.md) - Expected failure modes during bring-up with symptoms and diagnostics.
- [Directory Structure](docs/directory-structure.md) - Complete project directory organization with clear responsibilities.
- [Platform Boot Layer Specification](docs/platform-boot-layer.md) - Formal specification of the mandatory Platform Boot Layer.

### Implementation Skeletons

- [Machine Model Skeleton](docs/machine-model-skeleton.md) - C structure for apple-silicon-bringup machine implementation.
- [CPU Model Skeleton](docs/cpu-model-skeleton.md) - C structure for apple-arm64e CPU implementation.

### Project Status

- [Milestone 1 Completion](docs/milestone-1-completion.md) - Foundational architecture completion report.

## Research Value

This project enables legitimate research into:

- Apple Silicon platform assumptions and hardware contracts.
- macOS arm64e boot chain requirements and failure modes.
- Secure boot implementation and trust establishment.
- arm64e instruction semantics and pointer authentication.
- Platform-specific kernel initialization sequences.
- Device tree format and hardware discovery mechanisms.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

This project is for educational and research purposes only. Running macOS on non-Apple hardware may violate Apple's End User License Agreement. Users are responsible for ensuring compliance with all applicable laws and license agreements.