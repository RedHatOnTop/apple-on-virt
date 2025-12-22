/*
 * Phase 6c Early-Subsystem Expectation Probe
 *
 * Not an OS kernel.
 * This payload approximates what an early kernel would try immediately
 * after MMU/vector setup in its expected environment, so we can observe
 * which subsystems are touched next (per-CPU, timer, interrupts, PSCI,
 * Apple-specific registers).
 *
 * Load address: 0x801000000 (APPLE_KERNEL_BASE)
 */

.global _start
.section .text

_start:
    /* UART0 base: 0x0000000235200000 */
    movz    x9, #0
    movk    x9, #0x3520, lsl #16
    movk    x9, #0x2, lsl #32

    /* Marker: 'C' then '\n' */
    movz    x10, #0x43
    str     x10, [x9]
    movz    x10, #0x0a
    str     x10, [x9]

    /* Vector base attempt (EL1) */
    movz    x0, #0x200
    movk    x0, #0x8010, lsl #16          /* 0x0000000080100200 */
    msr     vbar_el1, x0

    /* Per-CPU identity + per-CPU pointer */
    mrs     x11, mpidr_el1
    movz    x12, #0x3000
    movk    x12, #0x8000, lsl #16         /* 0x0000000080003000 */
    msr     tpidr_el1, x12

    /* Timer init probes */
    mrs     x13, cntfrq_el0
    mrs     x14, cntvct_el0

    /* Interrupt controller MMIO touch (AIC base 0x000000023b100000) */
    movz    x15, #0
    movk    x15, #0x0000, lsl #16
    movk    x15, #0x3b10, lsl #16         /* low 32 bits = 0x3b100000 */
    movk    x15, #0x2, lsl #32            /* high = 0x2 */
    ldr     w16, [x15]
    movz    x17, #1
    str     w17, [x15, #8]

    /* Apple implementation-defined sysreg space (e.g. IPIs) */
    mrs     x18, S3_5_C15_C0_0

    /* Secondary CPU bring-up attempt (PSCI CPU_ON via HVC #0) */
    movz    x0, #0x0003
    movk    x0, #0x8400, lsl #16          /* x0 = 0x84000003 */
    movz    x1, #1                        /* target CPU */
    movz    x2, #0x0000
    movk    x2, #0x8010, lsl #16          /* entry = 0x0000000080100000 */
    movz    x3, #0
    hvc     #0

    /* Stop: force a deterministic synchronous abort */
    movz    x4, #0
    movk    x4, #0xffff, lsl #48          /* 0xffff000000000000 */
    ldr     x5, [x4]

hang:
    wfi
    b       hang
