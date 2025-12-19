/*
 * Apple Silicon Platform - Machine Implementation
 * Phase 2: iBoot Loading and Execution
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This is the ONLY machine model for Apple-on-Virt.
 *
 * Phase 2 adds:
 * - iBoot binary loading via -kernel option
 * - Execution handoff to iBoot
 * - Platform context exposure to iBoot
 *
 * Responsibility boundaries:
 * - Platform Boot Layer: Defines layout and state
 * - Machine Model: Creates memory regions, loads iBoot (this code)
 * - CPU Model: Executes instructions
 */

#include "qemu/osdep.h"
#include "qemu/units.h"
#include "qemu/error-report.h"
#include "qapi/error.h"
#include "hw/boards.h"
#include "hw/qdev-properties.h"
#include "hw/loader.h"
#include "exec/address-spaces.h"
#include "sysemu/sysemu.h"
#include "target/arm/cpu.h"
#include "target/arm/cpu-qom.h"

#include "apple_machine.h"
#include "iboot_loader.h"
#include "platform/platform_boot_layer.h"
#include "platform/platform_state.h"

/*
 * Idle Loop (Fallback)
 *
 * Used when no iBoot binary is provided.
 * Simple WFI (Wait For Interrupt) loop.
 *
 * Assembly:
 *   loop:
 *     wfi
 *     b loop
 */
static const uint32_t idle_loop[] = {
    0xd503207f,  /* wfi */
    0x17ffffff,  /* b -4 (loop back to wfi) */
};

/*
 * Machine initialization
 *
 * Phase 2 initialization flow:
 * 1. Initialize Platform Boot Layer (defines state)
 * 2. Create DRAM memory region
 * 3. Generate and place FDT in guest memory
 * 4. Create CPU
 * 5. Load iBoot (or idle loop if not provided)
 * 6. Set CPU entry point and initial state
 */
