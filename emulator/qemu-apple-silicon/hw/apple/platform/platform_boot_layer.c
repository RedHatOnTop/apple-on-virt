/*
 * Apple Silicon Platform - Platform Boot Layer Implementation
 * Phase 1.5: Platform Boot Layer Implementation
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Phase 1.5 implements complete Platform Boot Layer that:
 * - Creates PlatformState with explicit ownership
 * - Initializes complete memory map
 * - Generates actual FDT blob
 * - Provides guest-accessible state
 *
 * Responsibility Boundaries:
 * - Platform Boot Layer: Defines layout and state (this code)
 * - Machine Model: Creates actual QEMU memory regions
 * - CPU Model: Executes instructions
 */

#include "platform_boot_layer.h"
#include <string.h>

/*
 * apple_platform_boot_layer_init
 *
 * Initialize the Platform Boot Layer.
 * This establishes platform state with explicit ownership.
 */
void apple_platform_boot_layer_init(ApplePlatformBootLayer *pbl)
{
    if (!pbl) {
        return;
    }

    memset(pbl, 0, sizeof(*pbl));

    /*
     * Initialize Platform State
     * - Platform identity (synthetic values)
     * - Memory map (all regions documented)
     * - Secure boot state (synthesized as trusted)
     */
    apple_platform_state_init(&pbl->platform_state);

    /*
     * Initialize Device Tree structure
     * FDT blob will be generated in separate step
     */
    apple_dt_skeleton_init(&pbl->device_tree);

    pbl->initialized = true;
    pbl->fdt_ready = false;

    /*
     * Phase 1.5 Initialization Complete
     *
     * Platform Boot Layer now has explicit ownership of:
     * - Platform identity
     * - Memory map with documented addresses
     * - Secure boot state
     * - Device tree structure
     *
     * FDT generation is deferred to allow machine setup first.
     */
}

/*
 * apple_platform_boot_layer_generate_fdt
 *
 * Generate FDT blob with platform information.
 * Must be called after init, before boot handoff.
 */
int apple_platform_boot_layer_generate_fdt(ApplePlatformBootLayer *pbl)
{
    int ret;

    if (!pbl || !pbl->initialized) {
        return -1;
    }

    ret = apple_dt_generate_fdt(&pbl->device_tree, &pbl->platform_state);
    if (ret == 0) {
        pbl->fdt_ready = true;
        pbl->platform_state.device_tree_size = pbl->device_tree.fdt_size;
    }

    return ret;
}

/*
 * apple_platform_boot_layer_get_fdt
 *
 * Get FDT blob for placement in guest memory.
 */
void *apple_platform_boot_layer_get_fdt(ApplePlatformBootLayer *pbl, 
                                        uint32_t *size)
{
    if (!pbl || !pbl->fdt_ready) {
        if (size) {
            *size = 0;
        }
        return NULL;
    }

    return apple_dt_get_fdt(&pbl->device_tree, size);
}

/*
 * apple_platform_boot_layer_get_iboot_entry
 *
 * Get iBoot entry address for Phase 2.
 */
uint64_t apple_platform_boot_layer_get_iboot_entry(ApplePlatformBootLayer *pbl)
{
    if (!pbl || !pbl->initialized) {
        return 0;
    }
    return pbl->platform_state.iboot_entry_addr;
}

/*
 * apple_platform_boot_layer_get_dt_addr
 *
 * Get Device Tree guest address.
 */
uint64_t apple_platform_boot_layer_get_dt_addr(ApplePlatformBootLayer *pbl)
{
    if (!pbl || !pbl->initialized) {
        return 0;
    }
    return pbl->platform_state.device_tree_addr;
}
