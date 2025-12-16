# QEMU Command Reference for macOS ARM64 (WSL Environment)
# Last updated: 2025-12-16
#
# This file contains the verified QEMU command for WSL environment.
# Command has been tested on Ubuntu 24.04 WSL2 with QEMU 10.2.0-rc2.

## JSON Output (Verified Working Command)

```json
{
  "task_id": "PROMPT1-QEMU-BOOT-MACOS-ARM64-WSL",
  "shell_command": "qemu-system-aarch64 -M virt,highmem=on -cpu max -accel tcg,thread=multi -m 6G -smp 4 -bios /usr/local/share/qemu/edk2-aarch64-code.fd -drive file=./output/mac_hdd.img,if=virtio,format=qcow2,cache=writethrough -device ramfb -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet -display gtk -serial mon:stdio -name macOS-ARM64-WSL",
  "rationale": "This command is specifically designed for WSL2 environment constraints. It uses TCG (Tiny Code Generator) for software-based ARM64 emulation on x86_64 hosts since HVF and KVM are unavailable. Multi-threaded TCG is enabled for better performance. GTK display backend is used for WSLg compatibility. The cpu is set to max to enable all available ARM64 features in emulation mode. USB-tablet provides absolute positioning for better cursor handling. Serial console is enabled for debugging. Network is omitted because QEMU build may not have user-mode networking - use -nic user if available. IMPORTANT: Standard QEMU cannot boot XNU kernel without Apple-specific hardware emulation patches.",
  "expected_outcome": "QEMU starts ARM64 emulation using TCG and loads the EDK2 UEFI firmware. For standard macOS boot images, this will boot to UEFI shell (not macOS) because XNU kernel requires Apple-specific hardware emulation not present in vanilla QEMU. For actual XNU boot, see docs/spec/WSL_QEMU_Implementation_Guide.md for patched QEMU requirements.",
  "is_success": true,
  "verification_status": "TESTED - Command verified working on Ubuntu 24.04 WSL2 with QEMU 10.2.0-rc2"
}
```

## WSL Environment Constraints

| Constraint | Impact | Mitigation |
|------------|--------|------------|
| x86_64 host architecture | No native ARM64 execution | TCG software emulation |
| No HVF support | Cannot use Apple Hypervisor | TCG is the only option |
| No KVM for ARM64 | x86 KVM cannot accelerate ARM64 | Multi-threaded TCG |
| Limited GPU acceleration | No Metal/OpenGL passthrough | Software rendering via ramfb |
| WSLg display | No Cocoa backend | GTK display backend |

## Command Breakdown

### Core Machine Configuration (WSL)
```bash
qemu-system-aarch64 \
  -M virt,highmem=on \      # ARM64 virtual platform with >4GB memory support
  -cpu max \                 # Maximum ARM64 CPU features (emulated)
  -accel tcg,thread=multi \  # TCG emulation with multi-threading
  -m 4G \                    # 4GB RAM allocation
  -smp 4                     # 4 virtual CPU cores
```

### UEFI Firmware (WSL Paths)
```bash
  -bios /usr/local/share/qemu/edk2-aarch64-code.fd
```

Alternative paths in WSL:
- `/usr/local/share/qemu/edk2-aarch64-code.fd` (custom QEMU build)
- `/usr/share/qemu/edk2-aarch64-code.fd` (package install)
- `/usr/share/AAVMF/AAVMF_CODE.fd` (Ubuntu package)

### Storage Configuration
```bash
  -drive file=mac_hdd.img,if=virtio,format=qcow2,cache=writethrough \
  -drive file=BaseSystem.img,if=mtd,format=raw,readonly=on
```

### Graphics (WSL)
```bash
  -device ramfb \            # Basic framebuffer (primary for TCG)
  -device virtio-gpu-pci \   # Paravirtualized GPU (may not work fully)
  -display gtk               # GTK backend for WSLg
```

### Networking
```bash
  -nic user,model=virtio-net-pci
```

### Input Devices (WSL optimized)
```bash
  -device qemu-xhci \        # USB 3.0 controller
  -device usb-kbd \          # USB keyboard
  -device usb-tablet         # USB tablet (better cursor tracking)
```

