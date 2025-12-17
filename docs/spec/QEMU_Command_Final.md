# Platform Boot Layer Command Reference

Last updated: 2025-12-17

This document provides the definitive QEMU command reference for Apple-on-Virt, focusing on **Platform Boot Layer** integration rather than traditional UEFI approaches.

## Core Philosophy

Commands are designed to:
- Load custom Platform Boot Layer instead of EDK2 UEFI firmware
- Present hardware as Apple-compatible devices, not generic virtio
- Minimize kernel intervention during bring-up phase
- Support arm64e semantics specifically

## Standard Platform Boot Layer Command

### Basic Headless Kernel Bring-up (Phase 1)

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -accel tcg,thread=multi \
  -m 4G \
  -smp 4 \
  -bios ./platform-boot-layer.fd \
  -drive file=macos_kernelcache.img,if=virtio \
  -serial stdio
```

**Command Breakdown**:
| Parameter | Purpose | Apple Silicon Context |
|-----------|---------|----------------------|
| `-M virt` | Virtual ARM64 platform | Base hardware abstraction |
| `-cpu cortex-a72` | ARM64 CPU model | Behaviorally equivalent to arm64e |
| `-accel tcg,thread=multi` | Multi-threaded emulation | Required for non-Apple hosts |
| `-m 4G` | Memory allocation | Minimum for macOS arm64e |
| `-smp 4` | Virtual CPU count | Matches typical Apple SoC topology |
| `-bios ./platform-boot-layer.fd` | **Custom Platform Boot Layer** | Replaces EDK2 UEFI firmware |
| `-drive file=...,if=virtio` | Kernelcache storage | Transport layer, not exposed to macOS |

### Full GUI Environment (Phase 3)

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -accel hvf \
  -m 8G \
  -smp 8 \
  -bios ./platform-boot-layer.fd \
  -drive file=macos_rootfs.img,if=virtio \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -display cocoa,gl=on
```

**Enhanced Parameters**:
| Parameter | Purpose | Apple Silicon Context |
|-----------|---------|----------------------|
| `-accel hvf` | Native virtualization | Apple Silicon hosts only |
| `-m 8G` | Increased memory | Required for GUI desktop |
| `-smp 8` | Additional CPUs | Better performance for userspace |
| `-device ramfb` | Fallback framebuffer | Ensures basic display output |
| `-device virtio-gpu-pci` | GPU transport | Abstracted as Apple display device |
| `-display cocoa,gl=on` | Native display backend | Apple-optimized rendering |

## Platform-Specific Commands

### Apple Silicon Host (Primary Target)

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu host \
  -accel hvf \
  -m 8G \
  -smp $(sysctl -n hw.ncpu) \
  -bios ./platform-boot-layer.fd \
  -drive file=macos_system.img,if=virtio \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -display cocoa,gl=on
```

### Linux ARM64 Host (Secondary Target)

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -accel kvm \
  -m 8G \
  -smp 8 \
  -bios ./platform-boot-layer.fd \
  -drive file=macos_system.img,if=virtio \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -display gtk,gl=off
```

### Windows WSL2 (Experimental Only)

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -accel tcg,thread=multi \
  -m 4G \
  -smp 4 \
  -bios ./platform-boot-layer.fd \
  -drive file=macos_system.img,if=virtio \
  -device ramfb \
  -display gtk,gl=off
```

## Validation Commands

### Platform Boot Layer Test

```bash
# Verify Platform Boot Layer loads correctly
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -m 1G \
  -bios ./platform-boot-layer.fd \
  -serial stdio
```

Expected Output: Platform Boot Layer initialization messages, fake Apple SoC state confirmation.

### Kernel Bring-up Test

```bash
# Test unaltered kernel execution
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -m 4G \
  -bios ./platform-boot-layer.fd \
  -drive file=kernelcache.img,if=virtio \
  -serial stdio
```

Expected Output: "Starting kernel" message without panics.

## Key Differences from Traditional Approach

### What Changed

| Traditional UEFI Approach | New Platform Boot Layer Approach |
|--------------------------|----------------------------------|
| `-bios /usr/share/edk2/aarch64/QEMU_EFI.fd` | `-bios ./platform-boot-layer.fd` |
| Multi-stage UEFI boot process | Direct Platform Boot Layer → iBoot |
| Generic ARM64 hardware presentation | Fake Apple SoC state recreation |
| UEFI shell as intermediate step | Direct kernelcache loading |
| Focus on UEFI compatibility | Focus on Apple Silicon assumptions |

### Why It Matters

- **Authenticity**: Presents genuine Apple Silicon platform conditions
- **Security**: Maintains secure boot chain integrity
- **Sustainability**: Eliminates dependency on generic UEFI firmware
- **Research Value**: Enables legitimate study of macOS arm64e requirements

## Troubleshooting Common Issues

### Platform Boot Layer Not Found
- Ensure `platform-boot-layer.fd` exists in current directory
- Verify file permissions and integrity
- Check QEMU version compatibility

### Kernel Panic During Boot
- Verify kernelcache.img is unmodified
- Check memory allocation (minimum 4GB required)
- Ensure CPU model supports arm64e semantics

### Display Issues
- Use `-device ramfb` as fallback
- Verify graphics backend compatibility with host OS
- Consider disabling OpenGL (`gl=off`) for stability

## Future Evolution

As the project progresses through development phases, commands will evolve:

- **Phase 1**: Basic Platform Boot Layer with headless operation
- **Phase 2**: Enhanced device model exposure
- **Phase 3**: Full GUI support with optimized parameters  
- **Phase 4**: Custom hypervisor eliminating QEMU dependency

## Conclusion

These commands reflect the core principle of Apple-on-Virt: **reconstructing enough of the Apple Silicon platform for macOS arm64e to believe it is home**. By focusing on Platform Boot Layer implementation rather than UEFI workarounds, we create a more authentic foundation for Apple Silicon emulation research.

> This project emulates an Apple Silicon–like platform, not a generic ARM64 machine.