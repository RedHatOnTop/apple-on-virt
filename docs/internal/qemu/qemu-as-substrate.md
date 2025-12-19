# QEMU as Substrate

This document explains why and how QEMU is used as a substrate for the Apple Silicon platform reconstruction project.

## Philosophy

QEMU is used as an **implementation substrate**, not as a generic emulator to be extended. The goal is NOT to create a QEMU fork that could be upstreamed. The goal IS to leverage QEMU's proven infrastructure for a single-purpose emulator.

## Why QEMU?

### What QEMU Provides

1. **TCG (Tiny Code Generator)**
   - Mature ARM64 instruction translation
   - Efficient JIT compilation
   - Cross-platform host support

2. **Memory System**
   - MemoryRegion abstraction
   - Address space management
   - Memory-mapped I/O infrastructure

3. **Device Model Infrastructure**
   - QOM (QEMU Object Model) for device hierarchy
   - Device realization framework
   - IRQ routing

4. **Debugging Support**
   - GDB stub for remote debugging
   - Memory inspection
   - Register access

5. **I/O Infrastructure**
   - Block device layer
   - Network stack
   - Character devices

### What QEMU Does NOT Provide

1. **Apple-Specific Knowledge**
   - No Apple Silicon boot sequence
   - No Apple device tree format
   - No Apple-specific devices

2. **arm64e Semantics**
   - No PAC instruction semantics
   - No Apple-specific system registers
   - No secure boot verification

3. **Platform Identity**
   - No chip-id, board-id synthesis
   - No platform-specific NVRAM
   - No Apple serial number handling

## Retained Subsystems

The following QEMU subsystems are retained and used:

| Subsystem | Usage | Notes |
|-----------|-------|-------|
| TCG | CPU emulation | ARM64 translation |
| Memory | Address spaces | MemoryRegion API |
| QOM | Object model | Device/machine hierarchy |
| Block | Storage | Virtual disks |
| Chardev | Serial I/O | Console output |
| GDB stub | Debugging | Remote debugging |
| Main loop | Event handling | Timer and I/O events |

## Removed/Disabled Subsystems

The following are disabled or not used:

| Subsystem | Status | Reason |
|-----------|--------|--------|
| KVM/HVF | Disabled | Using TCG only |
| virt machine | Disabled | Apple-specific machine only |
| SBSA machine | Disabled | Not Apple Silicon |
| All ARM boards | Disabled | Only apple-silicon-bringup |
| ACPI | Not used | Apple uses device tree |
| UEFI | Not used | Apple boot is not UEFI |
| PCI auto-config | Limited | Apple has fixed topology |

## Integration Approach

### Machine Model

QEMU's MachineClass provides:
- Machine initialization entry point
- CPU creation hooks
- Memory configuration
- Device instantiation

We implement a single machine (`apple-silicon-bringup`) that:
- Creates Apple-like memory layout
- Instantiates Apple-like CPU
- Synthesizes pre-boot state

### CPU Model

QEMU's ARMCPUClass provides:
- Register definitions
- Instruction execution
- Exception handling

We extend this with:
- Apple-specific CPU model (`apple-arm64e`)
- Future: PAC semantics
- Future: Apple system registers

### Memory Model

QEMU's memory system provides:
- Physical address space
- Memory regions
- MMIO callbacks

We use this for:
- Apple Silicon memory map
- Device MMIO ranges
- Secure region definition

## What We Do NOT Do

1. **No Upstream Compatibility**
   - We modify QEMU freely
   - No concern for upstream merge
   - Internal consistency over compatibility

2. **No Generic ARM Support**
   - Only Apple Silicon platform
   - Only arm64e execution
   - No 32-bit ARM

3. **No Multi-Machine Support**
   - Single machine type
   - No machine variants
   - No runtime machine selection

4. **No Accelerator Support**
   - TCG only
   - No KVM
   - No HVF

## Technical Decisions

### Why Fork Instead of Plugin?

1. Machine models cannot be plugins in QEMU
2. Deep integration needed for boot flow
3. Clean surface reduction requires source modification

### Why Not Just Patch QEMU?

1. Changes are too invasive for patches
2. Would conflict with upstream constantly
3. Single-purpose design doesn't fit upstream model

### Why This QEMU Version?

- QEMU 9.2.4 (latest stable at project start)
- Mature ARM64 support
- Stable AArch64 exception handling
- Good debugging support

## Summary

QEMU provides:
- Proven CPU emulation
- Memory and I/O infrastructure
- Device model framework

We add:
- Apple Silicon machine model
- Apple-specific CPU extensions
- Platform Boot Layer synthesis

The result is a purpose-built emulator, not a generic VM.
