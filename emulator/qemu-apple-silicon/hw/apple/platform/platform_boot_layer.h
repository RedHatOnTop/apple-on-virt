/*
 * Apple Silicon Platform - Platform Boot Layer Header
 * Phase 1.5: Platform Boot Layer Implementation
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * The Platform Boot Layer synthesizes the pre-boot environment
 * that Apple firmware normally provides.
 *
 * Phase 1.5: Complete implementation with:
 * - Explicit ownership of platform state
 * - Actual FDT generation
 * - Guest-accessible state
 *
 * Responsibility boundaries:
 * - Platform Boot Layer: Defines platform layout and state
 * - Machine Model: Creates actual memory regions
 * - CPU Model: Executes instructions
 */

#ifndef HW_APPLE_PLATFORM_BOOT_LAYER_H
#define HW_APPLE_PLATFORM_BOOT_LAYER_H

#include "platform_state.h"
#include "device_tree_skeleton.h"

/*
 * Platform Boot Layer
 *
 * Owns:
 * - Platform state (identity, memory map, secure state)
 * - Device tree generation
 * - Boot handoff addresses
 */
typedef struct ApplePlatformBootLayer {
    /* Platform state - explicit ownership */
    ApplePlatformState platform_state;
    
    /* Device tree - explicit ownership */
    AppleDeviceTreeSkeleton device_tree;
    
    /* Initialization state */
    bool initialized;
    bool fdt_ready;
} ApplePlatformBootLayer;

/*
 * Initialize the Platform Boot Layer.
 * Creates platform state and device tree structures.
 */
void apple_platform_boot_layer_init(ApplePlatformBootLayer *pbl);

/*
 * Generate FDT and prepare for guest placement.
 * Must be called after init, before boot handoff.
 */
int apple_platform_boot_layer_generate_fdt(ApplePlatformBootLayer *pbl);

/*
 * Get FDT blob for placement in guest memory.
 */
void *apple_platform_boot_layer_get_fdt(ApplePlatformBootLayer *pbl, 
                                        uint32_t *size);

/*
 * Get iBoot entry address.
 */
uint64_t apple_platform_boot_layer_get_iboot_entry(ApplePlatformBootLayer *pbl);

/*
 * Get Device Tree guest address.
 */
uint64_t apple_platform_boot_layer_get_dt_addr(ApplePlatformBootLayer *pbl);

#endif /* HW_APPLE_PLATFORM_BOOT_LAYER_H */
