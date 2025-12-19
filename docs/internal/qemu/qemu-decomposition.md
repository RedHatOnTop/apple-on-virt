# QEMU Decomposition Plan

This document categorizes QEMU subsystems as retained, modified, or removed for Apple-on-Virt. QEMU serves as a substrate for emulation infrastructure, not as a target architecture.

## Categorization Principle

**Retained**: Used as-is from QEMU without modification.

**Modified**: Used from QEMU but requires Apple Silicon-specific adaptations.

**Removed**: Not relevant to Apple Silicon arm64e platform and excluded.

## Core Emulation Infrastructure

### TCG (Tiny Code Generator) - MODIFIED

**Current Role in QEMU:**
- Dynamic binary translation engine.
- Translates guest instructions to host instructions.
- Handles ARM64 instruction execution.

**Justification for Modification:**
- Must support arm64e-specific instructions.
- PAC instructions require custom implementation.
- Apple-specific system register behaviors need handling.
- Exception level transitions need precise semantics.

**Modification Scope:**
- Add arm64e instruction decoders.
- Implement PAC instruction semantics.
- Extend system register support for Apple-specific registers.
- Preserve ARMv8 base functionality.

**Why Not Removed:**
TCG provides mature instruction execution framework. Building from scratch would duplicate significant effort. Modifications are localized to arm64e extensions.

### CPU Execution Loop - MODIFIED

**Current Role in QEMU:**
- Main loop for instruction fetch-decode-execute.
- Handles interrupts and exceptions.
- Manages CPU state.

**Justification for Modification:**
- Must enforce arm64e exception semantics.
- Needs Apple-specific interrupt handling.
- Requires precise exception level management.

**Modification Scope:**
- Adapt exception entry/exit for Apple Silicon patterns.
- Modify interrupt delivery to match Apple Interrupt Controller (AIC).
- Ensure exception vector layout matches Apple conventions.

**Why Not Removed:**
Core execution loop is sound. Only delivery and state management need adaptation for Apple specifics.

### Memory Subsystem - MODIFIED

**Current Role in QEMU:**
- Handles address translation.
- Manages memory regions.
- Implements memory-mapped I/O.

**Justification for Modification:**
- Memory map must follow Apple Silicon layout.
- Address translation must match arm64e semantics.
- MMIO routing needs Apple device addresses.

**Modification Scope:**
- Configure memory map for Apple Silicon regions.
- Ensure MMU behavior matches arm64e specification.
- Route MMIO to Apple-compatible devices.

**Why Not Removed:**
Memory subsystem infrastructure is reusable. Configuration and address space layout require Apple-specific setup.

## ARM Architecture Support

### ARMv8 Base Implementation - RETAINED

**Current Role in QEMU:**
- Base ARM64 instruction implementation.
- Standard exception handling.
- Generic ARM system registers.

**Justification for Retention:**
- arm64e builds on ARMv8 base.
- Standard instructions work without change.
- Exception handling framework is sound.

**Usage:**
- Direct use for standard ARM64 instructions.
- Foundation for arm64e extensions.
- No modification to base ARMv8 semantics.

**Why Not Modified:**
ARMv8 base is architecturally defined and stable. Apple's arm64e is an extension, not a replacement.

### ARM CPU Models (Generic) - REMOVED

**Current Role in QEMU:**
- Cortex-A53, Cortex-A72, other ARM CPUs.
- Generic ARM platform emulation.
- Multi-CPU-model support infrastructure.

**Justification for Removal:**
- Apple Silicon is not Cortex-based.
- Generic ARM CPU models are irrelevant.
- Single apple-arm64e CPU model replaces all.

**Removed Components:**
- Cortex CPU definitions.
- Generic ARM CPU selection logic.
- Multi-model CPU infrastructure.

**Why Not Retained:**
Maintaining unused CPU models adds complexity without benefit. Apple-on-Virt targets only apple-arm64e.

### GIC (Generic Interrupt Controller) - REMOVED

**Current Role in QEMU:**
- Standard ARM interrupt controller.
- GICv2, GICv3 implementations.

