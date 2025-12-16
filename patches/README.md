# QEMU XNU Compatibility Patches

Last updated: 2025-12-16

## Overview

These patches provide minimal modifications to QEMU 10.x to enable XNU (macOS/Darwin kernel) boot support. The patches are designed to be:

1. **Universal**: Not tied to specific macOS versions
2. **Minimal**: Only essential changes for XNU boot
3. **Maintainable**: Easy to apply to future QEMU versions

## Patch Files

| Patch | Purpose | Required |
|-------|---------|----------|
| 01-apple-sysregs.patch | Apple-specific ARM64 system registers | Yes |
| 02-apple-virt-machine.patch | Apple-compatible virtual machine type | Yes |
| 03-xnu-boot-support.patch | XNU kernel loading support | Yes |
| 04-apple-uart.patch | Apple-compatible UART for serial output | Optional |

## Architecture

### Apple System Registers

XNU kernel expects Apple-specific ARM64 system registers that are not part of standard ARM architecture:

- **HID registers**: Hardware Implementation Defined registers (HID3-11, EHID1/4/10)
- **PMC registers**: Performance Monitor Control (PMC0, PMC1, PMCR1, PMSR)
- **APRR/CTRR**: Apple Page/Region Protection and Configurable Text Region Range
- **Other**: LSU_ERR_STS, CYC_CFG, CYC_OVRD, IPI_SR, etc.

These are implemented as stub registers that accept writes and return safe defaults.

### Apple Virtual Machine

The `apple-virt` machine type extends the standard `virt` machine with:

- Apple-specific register definitions registered at CPU initialization
- Modified memory layout compatible with XNU expectations
- Support for Apple Device Tree format (different from standard FDT)

### XNU Boot Support

XNU kernel boot requires:

1. **Mach-O kernel loading**: Parse Mach-O format kernelcache
2. **Device Tree**: Apple-format device tree with required nodes
3. **Boot arguments**: Kernel command line via boot-args
4. **CPACR setup**: Floating-point access configuration

## Building Patched QEMU

```bash
# Clone QEMU
git clone https://gitlab.com/qemu-project/qemu.git
cd qemu
git checkout v10.0.0  # or latest stable

# Apply patches in order
git apply ../patches/01-apple-sysregs.patch
git apply ../patches/02-apple-virt-machine.patch
git apply ../patches/03-xnu-boot-support.patch

# Configure
./configure --target-list=aarch64-softmmu --enable-gtk

# Build
make -j$(nproc)
```

## Usage

After building, the patched QEMU provides:

```bash
# List available machines
./build/qemu-system-aarch64 -machine help | grep apple

# Boot XNU kernel
./build/qemu-system-aarch64 \
  -M apple-virt \
  -cpu max \
  -m 6G \
  -kernel path/to/kernelcache \
  -dtb path/to/DeviceTree.dtb \
  -append "cpus=1 rd=md0 serial=2" \
  -serial mon:stdio
```

## Compatibility

| QEMU Version | Status |
|--------------|--------|
| 10.0.x | Supported |
| 10.1.x | Supported |
| 10.2.x | Testing |

## References

- XNU source: https://github.com/apple-oss-distributions/xnu
- ARM Architecture Reference Manual
- QEMU Developer Documentation
