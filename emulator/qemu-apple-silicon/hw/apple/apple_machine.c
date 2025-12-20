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
#include "qemu/log.h"
#include "exec/cpu-common.h"
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
 * Phase 5b: Minimal UART0 stub
 *
 * Contract:
 * - MMIO exists at APPLE_UART0_BASE
 * - Writes are accepted and emit bytes to host stderr
 * - Reads return a fixed non-zero value (dummy)
 */
static uint64_t apple_uart0_stub_read(void *opaque, hwaddr offset, unsigned size)
{
    (void)opaque;
    (void)offset;

    /* Dummy "ready" value; sized by access width. */
    switch (size) {
    case 1: return 0xFF;
    case 2: return 0xFFFF;
    case 4: return 0xFFFFFFFFULL;
    default: return 0xFFFFFFFFFFFFFFFFULL;
    }
}

static void apple_uart0_stub_write(void *opaque, hwaddr offset, uint64_t value,
                                  unsigned size)
{
    (void)opaque;
    (void)offset;
    (void)size;

    /* Treat the low byte of any write as a character. */
    fputc((int)(value & 0xFF), stderr);
    fflush(stderr);
}

static const MemoryRegionOps apple_uart0_stub_ops = {
    .read = apple_uart0_stub_read,
    .write = apple_uart0_stub_write,
    .endianness = DEVICE_NATIVE_ENDIAN,
    .valid = {
        .min_access_size = 1,
        .max_access_size = 8,
    },
};

/*
 * Phase 5d: Minimal AIC stub
 *
 * Contract:
 * - MMIO exists at APPLE_AIC_BASE
 * - Reads/writes do not crash
 * - Registers are writable (last-write-wins)
 * - No interrupt delivery is implemented
 */
static uint64_t apple_aic_stub_read(void *opaque, hwaddr offset, unsigned size)
{
    AppleMachineState *ams = opaque;
    uint64_t idx = (offset & ~(hwaddr)0x7) >> 3;
    uint64_t shift = (offset & 0x7) * 8;
    uint64_t mask = (size >= 8) ? ~0ULL : ((1ULL << (size * 8)) - 1);
    uint64_t val = 0;

    if (idx < (APPLE_AIC_SIZE / sizeof(uint64_t))) {
        val = (ams->aic_regs[idx] >> shift) & mask;
    }

    if (qemu_loglevel_mask(LOG_GUEST_ERROR)) {
        qemu_log_mask(LOG_GUEST_ERROR,
                      "AIC R off=0x%llx size=%u -> 0x%llx\n",
                      (unsigned long long)offset, size,
                      (unsigned long long)val);
    }

    return val;
}

static void apple_aic_stub_write(void *opaque, hwaddr offset, uint64_t value,
                                unsigned size)
{
    AppleMachineState *ams = opaque;
    uint64_t idx = (offset & ~(hwaddr)0x7) >> 3;
    uint64_t shift = (offset & 0x7) * 8;
    uint64_t mask = (size >= 8) ? ~0ULL : ((1ULL << (size * 8)) - 1);

    if (idx < (APPLE_AIC_SIZE / sizeof(uint64_t))) {
        uint64_t cur = ams->aic_regs[idx];
        cur &= ~(mask << shift);
        cur |= (value & mask) << shift;
        ams->aic_regs[idx] = cur;
    }

    if (qemu_loglevel_mask(LOG_GUEST_ERROR)) {
        qemu_log_mask(LOG_GUEST_ERROR,
                      "AIC W off=0x%llx size=%u val=0x%llx\n",
                      (unsigned long long)offset, size,
                      (unsigned long long)value);
    }
}

static const MemoryRegionOps apple_aic_stub_ops = {
    .read = apple_aic_stub_read,
    .write = apple_aic_stub_write,
    .endianness = DEVICE_NATIVE_ENDIAN,
    .valid = {
        .min_access_size = 1,
        .max_access_size = 8,
    },
};

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
 * Phase 5f: Minimal ADT "chosen" verifier (structure is treated as opaque).
 *
 * This only checks that the DT blob contains a top-level child with name
 * "chosen" using the same structural assumptions as the Phase 4 surrogate.
 */