**Justification for Removal:**
- Apple Silicon uses proprietary AIC (Apple Interrupt Controller).
- GIC interface is incompatible.
- macOS expects AIC, not GIC.

**Replacement:**
- Apple Interrupt Controller (AIC) implementation.
- Custom interrupt routing.
- Apple-specific interrupt priorities.

**Why Not Modified:**
GIC and AIC are fundamentally different. AIC must be implemented from scratch based on Apple Silicon behavior.

### ARM Generic Timer - REMOVED

**Current Role in QEMU:**
- Standard ARM timer implementation.
- Generic timer registers and behavior.

**Justification for Removal:**
- Apple Silicon uses custom timer implementation.
- Register layout differs from generic timer.
- Timer behavior has Apple-specific quirks.

**Replacement:**
- Apple Timer implementation.
- Apple-specific register addresses.
- Apple timer semantics.

**Why Not Modified:**
Generic ARM timer interface is incompatible with Apple's timer. Custom implementation required.

## Platform and Machine Models

### virt Machine - REMOVED

**Current Role in QEMU:**
- Generic ARM virtualization platform.
- Standard device layout.
- SBSA-compatible configuration.

**Justification for Removal:**
- Apple Silicon is not virt-compatible.
- Device layout is completely different.
- SBSA concepts do not apply.

**Replacement:**
- apple-silicon-bringup machine model.
- Apple-specific device topology.
- Apple platform initialization sequence.

**Why Not Modified:**
virt machine assumptions are incompatible with Apple Silicon. Complete replacement required.

### Other ARM Machines (Raspi, etc.) - REMOVED

**Current Role in QEMU:**
- Raspberry Pi, Xilinx, other ARM boards.
- Board-specific configurations.

**Justification for Removal:**
- Not Apple Silicon.
- Different hardware topology.
- Irrelevant to macOS.

**Removed Components:**
- All non-Apple machine models.
- Board-specific initialization.
- Platform-specific device configurations.

**Why Not Retained:**
These machines serve different purposes. Apple-on-Virt targets only Apple Silicon.

## Device Emulation

### PCI Infrastructure - REMOVED

**Current Role in QEMU:**
- PCI bus emulation.
- PCI device enumeration.
- PCIe support.

**Justification for Removal:**
- Apple Silicon uses proprietary interconnects, not PCI.
- macOS does not enumerate PCI on Apple Silicon.
- PCI address space is not present.

**Removed Components:**
- PCI bus implementation.
- PCI device discovery.
- PCI configuration space.

**Why Not Retained:**
PCI is not part of Apple Silicon platform. Maintaining it adds unnecessary complexity.

### VirtIO Devices - MODIFIED (Internal Only)

**Current Role in QEMU:**
- Paravirtualized device interfaces.
- VirtIO-block, virtio-net, etc.

**Justification for Modification:**
- VirtIO provides efficient device transport.
- Must be hidden behind Apple device identity.
- Implementation detail, not exposed to macOS.

**Modification Scope:**
- Use virtio transport internally.
- Present Apple device identity to macOS.
- No virtio device tree nodes.
- No virtio driver loading in macOS.

**Why Not Removed:**
VirtIO provides efficient implementation. As long as macOS sees Apple devices, internal transport is acceptable.

### Storage Devices - MODIFIED

**Current Role in QEMU:**
- Block device emulation.
- Various storage controllers.

**Justification for Modification:**
- Must present Apple-compatible storage interface.
- Register layout must match Apple expectations.
- Device tree node must use Apple compatible string.

**Modification Scope:**
- Apple storage device identity.
- Apple register interface.
- Apple device tree properties.
- Internal implementation can use QEMU infrastructure.

**Why Not Removed:**
QEMU storage infrastructure is reusable. Device identity and interface need Apple compatibility.

### Serial/UART - MODIFIED

**Current Role in QEMU:**
- Serial port emulation.
- UART implementations (16550, PL011, etc.).

**Justification for Modification:**
- Must present Apple UART interface.
- Register addresses must match Apple Silicon.
- Device tree compatible string must be Apple-specific.

**Modification Scope:**
- Apple UART register layout.
- Apple serial device identity.
- Apple UART behavior quirks if any.

