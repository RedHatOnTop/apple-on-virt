/*
 * Phase 7a Boot-chain Simulation: EL1 entry shim
 *
 * Goal: keep Phase 5 contracts intact, but change the execution environment
 * so the kernel payload is entered at EL1 (via ERET from EL3).
 *
 * Invariants preserved:
 * - X0 remains the DT pointer passed in from machine init.
 * - X1 is set to APPLE_BOOTARGS_BASE (0x800010000), same as Phase5f handoff.
 * - No ADT/boot_args mutation.
 * - No new devices/MMIO.
 *
 * Load address: 0x800100000 (APPLE_IBOOT_BASE)
 */

.global _start
.section .text

_start:
    /* UART0 base: 0x0000000235200000 */
    movz    x9, #0
    movk    x9, #0x3520, lsl #16
    movk    x9, #0x2, lsl #32

    /* Marker: 'H' then '\n' (matches Phase5f handoff) */
    movz    x10, #0x48
    str     x10, [x9]
    movz    x10, #0x0a
    str     x10, [x9]

    /* x1 = boot_args base (0x0000000800010000) */
    movz    x1, #0
    movk    x1, #0x1, lsl #16
    movk    x1, #0x8, lsl #32

    /* x2 = 0 (reserved) */
    movz    x2, #0

    /* x16 = kernel entry (0x0000000801000000) */
    movz    x16, #0
    movk    x16, #0x100, lsl #16
    movk    x16, #0x8, lsl #32

    /* Marker: 'E' then '1' then '\n' (Phase7a EL1 shim active) */
    movz    x10, #0x45
    str     x10, [x9]
    movz    x10, #0x31
    str     x10, [x9]
    movz    x10, #0x0a
    str     x10, [x9]

    /* Boot-chain simulation: configure lower EL to AArch64 and drop to EL1 */
    mrs     x20, scr_el3
    /* SCR_EL3.RW = 1 (lower ELs are AArch64) */
    orr     x20, x20, #(1 << 10)
    msr     scr_el3, x20
    isb

    /* SP_EL1 = top of DRAM - 0x1000 (0x80ffff000) */
    movz    x21, #0
    movk    x21, #0xfff0, lsl #16
    movk    x21, #0x80ff, lsl #32
    msr     sp_el1, x21

    /* ELR_EL3 = kernel entry */
    msr     elr_el3, x16

    /* SPSR_EL3: return to EL1h with D/A/I/F masked (0x3c5) */
    movz    x22, #0x3c5
    msr     spsr_el3, x22
    isb

    eret

hang:
    wfi
    b       hang
