/*
 * Apple Silicon Platform - Machine Header
 * Phase E: Platform Boot Layer Skeleton
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This is the ONLY machine model for Apple-on-Virt.
 * It reconstructs the Apple Silicon platform for macOS arm64e.
 *
 * Phase E Scope:
 * - Minimal machine skeleton that initializes without crashing
 * - Single CPU instantiation
 * - Platform Boot Layer structures (existence only)
 * - No firmware loading
 * - No boot behavior
 */

#ifndef HW_APPLE_MACHINE_H
#define HW_APPLE_MACHINE_H

#include "qemu/osdep.h"
#include "hw/boards.h"
#include "qom/object.h"
#include "platform/platform_boot_layer.h"

/*
 * Machine type definitions
 *
 * TYPE_APPLE_MACHINE: The QOM type name for the machine
 * APPLE_MACHINE(): Type-safe cast macro
 *
 * Note: QEMU requires machine type names to end with "-machine"
 */
#define TYPE_APPLE_MACHINE "apple-silicon-bringup-machine"
OBJECT_DECLARE_SIMPLE_TYPE(AppleMachineState, APPLE_MACHINE)

/*
 * AppleMachineState
 *
 * Phase E state:
 * - parent_obj: Required MachineState parent
 * - cpu: Reference to the single CPU
 * - ram: Memory region for RAM
 * - platform_boot_layer: Platform Boot Layer (Phase E)
 *
 * Future phases will add:
 * - Apple-specific devices
 * - More complex memory layout
 */
struct AppleMachineState {
    /*< private >*/
    MachineState parent_obj;

    /*< public >*/
    /* CPU reference - single CPU */
    CPUState *cpu;

    /* RAM region */
    MemoryRegion ram;

    /* UART0 stub MMIO region (Phase 5b) */
    MemoryRegion uart0;

    /* AIC stub MMIO region (Phase 5d) */
    MemoryRegion aic;
    uint64_t aic_regs[APPLE_AIC_SIZE / sizeof(uint64_t)];

    /* Platform Boot Layer (Phase E) */
    ApplePlatformBootLayer platform_boot_layer;
};

#endif /* HW_APPLE_MACHINE_H */
