# Apple Silicon–like Platform Emulation Technical Specification

Last updated: 2025-12-17

This technical specification outlines the vision and implementation strategy for **Apple-on-Virt**, a research project focused on emulating an Apple Silicon–like platform for macOS arm64e execution. This is not a generic ARM64 emulator, but a precise reconstruction of Apple Silicon platform assumptions that enables macOS arm64e to operate as if on genuine hardware.

> This project emulates an Apple Silicon–like platform, not a generic ARM64 machine.

## Core Identity Principles

### Platform Recreation vs. Generic Emulation

Traditional ARM virtualization approaches treat macOS as just another ARM64 operating system. Apple-on-Virt recognizes that **macOS arm64e is a hardware-trusting OS** that makes specific assumptions about its underlying platform. Our approach focuses on:

- **Fulfilling platform assumptions** rather than patching around them
- **Recreating Apple Silicon conditions** instead of using generic workarounds  
- **Maintaining security model integrity** through selective adaptation

### Security Philosophy

Security mechanisms are not disabled, but selectively adapted where physical hardware assumptions cannot be met in emulation. This preserves the research integrity of the project while enabling practical execution.

## Architecture Components

### Platform Boot Layer

The foundation of our architecture replaces traditional UEFI/BIOS concepts with a **Platform Boot Layer** that provides:

- **Fake Apple SoC state**: Convincing hardware identification and topology
- **Device Tree**: Apple-specific device tree entries matching real hardware
- **Secure boot context**: Cryptographic environment enabling secure boot chain
- **Unaltered iBoot**: No modifications to Apple's bootloader

```
[Platform Boot Layer]
 ├─ Fake Apple SoC state
 ├─ Device Tree  
 ├─ Secure boot context
 └─ iBoot (unaltered)
      ↓
    boot.efi
      ↓
    kernelcache (arm64e)
```

**Strategic Goal**: QEMU/EDK2 are currently necessary tools, but the ultimate objective is achieving a state where EDK2 is no longer required.

### arm64e Semantics Implementation

This project specifically targets **arm64e semantics**, which encompasses:

- **Pointer Authentication (PAC)**: Full support for Apple's pointer security model
- **ABI Differences**: Proper handling of Apple's specific calling conventions
- **Memory Model**: Correct implementation of Apple's memory management expectations
- **Kernel/Userspace Trust**: Maintaining the pointer trust model across privilege boundaries

> Non-arm64e CPUs are unsupported unless behaviorally equivalent to Apple Silicon arm64e.

## Security Model Adaptation

### Secure Boot Chain Preservation

Rather than bypassing secure boot, we recreate the necessary context:

- **Certificate Chain**: Fake but valid-looking secure boot certificates
- **Verification Flow**: Maintaining the iBoot → boot.efi → kernelcache verification chain
- **AMFI Context**: Apple Mobile File Integrity adapted for emulation environment
- **SSV Integration**: System Software Verification assumptions fulfilled

### Minimal Intervention Policy

Our security adaptation follows strict boundaries:

- **iBoot / boot.efi**: Absolutely no patches or modifications
- **Kernel**: Minimal intervention only during early bring-up phase
- **Userspace**: Completely unpatched - no modifications to user applications
- **Kexts**: Only provide device bridges, never platform identity manipulation

## Kernel Strategy

### Bring-up Phase Hierarchy

Kernel interaction follows a strict four-phase approach:

1. **Kernel Entry & Early Init**: Minimal platform setup during initial boot
2. **Platform Assumptions Resolution**: Fulfilling Apple Silicon hardware expectations  
3. **Device Model Exposure**: Presenting emulated hardware as Apple devices
4. **Kext Integration**: Loading only after core platform is established

### Kext Philosophy

Kexts serve as **bridges for emulated devices**, not as Hackintosh-style patches. They enable:
- Proper device tree presentation to the kernel
- Apple-compatible hardware interfaces
- Standard Apple drivers to load without modification
- Abstraction of underlying virtio transport details

## Device Model Architecture

