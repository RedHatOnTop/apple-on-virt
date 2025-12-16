# Kernel Extensions (Kexts) for macOS ARM64 Emulation

Last updated: 2025-12-16

## Important: ARM64 vs x86 Kext Approach

**This document clarifies the fundamental difference between ARM64 macOS emulation and x86 Hackintosh Kext handling.**

### ARM64 macOS Emulation (Our Approach)

For ARM64 macOS emulation in QEMU/WSL:

1. **Kexts are bundled in the prelinked kernelcache** - They are NOT injected externally
2. **No OpenCore/Clover required** - Boot is handled by QEMU's Apple machine emulation
3. **No Lilu/VirtualSMC needed** - These are x86 Hackintosh tools to fake Apple hardware
4. **Kexts are loaded from kernelcache** extracted from IPSW files

### x86 Hackintosh (Different Approach)

For x86 Hackintosh setups (NOT applicable to this project):
- Lilu.kext, VirtualSMC.kext, WhateverGreen.kext are required
- OpenCore/Clover bootloader injects Kexts
- SMC emulation needed because x86 hardware lacks Apple SMC

---

## Kexts in ARM64 Prelinked Kernelcache

When we extract and boot macOS ARM64, the following Kexts are automatically loaded from the kernelcache:

### Core System Kexts (Loaded from Kernelcache)

| Bundle ID | Purpose |
|-----------|---------|
| com.apple.kpi.bsd | BSD kernel interfaces |
| com.apple.kpi.iokit | IOKit kernel interfaces |
| com.apple.kpi.libkern | LibKern interfaces |
| com.apple.kpi.mach | Mach kernel interfaces |
| com.apple.kpi.private | Private kernel interfaces |
| com.apple.driver.AppleARMPlatform | ARM platform support |

### Hardware Emulation Kexts

| Bundle ID | Purpose |
|-----------|---------|
| com.apple.driver.AppleARMPMU | ARM Power Management Unit |
| com.apple.driver.AppleInterruptController | Interrupt controller |
| com.apple.driver.AppleGPIOICController | GPIO controller |
| com.apple.driver.AppleSamsungSerial | Serial UART support |
| com.apple.driver.AppleT8027 | T8027 (A12Z) SoC support |

### Storage Kexts

| Bundle ID | Purpose |
|-----------|---------|
| com.apple.iokit.IOStorageFamily | Storage framework |
| com.apple.filesystems.hfs.kext | HFS+ filesystem |
| com.apple.filesystems.apfs | APFS filesystem |
| com.apple.driver.DiskImages | Disk image support |

### Security Kexts

| Bundle ID | Purpose |
|-----------|---------|
| com.apple.driver.AppleMobileFileIntegrity | AMFI code signing |
| com.apple.kext.CoreTrust | Trust evaluation |
| com.apple.security.AppleImage4 | Image4 verification |
| com.apple.AppleSystemPolicy | System policy enforcement |

### Graphics/Display Kexts

| Bundle ID | Purpose |
|-----------|---------|
| com.apple.iokit.IOGraphicsFamily | Graphics framework |
| com.apple.driver.AppleM2ScalerCSCDriver | Display scaler |
| com.apple.iokit.IOSurface | Surface management |

### USB Kexts

| Bundle ID | Purpose |
|-----------|---------|
| com.apple.iokit.IOUSBHostFamily | USB host controller |
| com.apple.driver.usb.AppleUSBCommon | USB common framework |
| com.apple.driver.AppleUSBHostMergeProperties | USB properties |

### Network Kexts

| Bundle ID | Purpose |
|-----------|---------|
| com.apple.iokit.IONetworkingFamily | Network framework |
| com.apple.iokit.IOSkywalkFamily | Network stack |
| com.apple.nke.applicationfirewall | Application firewall |

---

## Required Actions for WSL Emulation

### What We Need to Do

1. **Extract kernelcache from IPSW**
   - Contains all bundled Kexts
   - Must be decoded (ASN1/LZFSE decompression)

2. **Patch Device Tree**
   - Configure hardware compatible strings
   - Set memory ranges and interrupts
   - Remove dependencies on unavailable hardware

3. **Build patched QEMU**
   - Apple system register support
   - Custom machine type for ARM64 macOS

### What We Do NOT Need

- [x] ~~Lilu.kext~~ - x86 Hackintosh only
- [x] ~~VirtualSMC.kext~~ - x86 Hackintosh only  
- [x] ~~WhateverGreen.kext~~ - x86 Hackintosh only
- [x] ~~BlueToolFixup.kext~~ - x86 Hackintosh only
- [x] ~~OpenCore/Clover bootloader~~ - Not applicable to QEMU emulation

---

## Kext Loading Order (Automatic from Kernelcache)

The kernelcache contains Kexts in proper dependency order. The boot process:

1. **Kernel loads** - XNU kernel initializes
2. **Core KPIs load** - Kernel Programming Interfaces (bsd, iokit, libkern, mach)
3. **Platform Kexts load** - AppleARMPlatform, interrupt controller
4. **Device Kexts load** - Storage, USB, serial, etc.
5. **Security Kexts load** - AMFI, CoreTrust, etc.
6. **Filesystem Kexts load** - HFS+, APFS
7. **launchd starts** - User space begins

---

## For GUI Boot (Future Goal)

To achieve GUI boot in QEMU emulation, additional work is needed:

### Display Requirements

1. **Framebuffer support** - QEMU ramfb provides basic framebuffer
2. **Display driver** - May need custom QEMU device or patched Kext
3. **WindowServer** - Requires proper display initialization

### Current Limitation

The reference implementation boots to a bash shell (text mode) because:
- GUI requires WindowServer and display stack
- QEMU's virtio-gpu may not be recognized by macOS ARM64 drivers
- Apple's DCP (Display Controller Processor) is not emulated

---

## Directory Contents

This directory is reserved for:

1. **Documentation** (this README)
2. **Analysis scripts** for kernelcache inspection
3. **Custom Kext development** (if needed in future)

**Note**: Pre-built Kexts like Lilu/VirtualSMC are NOT stored here because they are not applicable to ARM64 emulation.

---

## References

- XNU Source: https://github.com/apple-oss-distributions/xnu
- Prelinked Kernelcache Format: Apple's kernel loading mechanism
- Reference Implementation: `../local_storage/macos-arm64-emulation-main/`
- Dortania Guide (x86 only): https://dortania.github.io/OpenCore-Install-Guide/
