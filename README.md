# Apple-on-Virt: macOS Monterey ARM64 Emulator

A project aimed at running macOS Monterey (12.x) ARM64 on general-purpose ARM hardware using QEMU-based virtualization.

## Project Overview

This project provides tools and configurations for building an ARM64 macOS Monterey execution environment. The project is systematically divided into three key milestones:

1. **Milestone 1**: ARM-based macOS Emulator Construction
2. **Milestone 2**: Real Hardware Execution Conditions Research and Validation  
3. **Milestone 3**: ARM OpenCore Development and Custom Emulator Creation

## Requirements

### Host System
- **Recommended**: Apple Silicon Mac (M1/M2/M3) for native virtualization (HVF)
- **Alternative**: Linux ARM64 host with KVM support
- **Experimental**: Windows with WSL2 (TCG emulation only - very slow)
- Minimum 8GB RAM (4GB+ allocated to VM)
- 50GB+ free disk space

### Software Dependencies
- QEMU 7.0+ with aarch64 support
- EDK2 UEFI firmware for AArch64
- Python 3.8+ (for helper scripts)

### Installation (macOS Host)
```bash
# Install QEMU via Homebrew
brew install qemu

# EDK2 firmware is typically included with QEMU installation
```

### Installation (Linux ARM64 Host)
```bash
# Ubuntu/Debian
sudo apt install qemu-system-arm qemu-efi-aarch64

# Fedora
sudo dnf install qemu-system-aarch64 edk2-aarch64
```

### Installation (WSL2 - Experimental)
```bash
# Install QEMU in WSL Ubuntu
sudo apt update
sudo apt install qemu-system-arm qemu-efi-aarch64

# Note: WSL uses TCG emulation (x86_64 host cannot accelerate ARM64)
# Performance will be extremely limited - for research purposes only
```

## Quick Start

### 1. Prepare Installation Media

Place your macOS Monterey IPSW file in the `local_storage/ipsw/` directory.

### 2. Create Virtual Disk

```bash
qemu-img create -f qcow2 mac_hdd.img 128G
```

### 3. Boot the Emulator

**macOS/Linux ARM64 Host:**
```bash
./scripts/launch-macos.sh
```

**WSL2 (Experimental):**
```bash
./scripts/launch-macos-wsl.sh
```

See `config/qemu-command-reference.md` or `config/qemu-command-reference-wsl.md` for detailed configurations.

## Project Structure

```
apple-on-virt/
├── docs/
│   ├── plan/           # Project planning documents
│   └── spec/           # Technical specifications
├── scripts/            # Launch and utility scripts
├── config/             # QEMU and OpenCore configurations
├── kexts/              # Kernel extensions
├── efi/                # UEFI firmware files
├── local_storage/      # IPSW files and reference repositories
└── output/             # Build outputs and logs
```

## Core Technical Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Hypervisor | QEMU + HVF/KVM | ARM64 virtualization |
| Firmware | EDK2 ArmVirtPkg | UEFI boot support |
| GPU | virtio-gpu-pci | 2D GUI rendering |
| Network | virtio-net-pci | Paravirtualized networking |
| Storage | virtio-blk | Paravirtualized disk I/O |

## Kernel Extensions (Kexts)

**Important**: ARM64 macOS emulation uses a fundamentally different approach than x86 Hackintosh.

### ARM64 Emulation Approach (This Project)

For ARM64 macOS emulation in QEMU:
- Kexts are bundled in the **prelinked kernelcache** from IPSW
- No external Kext injection required
- No OpenCore/Clover bootloader needed
- 97+ Kexts load automatically from kernelcache

### NOT Applicable (x86 Hackintosh Only)

The following Kexts are for x86 Hackintosh and do NOT apply to ARM64 emulation:

| Kext | Why Not Needed |
|------|----------------|
| Lilu.kext | x86 binary patching framework |
| VirtualSMC.kext | SMC emulated in QEMU machine code |
| WhateverGreen.kext | x86 GPU driver patches |
| BlueToolFixup.kext | x86 Bluetooth patches |

For complete Kext documentation, see:
- [Kext Configuration Guide](docs/spec/Kext_Configuration_ARM64.md)
- [Kext Directory README](kexts/README.md)

## Documentation

- [Project Plan (Korean)](docs/plan/macOS%20Monterey%20ARM64%20실행%20환경%20구축%20프로젝트%20기획서.md)
- [Technical Specification](docs/spec/macOS_Monterey_ARM64_Execution_Environment_Specification.md)
- [WSL Implementation Guide](docs/spec/WSL_QEMU_Implementation_Guide.md)
- [Kext Configuration (ARM64)](docs/spec/Kext_Configuration_ARM64.md)
- [Implementation Report](docs/spec/Implementation_Report.md)
- [LLM Development Prompts](docs/spec/LLM_Prompts_for_macOS_Emulator_Development.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This project is for educational and research purposes only. Running macOS on non-Apple hardware may violate Apple's End User License Agreement. Users are responsible for ensuring compliance with all applicable laws and license agreements.

## Contributing

Contributions are welcome! Please read the documentation and follow the established coding standards.

## Acknowledgments

- [QEMU Project](https://www.qemu.org/)
- [EDK2/TianoCore](https://github.com/tianocore/edk2)
- [Dortania OpenCore Guide](https://dortania.github.io/OpenCore-Install-Guide/)
- [kholia/OSX-KVM](https://github.com/kholia/OSX-KVM)
- [UTM](https://github.com/utmapp/UTM)