### Platform-provided Device Presentation

Devices are presented to macOS as **platform-provided Apple-facing transports**:

- **Graphics**: Kernel sees "Apple display device", not "virtio GPU"
- **Storage**: Appears as Apple NVMe/Storage controller, not virtio-blk
- **Network**: Presented as Apple network interface, not virtio-net
- **Input**: Exposed as Apple HID devices, not generic input controllers

This abstraction ensures proper driver loading and eliminates the need for extensive kernel patching.

## Development Milestones

### Phase 0: Apple Silicon Platform Assumptions Research
- Comprehensive analysis of Apple Silicon boot requirements
- Documentation of platform assumptions made by macOS arm64e
- Identification of critical security model components

### Phase 1: Headless Kernel Bring-up
- Achieve unaltered kernel execution without GUI
- Validate platform boot layer functionality
- Confirm secure boot context recreation
- Establish minimal kext bridge framework

### Phase 2: Minimal Userspace Viability
- Enable basic system services and daemons
- Achieve stable userspace execution
- Validate security model adaptation effectiveness
- Ensure proper device enumeration and recognition

### Phase 3: Display + I/O Stabilization
- Full GUI support with proper graphics drivers
- Stable storage and network I/O
- Complete input device functionality
- Performance optimization and stability testing

### Phase 4: Optional OpenCore-like Abstractions
- Higher-level convenience layers if needed
- Enhanced user experience features
- Advanced device support extensions
- Production-ready stability improvements

## Non-Goals and Boundaries

This project explicitly **does not aim** to provide:

- **Production macOS VM**: Not intended for daily use or production environments
- **Hackintosh Replacement**: Fundamentally different approach from x86 Hackintosh
- **App Store/DRM Support**: Not designed for DRM-protected content execution
- **Generic ARM64 Emulation**: Specifically targets Apple Silicon arm64e semantics only
- **Performance Optimization**: Research focus over performance (though improvements welcome)

## Technical Constraints and Assumptions

### Hardware Requirements

- **Primary Target**: Apple Silicon hosts (M1/M2/M3) for native virtualization
- **Secondary Target**: Linux ARM64 hosts with KVM support
- **Experimental**: Windows with WSL2 (TCG emulation only - very slow)
- **Unsupported**: x86 hosts attempting to emulate arm64e (technically infeasible)

### Software Dependencies

- **Hypervisor**: QEMU 7.0+ with aarch64 support (temporary dependency)
- **Platform Boot Layer**: Custom implementation replacing EDK2 UEFI
- **Helper Tools**: Python 3.8+ for development and automation scripts

## Research Methodology

### LLM-Assisted Development

Large Language Models assist in:
- Code generation for platform-specific components
- Documentation and specification refinement
- Automated testing scenario creation
- Security model analysis and validation

All LLM outputs are validated against the core principles of platform recreation and security model preservation.

### Quality Gates and Validation

Each development phase includes concrete quality gates:
- **Phase 1**: Unaltered kernel logs "Starting kernel" message
- **Phase 2**: Basic system services start without kernel panics  
- **Phase 3**: GUI desktop environment displays normally
- **Phase 4**: Standard applications execute without modification

## Future Direction

Upon successful completion of the core milestones, the project may expand to:

- **Newer macOS Versions**: Ventura, Sonoma, and beyond
- **Enhanced Security Models**: Deeper SEP emulation and secure enclave simulation
- **Custom Hypervisor**: Eliminating QEMU dependency entirely
- **Advanced Device Support**: GPU acceleration, audio, and specialized peripherals

## Conclusion

Apple-on-Virt represents a paradigm shift in macOS emulation research. By focusing on **platform assumption fulfillment** rather than **workaround implementation**, we create a more authentic and sustainable approach to Apple Silicon emulation. This methodology respects Apple's security architecture while enabling legitimate research into macOS arm64e platform requirements.

> This project is not about booting macOS on ARM hardware, but about reconstructing enough of the Apple Silicon platform for macOS arm64e to believe it is home.