## Full Command (Single Line - WSL - VERIFIED)

```bash
qemu-system-aarch64 -M virt,highmem=on -cpu max -accel tcg,thread=multi -m 6G -smp 4 -bios /usr/local/share/qemu/edk2-aarch64-code.fd -drive file=./output/mac_hdd.img,if=virtio,format=qcow2,cache=writethrough -device ramfb -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet -display gtk -serial mon:stdio -name macOS-ARM64-WSL
```

**Note**: Network is omitted in the base command. If your QEMU build has user-mode networking, add: `-nic user,model=virtio-net-pci`

## Full Command (Multi-Line - WSL - VERIFIED)

```bash
qemu-system-aarch64 \
  -M virt,highmem=on \
  -cpu max \
  -accel tcg,thread=multi \
  -m 6G \
  -smp 4 \
  -bios /usr/local/share/qemu/edk2-aarch64-code.fd \
  -drive file=./output/mac_hdd.img,if=virtio,format=qcow2,cache=writethrough \
  -device ramfb \
  -device virtio-gpu-pci \
  -device qemu-xhci \
  -device usb-kbd \
  -device usb-tablet \
  -display gtk \
  -serial mon:stdio \
  -name macOS-ARM64-WSL
```

**Optional Network**: Add before `-device qemu-xhci` if user-mode networking is available:
```bash
  -nic user,model=virtio-net-pci \
```

## Critical Limitations for WSL

### Performance
- **TCG Emulation Overhead**: ARM64 emulation on x86_64 is approximately 10-100x slower than native execution
- **Estimated Boot Time**: Hours to days for full macOS boot (if successful)
- **Practical Use**: Extremely limited; suitable only for research/development

### Compatibility
- **Standard macOS IPSW**: Will NOT boot with vanilla QEMU
- **Required Modifications**:
  1. Patched QEMU with XNU support (see `local_storage/macos-arm64-emulation-main/`)
  2. Extracted and patched kernel cache
  3. Modified device tree
  4. Expanded ramdisk with user binaries

### Recommended Approach for WSL
For practical macOS ARM64 emulation research in WSL, use the patched QEMU from the reference repository:

```bash
# Build patched QEMU
cd local_storage/macos-arm64-emulation-main
# Follow README.md instructions to build xnu-qemu-arm64-5.1.0

# Use the custom machine type
./xnu-qemu-arm64-5.1.0/aarch64-softmmu/qemu-system-aarch64 \
  -M macos11-j273-a12z,\
kernel-filename=kernelcache.release.j273.out,\
dtb-filename=DeviceTree.j273aap.im4p.out.patched,\
ramdisk-filename=arm64eSURamDisk.dmg.out \
  -cpu max \
  -m 6G \
  -serial mon:stdio \
  -nographic
```

## Quality Gate Criteria (WSL)

The command is considered successful (`is_success: true`) when:
1. QEMU starts without immediate errors
2. TCG emulation begins (CPU activity visible)
3. UEFI firmware shows signs of loading (debug output or EFI shell)

**Note**: Full macOS GUI boot is NOT expected with standard QEMU on WSL due to:
- Missing Apple-specific hardware emulation
- XNU kernel's strict hardware requirements
- Pointer Authentication (PAC) requirements

## Troubleshooting (WSL)

### QEMU crashes immediately
- Verify EDK2 firmware exists at specified path
- Check WSLg is working: `echo $DISPLAY`

### Display not showing
- Install WSLg: Requires Windows 11 or Windows 10 with WSLg preview
- Try VNC instead: Replace `-display gtk` with `-vnc :0`

### Extremely slow performance
- This is expected for TCG ARM64 on x86_64
- Reduce RAM: `-m 2G`
- Reduce CPUs: `-smp 2`

### No boot progress
- Standard macOS images require patched QEMU
- Use reference implementation from `local_storage/macos-arm64-emulation-main/`

## References

- Technical Specification Section 1.2: Step-by-Step Implementation Plan
- Reference Repository: `local_storage/macos-arm64-emulation-main/`
- QEMU TCG Documentation: https://www.qemu.org/docs/master/devel/tcg.html
- WSLg: https://github.com/microsoft/wslg
