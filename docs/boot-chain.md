# Boot Chain Analysis

This document details the macOS arm64e boot chain that Apple-on-Virt must support without modification: **iBoot → boot.efi → kernelcache**.

## Boot Chain Overview

The Apple Silicon boot chain is a carefully orchestrated sequence of components that must execute in exact order with precise platform assumptions. Apple-on-Virt's primary goal is enabling this complete chain to execute without any binary patches.

```
[ Platform Boot Layer ]
        ↓
      iBoot (unaltered)
        ↓  
    boot.efi (unaltered)  
        ↓
  kernelcache (arm64e)
        ↓
   macOS userspace
```

## Platform Boot Layer Requirements

### Pre-Boot Environment
Before iBoot execution begins, the Platform Boot Layer must establish:

#### Apple-Style Memory Map
- Precise memory layout expected by Apple Silicon
- Correct memory regions for bootloader, kernel, and system services
- Proper alignment and permissions for secure boot components

#### Apple-Style Device Tree
- Minimal but complete device tree structure based on reverse engineering
- Essential nodes: `/cpus`, `/memory`, `/chosen`
- Apple-specific nodes: `secure-state`, `platform-id`, `chip-id`
- Hardware identity consistent across boot stages

#### Secure Boot Context
- Boot stage state flags indicating trusted execution path
- Cryptographic context for secure boot validation
- "Trusted boot path" assumption injection
- Platform security state initialization

#### Hardware State Injection
- Platform ID, Board ID, Chip ID (fake but consistent)
- System register values expected by iBoot
- CPU exception level contexts (EL3/EL2/EL1)
- PAC key register initialization

## iBoot Stage (Unaltered)

### iBoot Requirements
iBoot expects a very specific Apple Silicon platform environment:

- **Hardware Identity**: Precise platform/board/chip identification
- **Memory Layout**: Apple-specific memory map structure  
- **Device Tree**: Complete Apple-style device tree
- **Secure Context**: Valid secure boot state and cryptographic context
- **CPU State**: Proper EL3 context with initialized PAC keys

### Platform Assumptions
iBoot makes critical assumptions about the underlying platform:
- Genuine Apple SoC hardware
- Valid secure boot certificate chain
- Authentic device tree structure
- Proper memory protection setup

Apple-on-Virt must fulfill these assumptions through Platform Boot Layer recreation rather than iBoot modification.

## boot.efi Stage (Unaltered)

### boot.efi Requirements  
boot.efi continues the boot chain with additional platform expectations:

- **iBoot Handoff**: Valid handoff from unaltered iBoot
- **Kernel Preparation**: Proper kernelcache preparation and validation
- **Security Continuity**: Maintained secure boot context from iBoot
- **Device Enumeration**: Complete hardware enumeration from device tree

### Platform Dependencies
boot.efi depends on platform state established by iBoot:
- Verified kernelcache integrity
- Valid secure boot chain continuation
- Proper system service initialization context
- Correct hardware capability reporting

## kernelcache Stage (arm64e)

### Kernel Bring-up Requirements
The macOS arm64e kernel expects precise platform conditions:

- **CPU Model**: Genuine arm64e semantics with PAC support
- **Memory Management**: Apple-specific memory layout and protection
- **Device Tree**: Complete hardware description for driver loading
- **Security Model**: Valid AMFI and SSV context
- **Platform Identity**: Consistent Apple Silicon platform identification

### Critical Bring-up Points
The kernel has specific failure points during early initialization:
- **Entry Point**: Immediate post-entry platform assumptions
- **PAC Validation**: Pointer authentication during early execution
- **Device Tree Parsing**: Hardware recognition and driver loading
- **Security Initialization**: AMFI and secure boot context validation

Apple-on-Virt allows **minimal intervention only at these specific bring-up failure points**, never modifying the kernel binary itself.

## Boot Chain Integrity Principles

### No Binary Modification
- **iBoot**: Absolutely no patches or modifications allowed
- **boot.efi**: Absolutely no patches or modifications allowed  
- **kernelcache**: No binary patches, only minimal runtime intervention at bring-up failure points

### Platform Recreation Strategy
Instead of patching binaries, Apple-on-Virt recreates the exact platform environment each component expects:

1. **Platform Boot Layer** satisfies iBoot requirements
2. **Unaltered iBoot** establishes boot.efi requirements  
3. **Unaltered boot.efi** prepares kernelcache requirements
4. **Minimal kernel intervention** only at documented failure points

### Security Model Preservation
Security mechanisms are adapted rather than disabled:
- Secure boot context is recreated authentically
- AMFI context is maintained through emulation
- SSV assumptions are fulfilled through platform state
- PAC semantics are implemented meaningfully

## Validation Criteria

### Success Metrics
- iBoot loads and executes without modification
- boot.efi receives valid handoff from iBoot
- kernelcache begins execution with "Starting kernel" message
- Early kernel bring-up completes without panics
- Basic system services initialize successfully

### Failure Indicators
- iBoot fails to recognize platform as Apple Silicon
- boot.efi rejects handoff from iBoot
- kernelcache panics during early initialization
- Security validation failures during boot stages
- Device tree parsing errors in kernel

## Research Methodology

### Reverse Engineering Approach
Understanding the boot chain requires systematic reverse engineering:
- Analyze iBoot behavior on genuine Apple Silicon
- Document platform assumptions at each boot stage
- Identify critical failure points in kernel bring-up
- Map device tree requirements for proper hardware recognition

### Validation Testing
Each Platform Boot Layer component must be validated independently:
- Memory map correctness verification
- Device tree structure validation  
- Secure boot context authenticity testing
- Hardware state consistency checking

### Iterative Development
Boot chain support is developed iteratively:
1. **Phase 1**: Headless kernel bring-up (no GUI)
2. **Phase 2**: Minimal userspace viability
3. **Phase 3**: Display and I/O stabilization
4. **Phase 4**: Enhanced platform reconstruction accuracy

## Non-Goals Enforcement

The boot chain analysis explicitly excludes:
- **Multi-OS support**: Focus exclusively on macOS arm64e
- **Generic ARM64 compatibility**: Target only Apple Silicon platform assumptions
- **Performance optimization**: Prioritize accuracy over speed during bring-up
- **User convenience features**: Focus on boot chain integrity, not VM usability

## Conclusion

The macOS arm64e boot chain represents the core challenge and opportunity for Apple-on-Virt. By enabling **iBoot → boot.efi → kernelcache** to execute without modification, the project creates a legitimate research platform for Apple Silicon platform assumptions.

> This project does not try to make macOS run anywhere. It tries to make macOS believe it never left home.