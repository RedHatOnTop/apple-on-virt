# QEMU Command for macOS ARM64 on WSL

Last updated: 2025-12-16

## Final Executable Command

### Standard QEMU (UEFI Shell Boot - For Testing Infrastructure)

This command boots to UEFI shell using standard QEMU. It validates the QEMU, firmware, and display configuration work correctly in WSL:

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
  -nic user,model=virtio-net-pci \
  -device qemu-xhci \
  -device usb-kbd \
  -device usb-tablet \
  -display gtk \
  -serial mon:stdio \
  -d guest_errors,unimp \
  -name macOS-ARM64-WSL
```

### Single-Line Version

```bash
qemu-system-aarch64 -M virt,highmem=on -cpu max -accel tcg,thread=multi -m 6G -smp 4 -bios /usr/local/share/qemu/edk2-aarch64-code.fd -drive file=./output/mac_hdd.img,if=virtio,format=qcow2,cache=writethrough -device ramfb -device virtio-gpu-pci -nic user,model=virtio-net-pci -device qemu-xhci -device usb-kbd -device usb-tablet -display gtk -serial mon:stdio -name macOS-ARM64-WSL
```

## XNU Boot Command (Requires Patched QEMU)

For actual XNU kernel boot, a patched QEMU with Apple hardware emulation is required. The command structure is:

```bash
./qemu-build/qemu-10.0.0/build/qemu-system-aarch64 \
  -M apple-virt,kernel-filename=kernelcache.out,dtb-filename=DeviceTree.dtb.patched,ramdisk-filename=ramdisk.dmg,kern-cmd-args="cpus=1 rd=md0 serial=2 -v" \
  -cpu max \
  -accel tcg,thread=multi \
  -m 6G \
  -smp 1 \
  -device ramfb \
  -serial mon:stdio \
  -nographic
```

## Command Parameter Reference

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `-M virt,highmem=on` | ARM Virtual Machine | Generic ARM64 platform with >4GB memory support |
| `-cpu max` | Maximum features | Enable all available ARM64 CPU features in TCG |
| `-accel tcg,thread=multi` | TCG with threading | Software emulation with multi-core threading |
| `-m 6G` | 6GB RAM | Memory allocation for guest (adjust as needed) |
| `-smp 4` | 4 CPUs | Virtual CPU count (reduce for faster single-thread) |
| `-bios ...` | EDK2 firmware | UEFI firmware for ARM64 boot |
| `-drive file=...,if=virtio` | VirtIO block | Paravirtualized storage for performance |
| `-device ramfb` | RAM framebuffer | Basic display output for TCG |
| `-device virtio-gpu-pci` | VirtIO GPU | Accelerated graphics (limited in TCG) |
| `-nic user,model=virtio-net-pci` | User-mode network | NAT networking with virtio driver |
| `-device qemu-xhci` | USB 3.0 controller | USB host controller emulation |
| `-device usb-kbd` | USB keyboard | Input device |
| `-device usb-tablet` | USB tablet | Absolute positioning (better than mouse) |
| `-display gtk` | GTK display | Display backend for WSLg |
| `-serial mon:stdio` | Serial console | Kernel debug output and monitor |

## WSL-Specific Notes

### Display Configuration

WSLg requires GTK or SDL display backend:
- `-display gtk` - Default for WSLg
- `-display sdl` - Alternative if GTK has issues
- `-vnc :0` - VNC server on port 5900 (fallback)

### Performance Considerations

TCG emulation on x86_64 is approximately 10-100x slower than native ARM64:
- Reduce `-smp` to 1-2 for potentially faster single-threaded boot
- Reduce `-m` to 4G if host RAM is limited
- Boot time: Hours for full kernel boot

### Verification Steps

1. Verify WSLg is working:
   ```bash
   echo $DISPLAY  # Should show :0 or similar
   ```

2. Verify QEMU installation:
   ```bash
   qemu-system-aarch64 --version
   ```

3. Verify firmware exists:
   ```bash
   ls -la /usr/local/share/qemu/edk2-aarch64-code.fd
   ```

4. Create virtual disk if needed:
   ```bash
   qemu-img create -f qcow2 ./output/mac_hdd.img 128G
   ```

## Why Standard QEMU Cannot Boot XNU

macOS XNU kernel requires Apple-specific hardware features not present in standard QEMU:

1. **Apple System Registers**: HID3-11, EHID1/4/10, PMC0/1, PMCR1, PMSR, APRR, CTRR
2. **Apple Device Tree Format**: Different from standard ARM FDT
3. **Mach-O Kernel Format**: XNU uses Mach-O, not Linux kernel format
4. **CPACR Configuration**: Specific FPU/SIMD access configuration
5. **Memory Layout**: Apple-specific physical memory map

The `virt` machine type emulates generic ARM64 hardware incompatible with XNU's strict requirements.

## Next Steps for XNU Boot

To boot XNU kernel on WSL:

1. Build patched QEMU with Apple hardware emulation (see `scripts/build-qemu-xnu.sh`)
2. Extract kernel cache from IPSW (requires xar, lzfse, asn1 decode scripts)
3. Patch Device Tree with dtetool
4. Prepare ramdisk with user binaries (requires macOS for HFS+ resize)
5. Use the XNU boot command with patched QEMU

See `docs/spec/WSL_QEMU_Implementation_Guide.md` for detailed instructions.

## References

- [QEMU ARM System Emulator](https://www.qemu.org/docs/master/system/target-arm.html)
- [EDK2 ArmVirtPkg](https://github.com/tianocore/edk2/tree/master/ArmVirtPkg)
- [WSLg Documentation](https://github.com/microsoft/wslg)
