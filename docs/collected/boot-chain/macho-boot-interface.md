---
title: MachO Boot Interface
derived-from:
  - docs/external/Asahi Linux Docs/docs/fw/macho-boot-protocol.md
project-relevance:
  Required to correctly load and jump to the guest kernel (m1n1/macOS) in the emulator.
confidence: high
---

## Extracted Facts

### Register State at Entry
- **x0**: Points to `boot_args` structure.
- **MMU**: OFF at entry.
- **RVBAR**: Locked by iBoot to the top of the entry page (cannot be changed after boot).
    - IMPORTANT: Resume from deep sleep likely restarts execution here.

### Memory Layout (Physical)
- Start of RAM: `0x8_0000_0000`
- **Bottom Range**:
    - Coprocessor carveouts, iBoot structures.
    - `0x8_0000_0000` to `boot_args->phys_base`.
- **Kernel Image Region**:
    - Starts at `boot_args->phys_base`.
    - `kASLR slide gap` (<32MiB).
    - `Device Tree (ADT)` (/chosen/memory-map.DeviceTree).
    - `Trust Cache`.
    - `Mach-O base (header)` (mapped to `vmaddr + slide`).
    - `Mach-O segments`.
    - `Payload region` (e.g., m1n1 payload).
    - `SEP Firmware`.
    - `BootArgs` (at `boot_args->top_of_kdata`).
- **Free Memory**:
    - From `boot_args->top_of_kdata` to `boot_args->mem_size`.
    - Contains iBoot trampoline.
- **Top Range**:
    - Video memory, SEP carveout.
    - Above `0x8_0000_0000 + boot_args->mem_size_actual`.

### Addresses & Pointers
- **Physical Addresses**: The only true addresses for the emulator in this phase.
- **Virtual Addresses**:
    - `vaddr = paddr + ba.virt_base - ba.phys_base` (kASLR-slid).
    - Mach-O unslid addresses are irrelevant for runtime execution, only for linking.

### Boot Args Structure
- Passed in x0.
- Contains `phys_base`, `virt_base`, `top_of_kdata`, `mem_size`, `mem_size_actual`.
- Defines the memory map provided to the kernel.

## Explicit Non-Facts / Unknowns
- Exact structure definition of `boot_args` is not fully detailed here (source links to `xnuboot.h` code, which is external).
- Practical significance of RVBAR locking is "unclear" but presumed for sleep resume.

## Notes for Future Phases
- Emulator must populate `boot_args` correctly at `top_of_kdata`.
- Emulator must load ADT, TrustCache, and Kernel into the correct physical offsets relative to `phys_base`.
- Implement `RVBAR_ELx` locking behavior if supporting resizing/sleep.