static void apple_machine_init(MachineState *machine)
{
    AppleMachineState *ams = APPLE_MACHINE(machine);
    MemoryRegion *sysmem = get_system_memory();
    Object *cpuobj;
    ARMCPU *cpu;
    void *fdt;
    uint32_t fdt_size;
    int64_t dt_size;
    IBootLoadInfo iboot_info = {0};
    bool iboot_loaded = false;

    /*
     * Step 1: Platform Boot Layer Initialization
     *
     * This establishes:
     * - Platform identity (synthetic values)
     * - Memory map (all regions documented in platform_state.h)
     * - Secure boot state (synthesized as trusted)
     */
    apple_platform_boot_layer_init(&ams->platform_boot_layer);

    /*
     * Step 2: Create DRAM
     *
     * Note: Use memory_region_init_ram_nomigrate because MachineState is
     * not a DeviceState, and memory_region_init_ram requires a DeviceState
     * owner for migration registration.
     *
     * Uses addresses from platform_state.h (single source of truth):
     * - APPLE_DRAM_BASE = 0x40000000
     * - APPLE_DRAM_SIZE = 1GB
     */
    memory_region_init_ram_nomigrate(&ams->ram, OBJECT(machine), "apple.ram",
                                     APPLE_DRAM_SIZE, &error_fatal);
    memory_region_add_subregion(sysmem, APPLE_DRAM_BASE, &ams->ram);

    /*
     * Step 3: Place Device Tree blob
     *
     * Phase 5a: The project uses Apple Device Tree (ADT) binaries.
     * We treat the blob as opaque bytes and only place it in guest DRAM.
     *
     * - If -dtb is provided, load that file verbatim at APPLE_DT_BASE.
     * - Otherwise, fall back to the existing synthetic FDT generator.
     */
    dt_size = -1;
    if (machine->dtb) {
        error_report("Loading DT blob (-dtb) from: %s", machine->dtb);
        dt_size = load_image_targphys(machine->dtb, APPLE_DT_BASE, APPLE_DT_SIZE);
        if (dt_size <= 0) {
            error_report("Failed to load DT blob '%s'", machine->dtb);
        }
    }

    if (dt_size <= 0) {
        if (apple_platform_boot_layer_generate_fdt(&ams->platform_boot_layer) == 0) {
            fdt = apple_platform_boot_layer_get_fdt(&ams->platform_boot_layer, &fdt_size);
            if (fdt && fdt_size > 0) {
                rom_add_blob_fixed("device-tree", fdt, fdt_size, APPLE_DT_BASE);
            }
        }
    }

    /*
     * Step 4: Create CPU
     *
     * Uses cortex-a76 as base (closest to arm64e capabilities).
     */
    cpuobj = object_new(machine->cpu_type);
    if (!cpuobj) {
        error_report("Failed to create CPU object");
        return;
    }
    cpu = ARM_CPU(cpuobj);

    /* Realize the CPU */
    object_property_set_bool(cpuobj, "realized", true, &error_fatal);

    /* Store CPU reference */
    ams->cpu = CPU(cpu);

    /*
     * Step 5: Load iBoot or fallback to idle loop
     *
     * Phase 2: Load iBoot binary via -kernel option.
     * If no binary provided, use idle loop for testing.
     */
    if (machine->kernel_filename) {
        /*
         * iBoot Loading (Phase 2)
         *
         * Load iBoot binary at APPLE_IBOOT_BASE (0x40100000).
         * iBoot is treated as opaque - no parsing, no patching.
         */
        error_report("Loading iBoot from: %s", machine->kernel_filename);
        if (apple_iboot_load(machine->kernel_filename, &iboot_info) == 0) {
            iboot_loaded = true;
            error_report("iBoot loaded at 0x%llx (%" PRIu64 " bytes)",
                       (unsigned long long)iboot_info.load_addr,
                       iboot_info.size);
        } else {
            error_report("Failed to load iBoot from '%s'",
                        machine->kernel_filename);
            error_report("Falling back to idle loop");
        }
    }

    if (!iboot_loaded) {
        /*
         * No iBoot provided - use idle loop for testing.
         */
        rom_add_blob_fixed("idle-loop", idle_loop, sizeof(idle_loop),
                           APPLE_IBOOT_BASE);
        error_report("No iBoot provided, using idle loop at 0x%llx",
                   (unsigned long long)APPLE_IBOOT_BASE);
    }

    /*
     * Step 6: Set CPU entry point and initial state
     *
     * Phase 2: Execution Handoff
     *
     * CPU State for iBoot entry:
     * - PC = APPLE_IBOOT_BASE (0x40100000)
     * - SP = Top of DRAM (stack grows down)
     * - EL = EL1 (default for QEMU ARM)
     * - X0 = Device Tree address (convention)
     */
    cpu->env.pc = APPLE_IBOOT_BASE;
    
    /*
     * Set stack pointer to top of DRAM minus some space.
     * Stack grows downward.
     */
    cpu->env.xregs[31] = APPLE_DRAM_BASE + APPLE_DRAM_SIZE - 0x1000;
    
    /*
     * Pass Device Tree address in X0.
     * This is a common convention for ARM boot.
     */
    cpu->env.xregs[0] = APPLE_DT_BASE;
    
    error_report("=== Phase 2: Machine Init Complete ===");
    error_report("Entry Point (PC): 0x%llx", (unsigned long long)cpu->env.pc);
    error_report("Stack Pointer (SP): 0x%llx", (unsigned long long)cpu->env.xregs[31]);
    error_report("Device Tree (X0): 0x%llx", (unsigned long long)cpu->env.xregs[0]);
    if (iboot_loaded) {
        error_report("iBoot binary loaded - execution will begin at entry point");
    } else {
        error_report("Idle loop loaded - CPU will WFI until interrupt");
    }
}

/*
 * Machine class initialization
 *
 * Defines machine properties and capabilities.
 */
static void apple_machine_class_init(ObjectClass *oc, void *data)
{
    MachineClass *mc = MACHINE_CLASS(oc);

    /* Machine identity */
    mc->desc = "Apple Silicon arm64e Platform (apple-silicon-bringup)";
    mc->init = apple_machine_init;

    /*
     * Default CPU type
     *
     * Phase 1.5: Use cortex-a76 as it has:
     * - PAC instruction support (arm64e requirement)
     * - ARMv8.2+ features
     * - Better arm64e compatibility than cortex-a72
     *
     * Future: Custom apple-arm64e CPU type
     */
    mc->default_cpu_type = ARM_CPU_TYPE_NAME("cortex-a76");

    /* Fixed configuration - single CPU */
    mc->max_cpus = 1;
    mc->min_cpus = 1;
    mc->default_cpus = 1;

    /* Phase 1.5 RAM size - use documented value */
    mc->default_ram_size = APPLE_DRAM_SIZE;
    mc->default_ram_id = "apple.ram";

    /* Disable legacy features not applicable to Apple Silicon */
    mc->no_parallel = true;
    mc->no_floppy = true;
    mc->no_cdrom = true;
    mc->no_sdcard = true;
    
    /* Disable serial by default (no UART device yet) */
    mc->no_serial = true;
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
 *
 * This registers apple-silicon-bringup as the ONLY machine.
 * Called during QEMU initialization via type_init().
 */
static void apple_machine_register_types(void)
{
    type_register_static(&apple_machine_info);
}

type_init(apple_machine_register_types)
