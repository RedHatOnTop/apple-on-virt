/*
 * Apple Silicon Platform - Device Tree Generation Implementation
 * Phase 1.5: Platform Boot Layer Implementation
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Phase 1.5: Generates actual FDT blob for guest memory placement.
 * Uses libfdt to create a minimal device tree.
 */

#include "qemu/osdep.h"
#include "qemu/bswap.h"
#include "device_tree_skeleton.h"
#include "platform_state.h"
#include "sysemu/device_tree.h"
#include <string.h>
#include <libfdt.h>

/* FDT size - 64KB is plenty for our minimal tree */
#define FDT_MAX_SIZE  APPLE_DT_SIZE

/*
 * apple_dt_skeleton_init
 *
 * Initialize device tree structure tracking.
 */
void apple_dt_skeleton_init(AppleDeviceTreeSkeleton *dt)
{
    if (!dt) {
        return;
    }

    memset(dt, 0, sizeof(*dt));

    /* Root node - always exists */
    dt->root.name = "/";
    dt->root.exists = true;

    /* /chosen - boot arguments and such */
    dt->chosen.name = "/chosen";
    dt->chosen.exists = true;

    /* /memory - memory description */
    dt->memory.name = "/memory";
    dt->memory.exists = true;

    /* /cpus - CPU description */
    dt->cpus.name = "/cpus";
    dt->cpus.exists = true;

    dt->fdt = NULL;
    dt->fdt_size = 0;
    dt->fdt_addr = APPLE_DT_BASE;
    dt->initialized = true;
    dt->fdt_generated = false;
}

/*
 * apple_dt_generate_fdt
 *
 * Generate actual FDT blob with platform information.
 * Returns 0 on success, -1 on failure.
 */
int apple_dt_generate_fdt(AppleDeviceTreeSkeleton *dt,
                          ApplePlatformState *platform)
{
    void *fdt;
    int ret;
    char cpu_node[32];
    uint64_t mem_reg[2];

    if (!dt || !platform) {
        return -1;
    }

    /* Allocate FDT buffer */
    fdt = g_malloc0(FDT_MAX_SIZE);
    if (!fdt) {
        return -1;
    }

    /* Create empty FDT */
    ret = fdt_create_empty_tree(fdt, FDT_MAX_SIZE);
    if (ret < 0) {
        g_free(fdt);
        return -1;
    }

    /* Root node properties */
    qemu_fdt_setprop_string(fdt, "/", "compatible", "apple,apple-silicon-bringup");
    qemu_fdt_setprop_string(fdt, "/", "model", "Apple Silicon Bringup Platform");
    qemu_fdt_setprop_cell(fdt, "/", "#address-cells", 2);
    qemu_fdt_setprop_cell(fdt, "/", "#size-cells", 2);

    /* Platform identity in root node */
    qemu_fdt_setprop_cell(fdt, "/", "platform-id", platform->identity.platform_id);
    qemu_fdt_setprop_cell(fdt, "/", "board-id", platform->identity.board_id);
    qemu_fdt_setprop_cell(fdt, "/", "chip-id", platform->identity.chip_id);

    /* /chosen node */
    qemu_fdt_add_subnode(fdt, "/chosen");
    qemu_fdt_setprop_string(fdt, "/chosen", "bootargs", "debug=0x8 serial=3");
    
    /* Secure boot state in /chosen */
    qemu_fdt_setprop_cell(fdt, "/chosen", "secure-boot", 
                          platform->secure_state.secure_boot_enabled ? 1 : 0);
    qemu_fdt_setprop_cell(fdt, "/chosen", "boot-mode",
                          platform->secure_state.boot_mode);

    /* /memory node */
    qemu_fdt_add_subnode(fdt, "/memory");
    qemu_fdt_setprop_string(fdt, "/memory", "device_type", "memory");
    mem_reg[0] = cpu_to_be64(APPLE_DRAM_BASE);
    mem_reg[1] = cpu_to_be64(APPLE_DRAM_SIZE);
    qemu_fdt_setprop(fdt, "/memory", "reg", mem_reg, sizeof(mem_reg));

    /* /cpus node */
    qemu_fdt_add_subnode(fdt, "/cpus");
    qemu_fdt_setprop_cell(fdt, "/cpus", "#address-cells", 1);
    qemu_fdt_setprop_cell(fdt, "/cpus", "#size-cells", 0);

    /* /cpus/cpu@0 node */
    snprintf(cpu_node, sizeof(cpu_node), "/cpus/cpu@0");
    qemu_fdt_add_subnode(fdt, cpu_node);
    qemu_fdt_setprop_string(fdt, cpu_node, "compatible", "apple,arm64e");
    qemu_fdt_setprop_string(fdt, cpu_node, "device_type", "cpu");
    qemu_fdt_setprop_cell(fdt, cpu_node, "reg", 0);

    /* Pack the FDT to minimize size */
    ret = fdt_pack(fdt);
    if (ret < 0) {
        g_free(fdt);
        return -1;
    }

    /* Store FDT info */
    dt->fdt = fdt;
    dt->fdt_size = fdt_totalsize(fdt);
    dt->fdt_addr = APPLE_DT_BASE;
    dt->fdt_generated = true;

    return 0;
}

/*
 * apple_dt_get_fdt
 *
 * Get FDT blob for placement in guest memory.
 * Returns pointer to FDT and sets size.
 */
void *apple_dt_get_fdt(AppleDeviceTreeSkeleton *dt, uint32_t *size)
{
    if (!dt || !dt->fdt_generated) {
        if (size) {
            *size = 0;
        }
        return NULL;
    }

    if (size) {
        *size = dt->fdt_size;
    }
    return dt->fdt;
}
