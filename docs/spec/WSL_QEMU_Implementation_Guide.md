# WSL QEMU Implementation Guide for macOS ARM64 Emulation

Last updated: 2025-12-16

## Executive Summary

This document outlines the technical approach for generating an executable `qemu-system-aarch64` command to boot macOS ARM64 within the Windows Subsystem for Linux (WSL) environment. Due to fundamental architectural constraints, this implementation focuses on research and development purposes rather than practical daily use.

## Environment Constraints

### WSL-Specific Limitations

| Constraint | Impact | Mitigation Strategy |
|------------|--------|---------------------|
| x86_64 host architecture | No native ARM64 execution | TCG software emulation |
| No HVF support | Cannot use Apple Hypervisor | TCG is the only option |
| No KVM for ARM64 | x86 KVM cannot accelerate ARM64 code | Multi-threaded TCG |
| Limited GPU acceleration | No Metal/OpenGL passthrough | Software rendering (ramfb) |
| WSLg display constraints | No Cocoa backend | GTK display backend |

### Performance Expectations

- **TCG Emulation Overhead**: ARM64 emulation on x86_64 is approximately 10-100x slower than native execution
- **Estimated Boot Time**: Hours for kernel boot; full GUI boot requires additional optimizations
- **Practical Use**: Extremely limited; suitable only for research and development

## Technical Analysis

### Understanding the Reference Implementation

The `local_storage/macos-arm64-emulation-main` repository provides a working approach using:

1. **Custom QEMU Machine Type**: `macos11-j273-a12z` emulating Apple iPad Pro (A12Z) hardware
2. **XNU Kernel Patches**: Version-specific binary patches at hardcoded addresses
3. **Device Tree Modifications**: Customized Apple Device Tree structure
4. **Custom Hardware Emulation**: Apple-specific register implementations (HID, EHID, PMC, etc.)

### Key Technical Challenges for Universal Implementation

#### Challenge 1: Apple-Specific System Registers

XNU kernel requires Apple-proprietary ARM system registers that QEMU's standard `virt` machine does not implement:

```
- ARM64_REG_EHID1, EHID4, EHID10
- ARM64_REG_HID3, HID4, HID5, HID7, HID8, HID11
- ARM64_REG_LSU_ERR_STS
- PMC0, PMC1, PMCR1, PMSR
- APRR, CTRR (Configurable Text Region Range)
- Various EL2 registers
```

#### Challenge 2: CPACR (Coprocessor Access Control Register)

XNU expects specific CPACR configuration for floating-point and SIMD access that must be set during early boot.

#### Challenge 3: Device Tree Structure

macOS expects Apple-format Device Tree with specific node structures, not standard FDT (Flattened Device Tree) format.

#### Challenge 4: Kernel Binary Format

XNU kernel uses Mach-O binary format with specific load commands, not standard Linux kernel image format.

## Implementation Strategy

### Approach Selection: Minimal QEMU Patch Set

Given the requirements:
- Must use latest stable QEMU (currently 10.2.x)
- Must be "universal" (not tied to specific macOS version)
- Must support GUI loading goal
- Must not use the reference repository directly

**Selected Strategy**: Create a minimal patch set for latest QEMU that:
1. Adds Apple-specific system register stubs
2. Provides basic XNU-compatible machine configuration
3. Supports standard UEFI boot path where possible

### Phase 1: Standard QEMU Baseline Test

First, establish what standard QEMU can and cannot do:

```bash
qemu-system-aarch64 \
  -M virt,highmem=on \
  -cpu max \
  -accel tcg,thread=multi \
  -m 6G \
  -smp 4 \
  -bios /usr/local/share/qemu/edk2-aarch64-code.fd \
  -drive file=mac_hdd.img,if=virtio,format=qcow2 \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -device qemu-xhci \
  -device usb-kbd \
  -device usb-tablet \
  -display gtk \
  -serial mon:stdio
```

**Expected Result**: UEFI shell loads, but macOS kernel will not boot due to missing Apple hardware.

### Phase 2: QEMU Source Modification

Required modifications to QEMU source for XNU compatibility:

#### 2.1 System Register Stubs

Create stub implementations for Apple-specific registers that return safe default values:

```c
// Example: Apple HID register stub
static uint64_t apple_hid_read(CPUARMState *env, const ARMCPRegInfo *ri) {
    return 0;  // Safe default
}

static void apple_hid_write(CPUARMState *env, const ARMCPRegInfo *ri, uint64_t value) {
    // Ignore writes - stub implementation
}
```

#### 2.2 Machine Type Enhancement

Extend the `virt` machine or create new `apple-virt` machine type with:
- Apple-specific register definitions
- Modified memory layout compatible with XNU expectations
- Device Tree generation in Apple format

### Phase 3: XNU Boot Requirements

