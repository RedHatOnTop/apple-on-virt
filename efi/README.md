# EFI Firmware Files
# Last updated: 2025-12-16
#
# This directory contains UEFI firmware files required for macOS boot.

## Required Files

### EDK2 AArch64 UEFI Firmware
The primary firmware file is `QEMU_EFI.fd` from the EDK2 (TianoCore) project.

**Installation Sources:**

macOS (Homebrew):
```bash
brew install qemu
# Firmware location: /opt/homebrew/share/qemu/edk2-aarch64-code.fd
```

Ubuntu/Debian:
```bash
sudo apt install qemu-efi-aarch64
# Firmware location: /usr/share/AAVMF/AAVMF_CODE.fd
```

Fedora:
```bash
sudo dnf install edk2-aarch64
# Firmware location: /usr/share/edk2/aarch64/QEMU_EFI.fd
```

## Optional: NVRAM Variables File

For persistent NVRAM storage:
```bash
# Create a writable NVRAM file
cp /usr/share/edk2/aarch64/QEMU_VARS.fd ./NVRAM.fd
```

Then add to QEMU command:
```bash
-drive if=pflash,format=raw,file=QEMU_EFI.fd,readonly=on \
-drive if=pflash,format=raw,file=NVRAM.fd
```

## Directory Structure

```
efi/
├── README.md (this file)
├── QEMU_EFI.fd (symlink or copy of EDK2 firmware)
└── NVRAM.fd (optional, for persistent NVRAM)
```

## References

- EDK2 Project: https://github.com/tianocore/edk2
- ArmVirtPkg Documentation: https://github.com/tianocore/edk2/tree/master/ArmVirtPkg
