/*
 * Apple Silicon Platform - Platform State Header
 * Phase 1.5: Platform Boot Layer Implementation
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This file defines the PlatformState structure containing:
 * - Platform identity (synthetic but consistent)
 * - Memory map with defined regions
 * - Secure state flags
 * - Boot addresses for iBoot handoff
 *
 * Phase 1.5 provides:
 * - Complete memory map with documented addresses
 * - Platform state accessible to guest
 * - Foundation for iBoot loading
 */

#ifndef HW_APPLE_PLATFORM_STATE_H
#define HW_APPLE_PLATFORM_STATE_H

#include "qemu/osdep.h"
#include <stdint.h>
#include <stdbool.h>

/*
 * =============================================================================
 * MEMORY MAP ADDRESSES (Phase 1.5)
 * =============================================================================
 *
 * These addresses define the Apple Silicon-like memory layout.
 * All addresses are documented here as the single source of truth.
 *
 * Memory Layout:
 *
 * 0x0000_0000_0000_0000 - 0x0000_0000_0FFF_FFFF : Reserved (256MB)
 * 0x0000_0000_1000_0000 - 0x0000_0000_1FFF_FFFF : Secure Region (256MB)
 * 0x0000_0000_2000_0000 - 0x0000_0000_3FFF_FFFF : MMIO Region (512MB)
 * 0x0000_0008_0000_0000 - 0x0000_0008_0FFF_FFFF : DRAM (256MB)
 *
 * DRAM Layout:
 *
 * 0x8_0000_0000 - 0x8_0000_FFFF : Device Tree / ADT (64KB)
 * 0x8_0001_0000 - 0x8_000F_FFFF : Reserved for boot args (960KB)
 * 0x8_0010_0000 - 0x8_00FF_FFFF : iBoot load region (15MB)
 * 0x8_0100_0000 - 0x8_01FF_FFFF : Kernel load region (16MB)
 * 0x8_0200_0000 - 0x8_0FFF_FFFF : General DRAM (remaining)
 */

/* Base memory regions */
#define APPLE_RESERVED_BASE     0x00000000ULL
#define APPLE_RESERVED_SIZE     0x10000000ULL   /* 256MB */

#define APPLE_SECURE_BASE       0x10000000ULL
#define APPLE_SECURE_SIZE       0x10000000ULL   /* 256MB */

#define APPLE_MMIO_BASE         0x20000000ULL
#define APPLE_MMIO_SIZE         0x20000000ULL   /* 512MB */

/* UART0 (debug console) */
#define APPLE_UART0_BASE        0x235200000ULL
#define APPLE_UART0_SIZE        0x00004000ULL   /* 16KB */

/* Apple Interrupt Controller (AIC) */
#define APPLE_AIC_BASE          0x23b100000ULL
#define APPLE_AIC_SIZE          0x0000C000ULL   /* 48KB */

#define APPLE_DRAM_BASE         0x800000000ULL
#define APPLE_DRAM_SIZE         0x10000000ULL   /* 256MB */

/* DRAM sub-regions (all relative to APPLE_DRAM_BASE) */
#define APPLE_DT_OFFSET         0x00000000ULL   /* Device Tree offset */
#define APPLE_DT_SIZE           0x00010000ULL   /* 64KB for Device Tree */

#define APPLE_BOOTARGS_OFFSET   0x00010000ULL   /* Boot arguments offset */
#define APPLE_BOOTARGS_SIZE     0x000F0000ULL   /* 960KB for boot args */

#define APPLE_IBOOT_OFFSET      0x00100000ULL   /* iBoot load offset */
#define APPLE_IBOOT_SIZE        0x00F00000ULL   /* 15MB for iBoot */

#define APPLE_KERNEL_OFFSET     0x01000000ULL   /* Kernel load offset */
#define APPLE_KERNEL_SIZE       0x01000000ULL   /* 16MB for kernel */