For XNU kernel to boot, the following must be provided:

1. **Kernel Cache**: Extracted and potentially patched kernelcache from IPSW
2. **Device Tree**: Apple-format device tree with required nodes
3. **Boot Arguments**: Kernel command line arguments
4. **RAM Disk**: Optional boot ramdisk

## QEMU Command Generation

### Baseline Command (Standard QEMU - For Testing)

```bash
#!/bin/bash
# WSL macOS ARM64 Emulation - Baseline Test
# This command tests standard QEMU behavior

QEMU_BIN="qemu-system-aarch64"
FIRMWARE="/usr/local/share/qemu/edk2-aarch64-code.fd"
HDD_IMG="./output/mac_hdd.img"

$QEMU_BIN \
  -M virt,highmem=on,virtualization=off \
  -cpu max \
  -accel tcg,thread=multi \
  -m 6G \
  -smp cpus=4,cores=4 \
  -bios "$FIRMWARE" \
  -drive file="$HDD_IMG",if=virtio,format=qcow2,cache=writethrough \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -device qemu-xhci \
  -device usb-kbd \
  -device usb-tablet \
  -display gtk \
  -serial mon:stdio \
  -d guest_errors,unimp \
  -D qemu_debug.log
```

### Target Command (With XNU Support - Requires Patched QEMU)

The final command will require a patched QEMU binary with XNU support. The command structure will be similar to:

```bash
#!/bin/bash
# WSL macOS ARM64 Emulation - XNU Boot
# Requires: patched QEMU with Apple hardware emulation

QEMU_BIN="./qemu-build/aarch64-softmmu/qemu-system-aarch64"
KERNEL="./extracted/kernelcache"
DTB="./extracted/DeviceTree.dtb"
RAMDISK="./extracted/ramdisk.dmg"

$QEMU_BIN \
  -M apple-virt \
  -cpu max \
  -accel tcg,thread=multi \
  -m 6G \
  -smp 1 \
  -kernel "$KERNEL" \
  -dtb "$DTB" \
  -initrd "$RAMDISK" \
  -append "cpus=1 rd=md0 serial=2 -v" \
  -device ramfb \
  -serial mon:stdio \
  -nographic
```

## Build Instructions

### Building Patched QEMU in WSL

```bash
# Clone QEMU source
git clone https://gitlab.com/qemu-project/qemu.git
cd qemu
git checkout v10.2.0  # Latest stable

# Apply XNU compatibility patches (to be developed)
# git apply ../patches/xnu-compat.patch

# Configure for ARM64 target
./configure \
  --target-list=aarch64-softmmu \
  --enable-gtk \
  --enable-sdl \
  --disable-werror

# Build
make -j$(nproc)
```

## Quality Gate Criteria

The implementation is considered successful when:

1. **Level 1 - UEFI Boot**: QEMU starts without errors and UEFI firmware loads
2. **Level 2 - Kernel Load**: XNU kernel begins loading (visible in serial output)
3. **Level 3 - Kernel Boot**: Kernel completes initialization and starts launchd
4. **Level 4 - Shell Access**: Interactive shell prompt available
5. **Level 5 - GUI Render**: Basic GUI elements visible via ramfb/virtio-gpu

## Appendix A: File Locations

| File | Purpose | Location |
|------|---------|----------|
| QEMU Binary | Emulator | `/usr/local/bin/qemu-system-aarch64` |
| EDK2 Firmware | UEFI boot | `/usr/local/share/qemu/edk2-aarch64-code.fd` |
| Virtual Disk | macOS installation | `./output/mac_hdd.img` |
| Kernel Cache | XNU kernel | `./extracted/kernelcache` |
| Device Tree | Hardware description | `./extracted/DeviceTree.dtb` |

## Appendix B: Troubleshooting

### QEMU Crashes on Start
- Verify EDK2 firmware path is correct
- Check WSLg is functioning: `echo $DISPLAY`

### No Display Output
- Try VNC instead: `-vnc :0` instead of `-display gtk`
- Verify WSLg is installed (Windows 11 or WSL preview)

### Extremely Slow Performance
- Expected behavior for TCG emulation
- Reduce RAM: `-m 4G`
- Reduce CPUs: `-smp 2`
- Enable TCG optimizations in QEMU build

### Kernel Panic / Boot Failure
- Standard macOS images require patched QEMU
- Check serial output for specific error messages
- Review QEMU debug log for unimplemented features

## References

- [QEMU Documentation](https://www.qemu.org/docs/master/)
- [EDK2 ArmVirtPkg](https://github.com/tianocore/edk2/tree/master/ArmVirtPkg)
- [XNU Source Code](https://github.com/apple-oss-distributions/xnu)
- [Project Technical Specification](./macOS_Monterey_ARM64_Execution_Environment_Specification.md)