static bool apple_adt_has_chosen_child(const uint8_t *dt, size_t dt_size)
{
    uint32_t prop_count, child_count;
    size_t off;

    if (!dt || dt_size < 12) {
        return false;
    }

    prop_count = *(const uint32_t *)(dt + 0);
    child_count = *(const uint32_t *)(dt + 4);

    off = 8;
    for (uint32_t i = 0; i < prop_count; i++) {
        if (off + 36 > dt_size) {
            return false;
        }
        uint32_t len = *(const uint32_t *)(dt + off + 32) & 0x7fffffffU;
        off = (off + 36 + len + 3) & ~(size_t)3;
        if (off > dt_size) {
            return false;
        }
    }

    for (uint32_t c = 0; c < child_count; c++) {
        if (off + 8 + 36 + 7 > dt_size) {
            return false;
        }

        uint32_t c_prop_count = *(const uint32_t *)(dt + off + 0);
        (void)c_prop_count;

        /* First child property is expected to be name; value at +8+36. */
        const char *nm = (const char *)(dt + off + 8 + 36);
        if (!memcmp(nm, "chosen", 6)) {
            return true;
        }

        /* Skip child node (properties only; minimal ADT has no grandchildren). */
        size_t child_off = off + 8;
        for (uint32_t i = 0; i < c_prop_count; i++) {
            if (child_off + 36 > dt_size) {
                return false;
            }
            uint32_t len = *(const uint32_t *)(dt + child_off + 32) & 0x7fffffffU;
            child_off = (child_off + 36 + len + 3) & ~(size_t)3;
            if (child_off > dt_size) {
                return false;
            }
        }

        off = child_off;
    }

    return false;
}

static void apple_phase5f_verify_dtb(const char *dtb_path)
{
    FILE *f;
    uint8_t buf[APPLE_DT_SIZE];
    size_t n;

    if (!dtb_path) {
        return;
    }

    f = fopen(dtb_path, "rb");
    if (!f) {
        error_report("Phase5f: unable to open DT blob for verification: %s", dtb_path);
        return;
    }

    n = fread(buf, 1, sizeof(buf), f);
    fclose(f);

    if (apple_adt_has_chosen_child(buf, n)) {
        error_report("Phase5f: /chosen exists in DT blob (ADT)");
    } else {
        error_report("Phase5f: /chosen NOT found in DT blob (ADT)");
    }
}

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

    /* Phase 5f: verify /chosen exists in the provided ADT blob (no mutation). */
    if (machine->dtb) {
        apple_phase5f_verify_dtb(machine->dtb);
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
     * Phase 5f: Boot-args buffer must exist and be mapped.
     * We pre-zero a small prefix at the fixed BootArgs base.
     */
    {
        uint8_t zero[0x1000] = {0};
        cpu_physical_memory_write(APPLE_BOOTARGS_BASE, zero, sizeof(zero));
        error_report("Phase5f: boot_args buffer initialized at 0x%llx",
                     (unsigned long long)APPLE_BOOTARGS_BASE);
    }

    /*
     * Phase 5b: UART0 stub mapping
     *
     * This adds only a single MMIO subregion; DRAM mapping is unchanged.
     */
    memory_region_init_io(&ams->uart0, OBJECT(machine), &apple_uart0_stub_ops,
                          NULL, "apple.uart0", APPLE_UART0_SIZE);
    memory_region_add_subregion(sysmem, APPLE_UART0_BASE, &ams->uart0);

    /*
     * Phase 5d: AIC stub mapping (existence only, no real interrupts)
     */
    memset(ams->aic_regs, 0, sizeof(ams->aic_regs));
    memory_region_init_io(&ams->aic, OBJECT(machine), &apple_aic_stub_ops,
                          ams, "apple.aic", APPLE_AIC_SIZE);
    memory_region_add_subregion(sysmem, APPLE_AIC_BASE, &ams->aic);

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
     * Phase 5f: Optional "kernel" blob load via -initrd
     *
     * This is a bring-up convenience to demonstrate kernel entry attempt.
     * It loads the initrd raw at APPLE_KERNEL_BASE (no parsing).
     */
    if (machine->initrd_filename) {
        int64_t ksize;
        error_report("Phase5f: Loading kernel blob (-initrd) from: %s", machine->initrd_filename);
        ksize = load_image_targphys(machine->initrd_filename, APPLE_KERNEL_BASE, APPLE_KERNEL_SIZE);
        if (ksize > 0) {
            error_report("Phase5f: kernel blob loaded at 0x%llx (%" PRId64 " bytes)",
                         (unsigned long long)APPLE_KERNEL_BASE, ksize);
        } else {
            error_report("Phase5f: kernel blob load failed (%" PRId64 ")", ksize);
        }
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
