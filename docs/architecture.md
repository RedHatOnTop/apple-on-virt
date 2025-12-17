# Architecture Overview

This document provides a comprehensive overview of the Apple-on-Virt architecture, designed to reconstruct the minimal Apple Silicon platform required for macOS arm64e to execute its unmodified boot chain.

## Core Architecture Principles

### Purpose-Built Design
Apple-on-Virt is not a generic emulator but a **purpose-built platform reconstruction** focused exclusively on enabling macOS arm64e boot chain execution. Every architectural decision prioritizes accuracy over generality.

### Single Platform Focus
The architecture supports exactly one platform: **apple-silicon-bringup**. This eliminates complexity from multi-platform support and ensures all resources focus on Apple Silicon platform assumptions.

### Boot Chain Integrity
The complete boot chain **iBoot → boot.efi → kernelcache** must execute without binary modifications. The architecture provides the necessary platform context rather than patching binaries.

## High-Level Architecture

```
[ Host ]
 └─ Emulator Core (QEMU-derived)
     ├─ apple-arm64e CPU model
     ├─ apple-silicon-bringup machine
     ├─ Platform Boot Layer
     │    ├─ Apple-style Device Tree
     │    ├─ Secure Boot Context
     │    └─ Hardware State Injection
     ├─ iBoot (unaltered)
     ├─ boot.efi (unaltered)
     └─ macOS kernelcache (arm64e)
```

### Key Architectural Decisions

#### No UEFI/BIOS/SBSA Concepts
Traditional virtualization concepts like UEFI, BIOS, and SBSA are explicitly excluded. Apple Silicon has its own boot architecture that must be recreated authentically.

#### Platform Boot Layer as Foundation
The Platform Boot Layer serves as the synthetic environment that satisfies Apple Silicon boot and security assumptions before macOS execution begins.

#### Dedicated CPU Model
The `apple-arm64e` CPU model is never shared with generic ARMv8 implementations, ensuring arm64e semantics are properly implemented.

## Component Architecture

### Emulator Core (QEMU-derived)
- Provides hardware virtualization foundation
- Extended with Apple-specific components
- Temporary dependency - ultimate goal is independence

### apple-silicon-bringup Machine
- Single machine implementation inheriting from QEMU `MachineClass`
- Represents a "fake Apple SoC platform" rather than virtual board
- Responsible for platform-level initialization and state management

### apple-arm64e CPU Model  
- Derived from QEMU `ARMCPU` with dedicated `ARM_CPU_FEATURE_ARM64E`
- Implements arm64e calling conventions and PAC semantics
- Provides essential CPU state expected by macOS kernel

### Platform Boot Layer
- Synthetic environment satisfying Apple Silicon assumptions
- Composed of Apple-style Device Tree, Secure Boot Context, and Hardware State Injection
- Bridges the gap between emulation environment and Apple Silicon expectations

## Initialization Flow

### Machine Initialization Sequence
```
machine_init()
 ├─ init_memory_map()           # Apple-style memory layout
 ├─ init_apple_cpu()            # apple-arm64e CPU setup  
 ├─ init_platform_state()       # Platform identity and state
 ├─ generate_apple_device_tree() # Apple-specific device tree
 ├─ load_iboot()                # Load unaltered iBoot
 └─ handoff_to_iboot()          # Transfer control to Apple boot chain
```

### CPU Initialization Sequence
```
cpu_realize()
 ├─ init_arm64e_features()      # Enable arm64e-specific features
 ├─ init_pac_keys()             # Initialize PAC key registers
 ├─ init_exception_levels()     # Set up EL3/EL2/EL1 contexts
 ├─ init_system_registers()     # Configure Apple-expected registers
 └─ expose_cpu_to_machine()     # Integrate CPU with machine model
```

## Design Philosophy Implementation

### Environment Over Patching
Instead of modifying macOS binaries, the architecture recreates the exact platform environment macOS expects. This preserves binary integrity while enabling execution.

### Reproduction Over Bypass  
Security mechanisms are not disabled but recreated in a way that satisfies macOS requirements within emulation constraints. This maintains research integrity.

### Accuracy Over Generality
The single-platform, single-CPU approach ensures maximum accuracy for Apple Silicon platform reconstruction rather than attempting to support multiple configurations.

### Boot Chain Respect
The architecture treats the Apple boot chain as inviolable, providing only the platform context needed for successful execution without modification.

### One Machine, One CPU
The exclusive focus on `apple-silicon-bringup` machine and `apple-arm64e` CPU eliminates complexity and ensures all development effort targets the specific requirements of macOS arm64e.

## Research and Development Phases

### Phase 0: Platform Assumptions Research
- Comprehensive analysis of Apple Silicon boot requirements
- Documentation of platform assumptions made by macOS arm64e
- Reverse engineering of Apple-specific device tree structure

### Phase 1: Headless Kernel Bring-up  
- Implementation of Platform Boot Layer components
- Development of apple-arm64e CPU model with semantic PAC
- Validation of unaltered boot chain execution

### Phase 2: Minimal Userspace Viability
- Expansion of device model exposure
- Validation of security model adaptation
- Basic system service operation

### Phase 3: Display + I/O Stabilization
- Full GUI support implementation
- Stable device interaction
- Performance optimization

### Phase 4: Architecture Refinement
- Elimination of QEMU dependencies
- Enhanced platform reconstruction accuracy
- Production-ready stability

## Non-Goals Enforcement

The architecture explicitly excludes:
- Generic ARM64 emulation capabilities
- Multi-OS support infrastructure  
- DRM/App Store functionality
- Performance optimization at the expense of accuracy
- User-friendly VM convenience features

## Future Evolution

While currently QEMU-derived, the ultimate architectural goal is a self-contained emulator that eliminates external dependencies while maintaining the same platform reconstruction accuracy.

The modular design allows for gradual replacement of QEMU components with custom implementations while preserving the core architectural principles.

## Conclusion

This architecture represents a paradigm shift in macOS emulation research. By focusing on **platform assumption fulfillment** rather than **binary modification**, Apple-on-Virt creates a sustainable foundation for legitimate Apple Silicon platform research.

> This project does not try to make macOS run anywhere. It tries to make macOS believe it never left home.