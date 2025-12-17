# Machine Model Skeleton (apple-silicon-bringup)

This document specifies the C skeleton structure for the apple-silicon-bringup machine model. This will be implemented in `hw/apple/apple_machine.c` once QEMU is forked.

## File Structure

### apple_machine.h

```c
#ifndef HW_APPLE_MACHINE_H
#define HW_APPLE_MACHINE_H

#include "qemu/osdep.h"
#include "hw/boards.h"
#include "hw/arm/boot.h"

/*
 * apple-silicon-bringup Machine Model
 * Purpose-built Apple Silicon platform reconstruction for macOS arm64e
 */

#define TYPE_APPLE_MACHINE "apple-silicon-bringup"
#define APPLE_MACHINE(obj) OBJECT_CHECK(AppleMachineState, (obj), TYPE_APPLE_MACHINE)

/* Machine state structure */
typedef struct {
    MachineState parent_obj;
    
    /* Platform Boot Layer state */
    void *boot_layer;
    
    /* Platform identity */
    uint64_t platform_id;
    uint64_t board_id;
    uint64_t chip_id;
    
    /* CPU reference */
    ARMCPU *cpu;
    
    /* Memory regions */
    MemoryRegion *dram;
    MemoryRegion *mmio;
    
    /* Device tree */
    void *fdt;
    uint32_t fdt_size;
    
} AppleMachineState;

/* Machine initialization */
void apple_machine_init(MachineState *machine);

/* Platform Boot Layer interface */
void apple_platform_boot_layer_init(AppleMachineState *ams);
void apple_platform_boot_layer_synthesize(AppleMachineState *ams);

#endif /* HW_APPLE_MACHINE_H */
```

### apple_machine.c

```c
#include "qemu/osdep.h"
#include "hw/apple/apple_machine.h"
#include "hw/apple/platform_boot_layer.h"
#include "target/apple-arm64e/cpu.h"

/*
 * apple-silicon-bringup Machine Model
 * 
 * This is the ONLY machine model for Apple-on-Virt.
 * It reconstructs the Apple Silicon platform for macOS arm64e.
 * 
 * Architecture Philosophy:
 * - Platform reconstruction over generic emulation
 * - Single fixed configuration (no variants)
 * - Version-agnostic through platform fidelity
 * - No UEFI, no BIOS, no generic ARM compatibility
 */

/* Apple Silicon memory map constants */
#define APPLE_DRAM_BASE         0x0800000000ULL  /* 8GB base */
#define APPLE_DRAM_SIZE         0x0400000000ULL  /* 16GB */
#define APPLE_MMIO_BASE         0x1000000000ULL  /* MMIO region */
#define APPLE_MMIO_SIZE         0x1000000000ULL  /* MMIO size */

/* Platform identity (synthetic consistent values) */
#define APPLE_PLATFORM_ID       0x12345678
#define APPLE_BOARD_ID          0x87654321
#define APPLE_CHIP_ID           0xABCDEF1234567890ULL

/*
 * Machine initialization sequence
 * 
 * Order is critical:
 * 1. Platform Boot Layer synthesis
 * 2. CPU creation
 * 3. Device instantiation
 * 4. Device tree generation
 * 5. iBoot loading
 */
static void apple_machine_init(MachineState *machine)
{
    AppleMachineState *ams = APPLE_MACHINE(machine);
    
    /* Phase 1: Platform Boot Layer synthesis */
    apple_platform_boot_layer_init(ams);
    apple_platform_boot_layer_synthesize(ams);
    
    /* Phase 2: CPU creation */
    apple_machine_create_cpu(ams);
    
    /* Phase 3: Device instantiation */
    apple_machine_create_devices(ams);
    
    /* Phase 4: Device tree generation */
    apple_machine_generate_device_tree(ams);
    
    /* Phase 5: iBoot loading */
    apple_machine_load_iboot(ams);
    
    /* Initialization complete */
}

/*
 * CPU creation
 * Creates the apple-arm64e CPU model
 */
static void apple_machine_create_cpu(AppleMachineState *ams)
{
    MachineState *machine = MACHINE(ams);
    Object *cpuobj;
    
    /* Create apple-arm64e CPU (not generic ARM64) */
    cpuobj = object_new(TYPE_APPLE_ARM64E_CPU);
    
    /* Configure CPU with platform parameters */
    /* TODO: Set platform-specific CPU properties */
    
    /* Realize CPU */
    qdev_realize(DEVICE(cpuobj), NULL, &error_fatal);
    
    /* Store CPU reference */
    ams->cpu = ARM_CPU(cpuobj);
}

/*
 * Device instantiation
 * Creates Apple-compatible devices (not generic peripherals)
 */
static void apple_machine_create_devices(AppleMachineState *ams)
{
    /* Create Apple Interrupt Controller (AIC) - not GIC */
    apple_machine_create_aic(ams);
    
    /* Create Apple Timer - not generic ARM timer */
    apple_machine_create_timer(ams);
    
    /* Create Apple UART - not PL011 */
    apple_machine_create_uart(ams);
    
    /* Create Apple Storage - not virtio-blk */
    apple_machine_create_storage(ams);
}

/*
 * Device tree generation
 * Generates Apple-format device tree (not standard FDT)
 */
static void apple_machine_generate_device_tree(AppleMachineState *ams)
{
    /* Generate Apple-format device tree */
    /* This is NOT standard Linux device tree */
    /* Uses Apple-specific node structure and properties */
    
    /* TODO: Implement device tree generation */
}

/*
 * iBoot loading
 * Loads unmodified iBoot binary
 */
static void apple_machine_load_iboot(AppleMachineState *ams)
{
    /* Load iBoot binary from file */
    /* Place at correct address in DRAM */
    /* Set CPU entry point to iBoot */
    
    /* TODO: Implement iBoot loading */
}

/*
 * Machine class initialization
 * Defines machine properties and capabilities
 */
static void apple_machine_class_init(ObjectClass *oc, void *data)
{
    MachineClass *mc = MACHINE_CLASS(oc);
    
    /* Machine identity */
    mc->desc = "Apple Silicon arm64e Platform (apple-silicon-bringup)";
    mc->init = apple_machine_init;
    
    /* Fixed configuration */
    mc->max_cpus = 1;              /* Single CPU initially */
    mc->min_cpus = 1;
    mc->default_cpus = 1;
    mc->no_parallel = 1;           /* No legacy ports */
    mc->no_floppy = 1;
    mc->no_cdrom = 1;
    mc->no_sdcard = 1;
    
    /* Memory configuration */
    mc->default_ram_size = APPLE_DRAM_SIZE;
    mc->default_ram_id = "apple.dram";
    
    /* Boot configuration */
    mc->default_kernel_irqchip_split = true;
    
    /* Explicitly disable generic features */
    mc->no_user_config = 1;        /* No user configuration */
}

/*
 * Machine type definition
 */
static const TypeInfo apple_machine_info = {
    .name = TYPE_APPLE_MACHINE,
    .parent = TYPE_MACHINE,
    .instance_size = sizeof(AppleMachineState),
    .class_init = apple_machine_class_init,
};

/*
 * Machine registration
 */
static void apple_machine_register_types(void)
{
    type_register_static(&apple_machine_info);
}

type_init(apple_machine_register_types)
```