**Why Not Removed:**
Basic UART functionality is standard. Identity and addressing need Apple compatibility.

### Display/GPU - REMOVED (Initial Phase)

**Current Role in QEMU:**
- Graphics card emulation.
- Display output.
- VGA/SVGA/VirtIO-GPU.

**Justification for Removal:**
- Initial target is headless boot.
- Apple GPU is complex and undocumented.
- Display support is future work.

**Future Consideration:**
- Apple display controller research.
- Framebuffer implementation.
- macOS GUI support.

**Why Not Retained:**
Not required for initial bring-up. Adds significant complexity. Can be added later.

### Network Devices - REMOVED (Initial Phase)

**Current Role in QEMU:**
- Network interface emulation.
- Various NIC models.

**Justification for Removal:**
- Not required for headless boot.
- Apple network interface specifics need research.
- Networking is future work.

**Future Consideration:**
- Apple Ethernet controller emulation.
- Network boot support.
- Network services in userspace.

**Why Not Retained:**
Not essential for kernel bring-up. Can be added after basic boot succeeds.

## Firmware and Boot

### UEFI Firmware - REMOVED

**Current Role in QEMU:**
- UEFI implementation.
- OVMF firmware support.

**Justification for Removal:**
- Apple Silicon does not use UEFI.
- iBoot/boot.efi are not UEFI-compliant.
- Completely incompatible boot model.

**Removed Components:**
- UEFI firmware code.
- UEFI variable storage.
- UEFI boot services.
- UEFI runtime services.

**Why Not Modified:**
UEFI and Apple boot are fundamentally incompatible. Platform Boot Layer replaces firmware role.

### BIOS - REMOVED

**Current Role in QEMU:**
- Legacy BIOS for x86.
- Not relevant to ARM.

**Justification for Removal:**
- No BIOS on ARM64.
- No BIOS on Apple Silicon.
- x86-specific concept.

**Why Not Retained:**
BIOS is x86 legacy. Never applicable to Apple Silicon.

### Direct Kernel Boot - REMOVED

**Current Role in QEMU:**
- Boot Linux kernel directly.
- Bypass bootloader.

**Justification for Removal:**
- macOS requires boot chain (iBoot → boot.efi → kernelcache).
- Cannot boot kernelcache directly.
- Boot chain integrity is essential.

**Why Not Retained:**
Direct boot violates project principles. Complete boot chain must execute.

## Monitoring and Debugging

### GDB Stub - RETAINED

**Current Role in QEMU:**
- GDB remote debugging support.
- Breakpoints and single-stepping.

**Justification for Retention:**
- Essential for bring-up debugging.
- Allows kernel debugging.
- No Apple-specific changes needed.

**Usage:**
- Debug CPU state during boot.
- Set breakpoints in iBoot/boot.efi/kernel.
- Inspect registers and memory.

**Why Not Removed:**
Critical debugging tool. Works with arm64e without modification.

### Monitor Console - RETAINED

**Current Role in QEMU:**
- QEMU monitor for emulator control.
- Inspect and modify emulator state.

**Justification for Retention:**
- Useful for debugging.
- Inspect device state.
- Control emulation.

**Usage:**
- Query device registers.
- Dump memory regions.
- Control execution.

**Why Not Removed:**
Valuable debugging aid. No conflict with Apple Silicon emulation.

### Trace Infrastructure - RETAINED

**Current Role in QEMU:**
- Dynamic tracing support.
- Event logging.

**Justification for Retention:**
- Helps understand boot failures.
- Track device interactions.
- Debug timing issues.

**Usage:**
- Trace instruction execution.
- Log device register access.
- Monitor interrupt delivery.

**Why Not Removed:**
Essential for observability during bring-up. Platform-agnostic infrastructure.

## Build System and Infrastructure

### Meson Build System - RETAINED

**Current Role in QEMU:**
- Build configuration.
- Dependency management.
- Target selection.

**Justification for Retention:**
- Mature build system.
- Handles complex dependencies.
- Supports cross-compilation.

**Usage:**
- Configure Apple-on-Virt build.
- Disable unused QEMU components.
- Build only necessary code.

**Why Not Removed:**
Replacing build system adds no value. Meson configuration can select Apple-specific components.

