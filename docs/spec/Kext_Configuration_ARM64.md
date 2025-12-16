# Kext Configuration for macOS ARM64 Emulation in WSL

Last updated: 2025-12-16

## Executive Summary

This document specifies the kernel extension (Kext) configuration for macOS ARM64 emulation in the WSL environment. It clarifies the fundamental difference between ARM64 emulation and x86 Hackintosh approaches.

**Key Finding**: Traditional Hackintosh Kexts (Lilu, VirtualSMC, WhateverGreen) are NOT applicable to ARM64 macOS emulation because they are designed for x86 architecture to fake Apple hardware on non-Apple systems.

## Architecture Comparison

### ARM64 macOS Emulation (This Project)

| Aspect | Description |
|--------|-------------|
| Architecture | ARM64 (AArch64) emulated on x86_64 via TCG |
| Boot Method | Direct kernel boot via patched QEMU |
| Kext Source | Bundled in prelinked kernelcache from IPSW |
| Bootloader | None required - QEMU handles boot |
| SMC | Emulated in QEMU machine code |

### x86 Hackintosh (NOT This Project)

| Aspect | Description |
|--------|-------------|
| Architecture | x86_64 native |
| Boot Method | OpenCore/Clover bootloader |
| Kext Source | External injection via bootloader |
| Bootloader | Required (OpenCore recommended) |
| SMC | VirtualSMC.kext fakes SMC |

## Kext Categories for ARM64 Emulation

### Category 1: Core Kernel Programming Interfaces (KPIs)

These are pseudo-Kexts providing kernel interfaces. Always present in kernelcache.

| Bundle ID | Symbol Count | Purpose |
|-----------|--------------|---------|
| com.apple.kpi.bsd | ~2000 | BSD syscall interfaces |
| com.apple.kpi.iokit | ~1500 | IOKit driver interfaces |
| com.apple.kpi.libkern | ~800 | LibKern C++ runtime |
| com.apple.kpi.mach | ~400 | Mach kernel interfaces |
| com.apple.kpi.private | ~300 | Private kernel APIs |
| com.apple.kpi.unsupported | ~100 | Unsupported but exported APIs |
| com.apple.kpi.dsep | ~50 | DSEP interfaces |

### Category 2: Platform Kexts (ARM-Specific)

These Kexts provide ARM64 Apple Silicon platform support.

| Bundle ID | Purpose | Required for Emulation |
|-----------|---------|------------------------|
| com.apple.driver.AppleARMPlatform | Base ARM platform support | Yes - emulated by QEMU |
| com.apple.driver.AppleARMPMU | Power Management Unit | Yes - stubbed |
| com.apple.driver.AppleInterruptController | AIC interrupt controller | Yes - emulated |
| com.apple.driver.AppleT8027 | A12Z SoC support | Yes - device tree match |
| com.apple.driver.AppleGPIOICController | GPIO controller | Yes - emulated |

### Category 3: Security Kexts

Critical for system boot and code signing.

| Bundle ID | Purpose | Can Bypass |
|-----------|---------|------------|
| com.apple.driver.AppleMobileFileIntegrity | AMFI code signing | Partially (boot args) |
| com.apple.kext.CoreTrust | Trust cache evaluation | No |
| com.apple.security.AppleImage4 | Image4 signature verify | No |
| com.apple.AppleSystemPolicy | System policy | No |
| com.apple.driver.AppleSEPManager | Secure Enclave | Stubbed in emulation |

### Category 4: Storage Kexts

Essential for booting from disk images.

| Bundle ID | Purpose | Notes |
|-----------|---------|-------|
| com.apple.iokit.IOStorageFamily | Storage base framework | Required |
| com.apple.filesystems.hfs.kext | HFS+ filesystem | Required for boot ramdisk |
| com.apple.filesystems.apfs | APFS filesystem | Required for system |
| com.apple.driver.DiskImages | Disk image mounting | Required |
| com.apple.driver.AppleDiskImages2 | Disk image v2 | Required |

### Category 5: I/O Kexts

For device communication.

| Bundle ID | Purpose | Emulation Notes |
|-----------|---------|-----------------|
| com.apple.driver.AppleSamsungSerial | UART serial | QEMU samsung-uart |
| com.apple.iokit.IOUSBHostFamily | USB framework | QEMU xhci |
| com.apple.driver.AppleEmbeddedPCIE | PCIe controller | Limited support |

### Category 6: Graphics Kexts (For Future GUI)

| Bundle ID | Purpose | Status |
|-----------|---------|--------|
| com.apple.iokit.IOGraphicsFamily | Graphics framework | Needs display device |
| com.apple.driver.AppleM2ScalerCSCDriver | Display scaler | Apple-specific |
| com.apple.iokit.IOSurface | Surface management | Works with framebuffer |

## Kexts NOT Required for ARM64 Emulation