## Initialization Flow

```
apple_machine_init()
    |
    +-- apple_platform_boot_layer_init()
    |       Initialize Platform Boot Layer structures
    |
    +-- apple_platform_boot_layer_synthesize()
    |       Synthesize all platform state:
    |       - Memory map
    |       - Secure boot context
    |       - Platform identity
    |
    +-- apple_machine_create_cpu()
    |       Create apple-arm64e CPU
    |       Configure with platform parameters
    |       Realize CPU
    |
    +-- apple_machine_create_devices()
    |       Create AIC (not GIC)
    |       Create Apple Timer (not generic timer)
    |       Create Apple UART (not PL011)
    |       Create Apple Storage (not virtio)
    |
    +-- apple_machine_generate_device_tree()
    |       Generate Apple-format device tree
    |       Include all platform state
    |       Include all device nodes
    |
    +-- apple_machine_load_iboot()
            Load unmodified iBoot binary
            Set CPU entry point
            Transfer control
```

## Key Architectural Points

### 1. No Generic ARM Code

This machine does NOT use:
- virt machine as base
- GIC (Generic Interrupt Controller)
- Generic ARM timer
- Standard ARM peripherals
- SBSA assumptions

### 2. No UEFI/BIOS

This machine does NOT provide:
- UEFI boot services
- BIOS interrupts
- EFI protocols
- ACPI tables
- Standard firmware interfaces

### 3. No Configuration Options

This machine does NOT support:
- Multiple CPU models
- User-selectable hardware
- Board variants
- Memory size configuration (fixed)
- Device enable/disable options

### 4. Platform Boot Layer Integration

The Platform Boot Layer is:
- Initialized before CPU creation
- Completed before iBoot execution
- Not a runtime service provider
- Not modifiable after synthesis

### 5. Initialization Order Enforcement

The order is strict:
1. Platform Boot Layer (creates state)
2. CPU (uses platform state)
3. Devices (register in platform)
4. Device Tree (describes everything)
5. iBoot (uses all of above)

Violating this order will cause initialization failures.

## Explicit Non-Implementations

At skeleton stage, these are NOT implemented:

- Device functionality (Device Layer responsibility)
- Instruction execution (CPU Model responsibility)
- Boot chain execution (that comes after init)
- Debug features (added later)
- Performance optimization (correctness first)

## Integration Points

### With Platform Boot Layer

```c
/* Machine calls into Platform Boot Layer */
apple_platform_boot_layer_init(ams);
apple_platform_boot_layer_synthesize(ams);

/* Platform Boot Layer provides: */
// - Memory map definition
// - Secure boot context
// - Platform identity values
// - Device tree foundation
```

### With CPU Model

```c
/* Machine creates CPU */
cpuobj = object_new(TYPE_APPLE_ARM64E_CPU);

/* Machine configures CPU with platform state */
// - Platform ID
// - Initial register values
// - Entry point

/* CPU provides: */
// - Instruction execution
// - Exception handling
// - Register access
```

### With Device Layer

```c
/* Machine creates devices */
apple_machine_create_aic(ams);
apple_machine_create_timer(ams);
apple_machine_create_uart(ams);
apple_machine_create_storage(ams);

/* Devices provide: */
// - Hardware interfaces
// - Interrupt generation
// - Device tree node information
```

## Validation Criteria

The skeleton is correct when:

1. **Single Responsibility**: Each function does one thing.
2. **Clear Init Flow**: Initialization sequence is obvious.
3. **No Generic ARM**: No references to virt, GIC, or standard peripherals.
4. **No UEFI**: No firmware service interfaces.
5. **Platform Focus**: All code serves platform reconstruction.
6. **Documentation Match**: Code structure matches documented responsibilities.

## Next Steps

After skeleton creation:

1. Implement Platform Boot Layer functions.
2. Implement CPU creation with correct configuration.
3. Implement device instantiation.
4. Implement device tree generation.
5. Implement iBoot loading.
6. Test initialization sequence.
7. Verify platform state consistency.

This skeleton establishes structure. Implementation fills in functionality.
