# QEMU Command Reference for macOS Monterey ARM64
# Last updated: 2025-12-16
#
# This file contains the complete QEMU command generated according to 
# Prompt 1 specifications from LLM_Prompts_for_macOS_Emulator_Development.md

## JSON Output (Per Prompt 1 Schema)

```json
{
  "task_id": "PROMPT1-QEMU-BOOT-MACOS-MONTEREY-ARM64",
  "shell_command": "qemu-system-aarch64 -M virt,highmem=on -cpu host -accel hvf -m 4G -smp 4 -bios /usr/share/edk2/aarch64/QEMU_EFI.fd -drive file=BaseSystem.img,if=mtd,format=raw -drive file=mac_hdd.img,if=virtio,format=qcow2 -device ramfb -device virtio-gpu-pci -nic user,model=virtio-net-pci -device usb-ehci -device usb-kbd -device usb-mouse -display cocoa,gl=on",
  "rationale": "This command configures QEMU for optimal macOS Monterey ARM64 execution on Apple Silicon hosts. It uses HVF (Hypervisor.Framework) for native virtualization, VirtIO paravirtualized devices for improved I/O performance, and EDK2 UEFI firmware for proper boot sequence. The ramfb device provides fallback graphics if virtio-gpu fails. USB HID devices enable keyboard and mouse input.",
  "expected_outcome": "QEMU boots the macOS Monterey ARM64 installer from BaseSystem.img, displays the Apple logo and progress bar, then presents the macOS Recovery environment with Disk Utility and installer options visible in the GUI.",
  "is_success": false
}
```

## Command Breakdown

### Core Machine Configuration
```bash
qemu-system-aarch64 \
  -M virt,highmem=on \      # ARM64 virtual platform with >4GB memory support
  -cpu host \                # Use host CPU model (M1/M2/M3)
  -accel hvf \               # Apple Hypervisor.Framework acceleration
  -m 4G \                    # 4GB RAM allocation
  -smp 4                     # 4 virtual CPU cores
```

### UEFI Firmware
```bash
  -bios /usr/share/edk2/aarch64/QEMU_EFI.fd
```
EDK2 ArmVirtPkg provides UEFI boot support required by macOS.
Alternative paths:
- macOS (Homebrew): `/opt/homebrew/share/qemu/edk2-aarch64-code.fd`
- Linux: `/usr/share/edk2/aarch64/QEMU_EFI.fd`

### Storage Configuration
```bash
  -drive file=BaseSystem.img,if=mtd,format=raw \    # Installer image
  -drive file=mac_hdd.img,if=virtio,format=qcow2    # System disk
```
- `mtd`: Memory technology device controller for installer
- `virtio`: Paravirtualized block device for better performance

### Graphics
```bash
  -device ramfb \            # Basic framebuffer (fallback)
  -device virtio-gpu-pci \   # Paravirtualized GPU
  -display cocoa,gl=on       # macOS native display with Metal/GL
```

### Networking
```bash
  -nic user,model=virtio-net-pci
```
User-mode NAT networking with paravirtualized adapter.

### Input Devices
```bash
  -device usb-ehci \         # USB controller
  -device usb-kbd \          # USB keyboard
  -device usb-mouse          # USB mouse
```

## Full Command (Single Line)

```bash
qemu-system-aarch64 -M virt,highmem=on -cpu host -accel hvf -m 4G -smp 4 -bios /usr/share/edk2/aarch64/QEMU_EFI.fd -drive file=BaseSystem.img,if=mtd,format=raw -drive file=mac_hdd.img,if=virtio,format=qcow2 -device ramfb -device virtio-gpu-pci -nic user,model=virtio-net-pci -device usb-ehci -device usb-kbd -device usb-mouse -display cocoa,gl=on
```

## Full Command (Multi-Line for Readability)

```bash
qemu-system-aarch64 \
  -M virt,highmem=on \
  -cpu host \
  -accel hvf \
  -m 4G \
  -smp 4 \
  -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
  -drive file=BaseSystem.img,if=mtd,format=raw \
  -drive file=mac_hdd.img,if=virtio,format=qcow2 \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -device usb-ehci \
  -device usb-kbd \
  -device usb-mouse \
  -display cocoa,gl=on
```

## Linux ARM64 Host Variant

For Linux ARM64 hosts with KVM support:

```bash
qemu-system-aarch64 \
  -M virt,highmem=on \
  -cpu host \
  -accel kvm \
  -m 4G \
  -smp 4 \
  -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
  -drive file=BaseSystem.img,if=mtd,format=raw \
  -drive file=mac_hdd.img,if=virtio,format=qcow2 \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -device usb-ehci \
  -device usb-kbd \
  -device usb-mouse \
  -display gtk,gl=on
```

## Quality Gate Criteria

The command is considered successful (`is_success: true`) when:
1. QEMU starts without immediate errors
2. UEFI firmware initializes (EFI shell or boot manager visible)
3. macOS installer begins loading (Apple logo appears)
4. macOS Recovery environment GUI is displayed
5. Disk Utility and macOS installer options are accessible

## Troubleshooting

### Boot Fails Immediately to (qemu) Prompt
- Verify UEFI firmware path exists
- Check BaseSystem.img is valid macOS installer image

### No Display Output
- Try removing `-device virtio-gpu-pci` and rely on `ramfb`
- Verify display backend (`cocoa` for macOS, `gtk` for Linux)

### Performance Issues
- Verify HVF/KVM acceleration is active (not TCG)
- Increase RAM allocation (`-m 8G`)
- Increase CPU cores (`-smp 8`)

## References

- Technical Specification Section 1.2: Step-by-Step Implementation Plan
- QEMU Documentation: https://www.qemu.org/docs/master/
- EDK2 Project: https://github.com/tianocore/edk2