The following Kexts are x86 Hackintosh-specific and should NOT be used:

| Kext | Purpose | Why Not Needed |
|------|---------|----------------|
| Lilu.kext | Runtime patching | x86 binary patching, no ARM64 support |
| VirtualSMC.kext | SMC emulation | SMC emulated in QEMU machine code |
| WhateverGreen.kext | GPU patches | x86 GPU drivers, not ARM64 |
| BlueToolFixup.kext | Bluetooth fix | x86 specific patches |
| AppleALC.kext | Audio codec | x86 audio hardware |
| VoodooPS2*.kext | PS/2 input | x86 PS/2 controller |
| VoodooI2C*.kext | I2C input | x86 specific |
| NVMeFix.kext | NVMe patches | x86 NVMe drivers |
| RestrictEvents.kext | Event filtering | x86 system events |

## Required QEMU Machine Configuration

For Kexts to load properly, QEMU must provide:

### 1. Apple System Registers

```c
// Example required registers (from patches/01-apple-sysregs.patch)
HID3, HID4, HID5, HID7, HID8, HID11    // Hardware Implementation Defined
EHID1, EHID4, EHID10                    // Extended HID
PMC0, PMC1, PMCR1, PMSR                 // Performance Monitor
APRR_EL0, APRR_EL1                      // Apple Page Protection
CTRR_*                                   // Configurable Text Region
```

### 2. Device Tree Nodes

Required device tree entries for Kext matching:

```
device-tree/
├── cpus/
│   └── cpu0/
│       ├── compatible = "apple,tempest", "ARM,v8"
│       ├── reg = <0>
│       └── state = "running"
├── arm-io/
│   ├── compatible = "arm-io,t8027"
│   ├── interrupt-controller/
│   │   └── compatible = "aic,1"
│   └── uart0/
│       └── compatible = "uart-1,samsung"
└── chosen/
    ├── dram-base = <0>
    ├── dram-size = <size>
    └── random-seed = <...>
```

### 3. Memory Layout

```
0x000000000 - 0x800000000  : RAM (variable)
0x800000000 - 0xFFFFFFFFF  : Device MMIO (arm-io)
```

## Boot Arguments Affecting Kexts

| Boot Arg | Effect on Kexts |
|----------|-----------------|
| `kextlog=0xfff` | Enable verbose Kext logging |
| `cpus=1` | Limit to single CPU (avoids SMP issues) |
| `rd=md0` | Boot from ramdisk device |
| `serial=2` | Enable serial console output |
| `-v` | Verbose boot (shows Kext loading) |
| `amfi_get_out_of_my_way=1` | Disable AMFI (allows unsigned code) |
| `cs_enforcement_disable=1` | Disable code signing enforcement |

## Kext Loading Sequence

Based on analysis of successful boot logs:

```
1. Kernel initialization
2. KPI pseudo-Kexts register (bsd, iokit, libkern, mach)
3. Core crypto: com.apple.kec.Libm, com.apple.kec.corecrypto
4. Platform: com.apple.driver.AppleARMPlatform
5. Security: AppleImage4, AppleMobileFileIntegrity, CoreTrust
6. I/O families: IOStorageFamily, IOUSBHostFamily
7. Device drivers: Serial, interrupt controller
8. Filesystem: HFS+, APFS
9. User space begins (launchd)
```

## Troubleshooting Kext Issues

### Symptom: Kernel panic during boot

**Possible Causes:**
1. Missing Apple system registers in QEMU
2. Device tree missing required nodes
3. Kext dependency not satisfied

**Debug:**
```bash
# Enable Kext logging
kern-cmd-args="kextlog=0xfff -v"
```

### Symptom: AMFI denies execution

**Solution:**
```bash
# Add to boot args
amfi_get_out_of_my_way=1
```

### Symptom: Filesystem mount fails

**Check:**
1. Ramdisk properly formatted as HFS+
2. com.apple.filesystems.hfs.kext present in kernelcache
3. md0 device properly mapped

## Future Work: GUI Boot Requirements

For WindowServer and GUI to work:

1. **Display Device**
   - QEMU ramfb provides basic framebuffer
   - May need custom virtio-gpu-apple device

2. **IOGraphics Stack**
   - IOFramebuffer implementation
   - IODisplay service

3. **WindowServer Launch**
   - Proper LaunchAgent configuration
   - Display initialization

4. **Input Stack**
   - HID (Human Interface Device) support
   - Keyboard and pointer input routing

## References

1. XNU Source Code: `local_storage/xnu-source/`
2. Reference Implementation: `local_storage/macos-arm64-emulation-main/`
3. Boot Log Analysis: `local_storage/macos-arm64-emulation-main/macos-qemu.log`
4. Device Tree Tool: `local_storage/macos-arm64-emulation-main/dtetool/`