/* Absolute addresses (computed from base + offset) */
#define APPLE_DT_BASE           (APPLE_DRAM_BASE + APPLE_DT_OFFSET)
#define APPLE_BOOTARGS_BASE     (APPLE_DRAM_BASE + APPLE_BOOTARGS_OFFSET)
#define APPLE_IBOOT_BASE        (APPLE_DRAM_BASE + APPLE_IBOOT_OFFSET)
#define APPLE_KERNEL_BASE       (APPLE_DRAM_BASE + APPLE_KERNEL_OFFSET)

/*
 * Platform Identity
 *
 * These values are synthetic but consistent across runs.
 * They do NOT match real hardware but are recognizable as synthetic.
 */
typedef struct ApplePlatformIdentity {
    uint32_t platform_id;   /* Synthetic platform identifier */
    uint32_t board_id;      /* Synthetic board identifier */
    uint32_t chip_id;       /* Synthetic chip identifier */
} ApplePlatformIdentity;

/* Synthetic identity values - obviously fake but stable */
#define APPLE_SYNTHETIC_PLATFORM_ID  0xA0A0A0A0
#define APPLE_SYNTHETIC_BOARD_ID     0xB0B0B0B0
#define APPLE_SYNTHETIC_CHIP_ID      0xC0C0C0C0

/*
 * Memory Region Definition
 *
 * Defines named memory regions with accessibility flags.
 */
typedef struct AppleMemoryRegion {
    const char *name;       /* Region name (e.g., "DRAM", "Reserved") */
    uint64_t base;          /* Base address */
    uint64_t size;          /* Region size */
    bool accessible;        /* Guest can access */
    bool writable;          /* Guest can write */
    bool executable;        /* Guest can execute */
} AppleMemoryRegion;

/*
 * Memory Map
 *
 * Maximum 16 regions for complete memory map.
 */
#define APPLE_MAX_MEMORY_REGIONS 16

typedef struct AppleMemoryMap {
    AppleMemoryRegion regions[APPLE_MAX_MEMORY_REGIONS];
    unsigned int region_count;
} AppleMemoryMap;

/*
 * Secure State Flags
 *
 * Represents secure boot state that would exist after
 * successful hardware trust establishment.
 */
typedef struct AppleSecureState {
    bool secure_boot_enabled;       /* Secure boot is active */
    bool trust_chain_valid;         /* Boot chain verified */
    bool platform_integrity_ok;     /* Platform integrity valid */
    uint32_t boot_mode;             /* Boot mode indicator */
} AppleSecureState;

/* Boot mode values */
#define APPLE_BOOT_MODE_NORMAL      0x00
#define APPLE_BOOT_MODE_RECOVERY    0x01
#define APPLE_BOOT_MODE_DFU         0x02

/*
 * PlatformState
 *
 * The main platform state structure created by the Platform Boot Layer.
 * Phase 1.5: Contains complete state for iBoot handoff.
 *
 * This structure owns:
 * - Platform identity (explicit ownership)
 * - Memory map (explicit ownership)
 * - Secure boot state (explicit ownership)
 * - Device Tree address (for guest access)
 */
typedef struct ApplePlatformState {
    /* Platform identity - synthetic but consistent */
    ApplePlatformIdentity identity;

    /* Memory map with all regions */
    AppleMemoryMap memory_map;

    /* Secure boot state */
    AppleSecureState secure_state;

    /* Device Tree guest address (where FDT is placed) */
    uint64_t device_tree_addr;
    uint32_t device_tree_size;

    /* iBoot entry point (for Phase 2) */
    uint64_t iboot_entry_addr;

    /* Initialized flag */
    bool initialized;
} ApplePlatformState;

/*
 * Function prototypes
 *
 * Phase 1.5: Complete initialization functions.
 */

/* Initialize platform state structure */
void apple_platform_state_init(ApplePlatformState *state);

/* Initialize platform identity with stable synthetic values */
void apple_platform_identity_init(ApplePlatformIdentity *identity);

/* Initialize memory map with all regions */
void apple_memory_map_init(AppleMemoryMap *map);

/* Initialize secure state (synthesized as trusted) */
void apple_secure_state_init(AppleSecureState *secure);

#endif /* HW_APPLE_PLATFORM_STATE_H */
