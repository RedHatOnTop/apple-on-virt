/*
 * Apple Silicon Platform - Platform State Implementation
 * Phase 1.5: Platform Boot Layer Implementation
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This file implements the PlatformState initialization with:
 * - Complete memory map with documented addresses
 * - Synthetic platform identity
 * - Secure boot state synthesis
 */

#include "platform_state.h"
#include <string.h>

/*
 * Phase 1.5 Memory Map
 *
 * Complete memory map with all regions defined.
 * These regions are documented in platform_state.h and
 * are enforced by the machine model.
 */
static const AppleMemoryRegion memory_regions[] = {
    {
        .name = "Reserved",
        .base = APPLE_RESERVED_BASE,
        .size = APPLE_RESERVED_SIZE,
        .accessible = false,
        .writable = false,
        .executable = false,
    },
    {
        .name = "Secure",
        .base = APPLE_SECURE_BASE,
        .size = APPLE_SECURE_SIZE,
        .accessible = false,
        .writable = false,
        .executable = false,
    },
    {
        .name = "MMIO",
        .base = APPLE_MMIO_BASE,
        .size = APPLE_MMIO_SIZE,
        .accessible = true,
        .writable = true,
        .executable = false,
    },
    {
        .name = "DRAM",
        .base = APPLE_DRAM_BASE,
        .size = APPLE_DRAM_SIZE,
        .accessible = true,
        .writable = true,
        .executable = true,
    },
    {
        .name = "DeviceTree",
        .base = APPLE_DT_BASE,
        .size = APPLE_DT_SIZE,
        .accessible = true,
        .writable = false,
        .executable = false,
    },
    {
        .name = "BootArgs",
        .base = APPLE_BOOTARGS_BASE,
        .size = APPLE_BOOTARGS_SIZE,
        .accessible = true,
        .writable = false,
        .executable = false,
    },
    {
        .name = "iBoot",
        .base = APPLE_IBOOT_BASE,
        .size = APPLE_IBOOT_SIZE,
        .accessible = true,
        .writable = true,
        .executable = true,
    },
    {
        .name = "Kernel",
        .base = APPLE_KERNEL_BASE,
        .size = APPLE_KERNEL_SIZE,
        .accessible = true,
        .writable = true,
        .executable = true,
    },
};

#define MEMORY_REGION_COUNT (sizeof(memory_regions) / sizeof(memory_regions[0]))

/*
 * apple_platform_identity_init
 *
 * Initialize platform identity with stable synthetic values.
 * Values are consistent across runs and obviously synthetic.
 */
void apple_platform_identity_init(ApplePlatformIdentity *identity)
{
    if (!identity) {
        return;
    }

    identity->platform_id = APPLE_SYNTHETIC_PLATFORM_ID;
    identity->board_id = APPLE_SYNTHETIC_BOARD_ID;
    identity->chip_id = APPLE_SYNTHETIC_CHIP_ID;
}

/*
 * apple_memory_map_init
 *
 * Initialize memory map with all defined regions.
 * Regions are documented in platform_state.h
 */
void apple_memory_map_init(AppleMemoryMap *map)
{
    if (!map) {
        return;
    }

    memset(map, 0, sizeof(*map));

    for (unsigned int i = 0; i < MEMORY_REGION_COUNT; i++) {
        map->regions[i] = memory_regions[i];
    }
    map->region_count = MEMORY_REGION_COUNT;
}

/*
 * apple_secure_state_init
 *
 * Initialize secure state to indicate trusted platform.
 * This synthesizes the state that would exist after
 * successful hardware trust establishment.
 */
void apple_secure_state_init(AppleSecureState *secure)
{
    if (!secure) {
        return;
    }

    /*
     * Synthesize trusted state.
     * Boot components will see this and proceed normally.
     */
    secure->secure_boot_enabled = true;
    secure->trust_chain_valid = true;
    secure->platform_integrity_ok = true;
    secure->boot_mode = APPLE_BOOT_MODE_NORMAL;
}

/*
 * apple_platform_state_init
 *
 * Initialize the complete platform state structure.
 * This establishes all state needed for boot handoff.
 */
void apple_platform_state_init(ApplePlatformState *state)
{
    if (!state) {
        return;
    }

    memset(state, 0, sizeof(*state));

    /* Initialize sub-components */
    apple_platform_identity_init(&state->identity);
    apple_memory_map_init(&state->memory_map);
    apple_secure_state_init(&state->secure_state);

    /* Set Device Tree location */
    state->device_tree_addr = APPLE_DT_BASE;
    state->device_tree_size = 0;  /* Set when FDT is generated */

    /* Set iBoot entry point */
    state->iboot_entry_addr = APPLE_IBOOT_BASE;

    /* Mark as initialized */
    state->initialized = true;

    /*
     * Phase 1.5 State Initialization Complete
     *
     * Platform Boot Layer now has explicit ownership of:
     * - Platform identity (synthetic values)
     * - Memory map (all regions documented)
     * - Secure boot state (synthesized as trusted)
     * - Device Tree address (APPLE_DT_BASE)
     * - iBoot entry address (APPLE_IBOOT_BASE)
     *
     * Responsibility boundaries are clear:
     * - Machine: Creates actual memory regions
     * - CPU: Executes instructions
     * - Platform Boot Layer: Defines layout and state
     */
}