### Python Scripts - RETAINED (Selectively)

**Current Role in QEMU:**
- Code generation.
- Build helpers.
- Testing infrastructure.

**Justification for Retention:**
- Some scripts are universally useful.
- Code generation for CPU models.
- Documentation generation.

**Usage:**
- Generate arm64e instruction decoders.
- Build system helpers.
- Test harness (if applicable).

**Why Not Removed:**
Useful scripts are kept, QEMU-specific scripts removed. Evaluated case-by-case.

## Testing and Validation

### QEMU Test Suite - REMOVED

**Current Role in QEMU:**
- Tests for QEMU features.
- Multi-platform validation.
- Generic ARM tests.

**Justification for Removal:**
- QEMU-specific, not Apple-specific.
- Tests features not used in Apple-on-Virt.
- Different validation requirements.

**Replacement:**
- Apple-on-Virt specific tests.
- macOS boot validation.
- Platform fidelity tests.

**Why Not Retained:**
QEMU tests validate QEMU functionality. Apple-on-Virt needs macOS-specific validation.

## Categorization Summary

### Retained (Used As-Is)

- ARMv8 base instruction implementation
- GDB stub
- Monitor console
- Trace infrastructure
- Meson build system
- Select Python scripts

**Count**: ~6 major subsystems

**Rationale**: Provide essential, platform-agnostic infrastructure.

### Modified (Adapted for Apple Silicon)

- TCG (arm64e extensions)
- CPU execution loop (exception semantics)
- Memory subsystem (address space layout)
- VirtIO devices (internal transport only)
- Storage devices (Apple identity)
- Serial/UART (Apple registers)

**Count**: ~6 major subsystems

**Rationale**: Core functionality useful but requires Apple-specific adaptation.

### Removed (Not Relevant)

- Generic ARM CPU models
- GIC (Generic Interrupt Controller)
- ARM Generic Timer
- virt and other ARM machines
- PCI infrastructure
- UEFI firmware
- BIOS
- Direct kernel boot
- Display/GPU (initial phase)
- Network devices (initial phase)
- QEMU test suite

**Count**: ~11 major subsystems

**Rationale**: Not applicable to Apple Silicon or not needed for initial bring-up.

## Implementation Strategy

### Phase 1: Minimal Viable Emulator

Retain/modify only what is essential:
- ARMv8 base + arm64e extensions
- CPU execution loop
- Memory subsystem
- Serial console
- GDB stub for debugging

### Phase 2: Complete Headless Boot

Add necessary devices:
- Storage device (Apple identity)
- Timer (Apple implementation)
- Interrupt controller (AIC)

### Phase 3: Optimization

Optimize modified subsystems:
- TCG arm64e performance
- Memory access efficiency
- Device emulation speed

### Phase 4: Feature Expansion

Add removed components if needed:
- Display support
- Network support
- Additional devices

## Justification Documentation

Each categorization decision is justified by:

1. **Relevance**: Is this subsystem relevant to Apple Silicon arm64e?
2. **Compatibility**: Can this subsystem work with Apple platform assumptions?
3. **Necessity**: Is this subsystem required for macOS bring-up?
4. **Maintainability**: Does keeping this subsystem aid or hinder the project?

## Long-Term QEMU Relationship

### Current State: QEMU Substrate

Apple-on-Virt currently uses QEMU as implementation substrate:
- Builds on QEMU codebase.
- Modifies/extends for Apple Silicon.
- Removes irrelevant components.

### Future Goal: QEMU Independence (Optional)

Long-term, QEMU dependency may be reduced:
- Replace QEMU components with custom implementations.
- Maintain only essential QEMU infrastructure.
- Evaluate on case-by-case basis.

### Criterion for Replacement

Replace QEMU component when:
- QEMU abstraction is insufficient for Apple Silicon.
- QEMU component adds excessive complexity.
- Custom implementation provides better platform fidelity.
- Maintenance burden justifies replacement.

### Criterion for Retention

Retain QEMU component when:
- Provides mature, tested functionality.
- Platform-agnostic infrastructure.
- No Apple-specific concerns.
- Replacing would duplicate significant effort without benefit.
