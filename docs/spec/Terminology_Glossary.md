# Terminology Glossary

This glossary defines key terms used throughout the Apple-on-Virt project documentation to ensure consistent understanding of the platform's unique architecture and philosophy.

## Platform Boot Layer

**Definition**: The abstraction layer that replaces traditional UEFI/BIOS concepts in Apple Silicon emulation. It provides the necessary boot context, device tree, and secure boot environment that macOS arm64e expects.

**Context**: Unlike generic ARM virtualization that relies on EDK2 UEFI firmware, the Platform Boot Layer specifically recreates Apple Silicon boot conditions including fake SoC state and secure boot context.

**Related Terms**: Secure boot context, Device Tree, Fake Apple SoC state

## arm64e Semantics

**Definition**: The specific instruction set architecture, ABI (Application Binary Interface), and security model used by Apple Silicon processors, distinct from generic ARMv8-A.

**Key Characteristics**:
- Pointer Authentication (PAC) support
- Specific calling conventions and register usage
- Kernel/userspace pointer trust model
- Security-focused memory management

**Context**: This project targets arm64e semantics specifically, not generic ARM64. Non-arm64e CPUs are unsupported unless they can behaviorally emulate Apple Silicon arm64e characteristics.

## Security Assumption Adaptation

**Definition**: The process of selectively modifying security mechanisms to match emulation capabilities while preserving the original security intent, rather than simply disabling security features.

**Principles**:
- Security mechanisms are not disabled but adapted
- Physical hardware assumptions are recreated in software where possible
- Minimal mitigation is applied only where physical constraints cannot be met
- The goal is maintaining security model integrity while enabling emulation

**Context**: This approach distinguishes legitimate research from "cheating" projects that simply bypass security.

## Bring-up Kernel

**Definition**: The minimal kernel state during initial platform initialization, before full system services are available.

**Characteristics**:
- Early boot phase with limited functionality
- Platform assumption resolution occurring
- Minimal intervention window for emulation requirements
- Precedes kext loading and full device model exposure

**Context**: Kernel modifications are restricted to this phase only, with the goal of achieving unaltered kernel execution thereafter.

## Emulated SoC

**Definition**: The reconstructed Apple System-on-Chip state presented to macOS, including CPU topology, memory layout, device tree, and hardware registers.

**Components**:
- Fake Apple SoC identification
- Apple-specific device tree entries
- Hardware register emulation
- Memory mapping that matches Apple Silicon expectations

**Context**: The emulated SoC must be convincing enough for macOS to believe it is running on genuine Apple hardware.

## Platform-provided Display Device

**Definition**: The presentation of graphics hardware to macOS as an Apple-native display device, rather than exposing underlying virtio transport details.

**Implementation**:
- Kernel sees Apple-compatible GPU interface
- Virtio serves as invisible transport layer
- Device tree presents Apple GPU identifiers
- Graphics drivers load as if on real hardware

**Context**: This approach ensures proper driver loading and avoids the need for custom GPU patches.

## Secure Boot Context

**Definition**: The cryptographic and verification environment that enables macOS secure boot chain validation in the emulation environment.

**Components**:
- Fake secure boot certificates
- Emulated secure enclave communication
- Verified boot chain from Platform Boot Layer through iBoot
- AMFI (Apple Mobile File Integrity) context adaptation

**Context**: Rather than disabling secure boot, the project recreates the necessary context for secure boot to function in emulation.

## Device Model Exposure

**Definition**: The process of presenting emulated hardware to macOS as genuine Apple devices through appropriate device tree entries and hardware interfaces.

**Principles**:
- Devices appear as Apple hardware to the kernel
- Underlying virtio transport is abstracted away
- Proper device identification and capabilities are presented
- Enables standard Apple drivers to load without modification

**Context**: This is essential for achieving the "macOS believes it is home" goal without requiring extensive kernel patching.