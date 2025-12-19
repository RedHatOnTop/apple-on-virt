/*
 * Apple Silicon Platform - Device Tree Generation Header
 * Phase 1.5: Platform Boot Layer Implementation
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This file defines the Device Tree generation interface.
 * Phase 1.5 generates an actual FDT blob with:
 * - / (root) with model and compatible
 * - /chosen with boot arguments
 * - /memory with DRAM description
 * - /cpus with CPU description
 *
 * The FDT is placed in guest memory at APPLE_DT_BASE.
 */

#ifndef HW_APPLE_DEVICE_TREE_SKELETON_H
#define HW_APPLE_DEVICE_TREE_SKELETON_H

#include "qemu/osdep.h"
#include <stdint.h>
#include <stdbool.h>

/* Forward declaration */
struct ApplePlatformState;

/*
 * Device Tree Node Tracking
 *
 * Tracks which nodes exist in the generated device tree.
 */
typedef struct AppleDeviceTreeNode {
    const char *name;       /* Node name */
    bool exists;            /* Node existence flag */
} AppleDeviceTreeNode;

/*
 * Device Tree State
 *
 * Tracks the device tree structure and generation state.
 */
typedef struct AppleDeviceTreeSkeleton {
    AppleDeviceTreeNode root;       /* / */
    AppleDeviceTreeNode chosen;     /* /chosen */
    AppleDeviceTreeNode memory;     /* /memory */
    AppleDeviceTreeNode cpus;       /* /cpus */
    
    /* FDT blob storage */
    void *fdt;                      /* Pointer to FDT blob */
    uint32_t fdt_size;              /* Size of FDT blob */
    uint64_t fdt_addr;              /* Guest address of FDT */
    
    bool initialized;
    bool fdt_generated;
} AppleDeviceTreeSkeleton;

/*
 * Function prototypes
 */

/* Initialize device tree structure */
void apple_dt_skeleton_init(AppleDeviceTreeSkeleton *dt);

/* Generate actual FDT blob (Phase 1.5) */
int apple_dt_generate_fdt(AppleDeviceTreeSkeleton *dt,
                          struct ApplePlatformState *platform);

/* Get FDT blob for placement in guest memory */
void *apple_dt_get_fdt(AppleDeviceTreeSkeleton *dt, uint32_t *size);

#endif /* HW_APPLE_DEVICE_TREE_SKELETON_H */
