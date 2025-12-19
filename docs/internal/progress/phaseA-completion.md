# Phase A Completion Report: QEMU Fork & Substrate Preparation

## Status: COMPLETE

## Tasks Completed

### A1: QEMU Baseline Selection

- **Selected Version**: QEMU 9.2.4 (latest stable)
- **Source**: https://download.qemu.org/qemu-9.2.4.tar.xz
- **Size**: ~128.5 MB

### A2: Fork into Private Namespace

- **Fork Location**: `emulator/qemu-apple-silicon/`
- **Fork Type**: Complete source tree copy (not git submodule)
- **Upstream Compatibility**: Explicitly NOT a goal

### A3: System Binary Rename

- **Original Name**: qemu-system-aarch64
- **New Name**: qemu-system-apple64e
- **Configuration**: `configs/targets/apple64e-softmmu.mak`
- **Device Config**: `configs/devices/apple64e-softmmu/default.mak`

## Build Verification

Build successful with:
```bash
./configure --target-list=apple64e-softmmu --disable-docs --disable-gtk --disable-sdl
ninja -j4 qemu-system-apple64e
```

Binary details:
- Size: ~95 MB
- Type: ELF 64-bit LSB pie executable, x86-64
- Status: Runs and displays machine list

## Quality Gate: Registration Mechanisms

### MachineClass Registration

**Location**: Each machine file (e.g., `hw/arm/virt.c`)

**Registration Chain**:
```
main() -> qemu_init() -> module_call_init(MODULE_INIT_QOM)
  -> type_init() callbacks execute
    -> type_register_static(&machine_info)
```

**Example** (from `hw/arm/virt.c:3352-3356`):
```c
static void machvirt_machine_init(void)
{
    type_register_static(&virt_machine_info);
}
type_init(machvirt_machine_init);
```

### CPUClass Registration

**Location**: `target/arm/cpu64.c`

**Registration Chain**:
```
main() -> qemu_init() -> module_call_init(MODULE_INIT_QOM)
  -> type_init() callbacks execute
    -> type_register_static(&aarch64_cpu_type_info)
    -> aarch64_cpu_register() for each CPU model
```

**Example** (from `target/arm/cpu64.c:856-867`):
```c
static void aarch64_cpu_register_types(void)
{
    size_t i;
    type_register_static(&aarch64_cpu_type_info);
    for (i = 0; i < ARRAY_SIZE(aarch64_cpus); ++i) {
        aarch64_cpu_register(&aarch64_cpus[i]);
    }
}
type_init(aarch64_cpu_register_types)
```

### System Emulation Entry Point

**Location**: `system/main.c` and `system/vl.c`

**Entry Flow**:
```
main(argc, argv)                    [system/main.c:45]
  -> qemu_init(argc, argv)          [system/vl.c:2748]
       -> qemu_init_subsystems()    [system/runstate.c:856]
       -> qemu_init_board()         [system/vl.c:2626]
            -> machine_run_board_init()
                 -> machine->init(machine)
```

## Current State

The fork is now:
- Buildable as `qemu-system-apple64e`
- Contains all original QEMU code unchanged
- Ready for surface reduction (Phase B)

## Known Issues

Currently the binary still exposes all generic ARM machines (83 total). This will be addressed in Phase B.

## Files Modified/Created

| File | Action |
|------|--------|
| `configs/targets/apple64e-softmmu.mak` | Created |
| `configs/devices/apple64e-softmmu/default.mak` | Created |

No original QEMU files were modified in Phase A.

## Next Phase

Phase B: QEMU Surface Reduction - disable all machines except apple-silicon-bringup.