# Platform Boot Layer Implementation Guide

Last updated: 2025-12-17

This guide provides implementation details for the **Platform Boot Layer**, the core abstraction that replaces traditional UEFI/BIOS concepts in Apple Silicon–like platform emulation.

## Platform Boot Layer Architecture

The Platform Boot Layer serves as the foundation for Apple-on-Virt, providing the necessary boot context that macOS arm64e expects without relying on generic UEFI firmware.

### Core Components

```
[Platform Boot Layer]
 ├─ Fake Apple SoC state
 ├─ Device Tree  
 ├─ Secure boot context
 └─ iBoot (unaltered)
```

### Implementation Strategy

Rather than using EDK2 UEFI firmware as a crutch, the Platform Boot Layer directly implements Apple Silicon boot requirements:

- **Hardware Identification**: Presents convincing Apple SoC identifiers
- **Memory Layout**: Recreates Apple-specific memory mapping
- **Device Tree**: Provides Apple-compatible device tree entries
- **Secure Context**: Establishes cryptographic environment for secure boot

## QEMU Integration (Temporary)

While the ultimate goal is eliminating QEMU dependency, current implementation uses QEMU as a hardware virtualization layer with custom Platform Boot Layer integration.

### Basic Platform Boot Layer Command Structure

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -accel tcg,thread=multi \
  -m 4G \
  -smp 4 \
  -bios ./platform-boot-layer.fd \  # Custom Platform Boot Layer
  -drive file=macos_kernelcache.img,if=virtio \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -display gtk,gl=off
```

**Key Differences from Traditional Approach**:
- `-bios` points to custom Platform Boot Layer, not EDK2 UEFI
- No reliance on UEFI shell or generic ARM64 boot paths
- Direct kernelcache loading instead of multi-stage UEFI boot

## Validation Levels

### Level 1 - Platform Boot Layer Initialization
- Platform Boot Layer loads successfully
- Fake Apple SoC state established
- Device tree properly configured

### Level 2 - Secure Boot Context Establishment  
- Secure boot certificates validated
- iBoot executes without modification
- boot.efi loads correctly

### Level 3 - Kernel Bring-up
- kernelcache loads and executes
- Early platform assumptions fulfilled
- Minimal intervention during bring-up phase

## Environment Considerations

### Apple Silicon Hosts (Primary Target)
- Use native virtualization (HVF) for optimal performance
- Direct hardware acceleration available
- Best compatibility with arm64e semantics

### Linux ARM64 Hosts (Secondary Target)  
- KVM support required for reasonable performance
- May require additional platform assumption fulfillment
- Good compatibility with arm64e instruction set

### Windows WSL2 (Experimental Only)
- TCG emulation only - very slow performance
- Limited graphics and I/O capabilities
- Research purposes only, not recommended for development

## Troubleshooting

### Common Issues

**Platform Boot Layer Not Loading**:
- Verify custom firmware image integrity
- Check QEMU version compatibility
- Ensure proper memory allocation

**Secure Boot Context Failure**:
- Validate fake certificate chain
- Verify device tree Apple-specific entries
- Check SoC state recreation accuracy

**Kernel Panic During Bring-up**:
- Review platform assumption fulfillment
- Verify minimal intervention boundaries
- Check device tree compatibility

## Future Development

The Platform Boot Layer is designed to be eventually independent of QEMU:

- **Phase 1**: QEMU-integrated Platform Boot Layer
- **Phase 2**: Standalone Platform Boot Layer with custom hypervisor
- **Phase 3**: Complete elimination of external dependencies

## Conclusion

This implementation guide reflects the core philosophy of Apple-on-Virt: **reconstructing enough of the Apple Silicon platform for macOS arm64e to believe it is home**. By focusing on Platform Boot Layer implementation rather than UEFI workarounds, we create a more authentic and sustainable approach to Apple Silicon emulation.

> Security mechanisms are not disabled, but selectively adapted where physical hardware assumptions cannot be met in emulation.