/*
 * Phase 6b Exception / Vector Observation Payload
 *
 * Goal: observe VBAR_EL1 write attempt and the exception vector actually used
 * when a synchronous abort is taken during early MMU transition attempts.
 *
 * Load address: 0x801000000 (APPLE_KERNEL_BASE)
 */

.global _start
.section .text

_start:
    /* UART0 base: 0x0000000200352000 */
    movz    x9, #0
    movk    x9, #0x3520, lsl #16
    movk    x9, #0x2, lsl #32

    /* Marker: 'V' then '\n' */
    movz    x10, #0x56
    str     x10, [x9]
    movz    x10, #0x0a
    str     x10, [x9]

    /* Attempt to set an EL1 vector base (expected OS behavior) */
    movz    x0, #0x200
    movk    x0, #0x8010, lsl #16          /* x0 = 0x0000000080100200 */
    msr     vbar_el1, x0

    /* MMU-related sysreg writes (still stubbed/logged) */
    movz    x0, #0x1000
    movk    x0, #0x8000, lsl #16
    msr     ttbr0_el1, x0
    msr     ttbr1_el1, x0

    movz    x1, #0x3520
    msr     tcr_el1, x1

    movz    x2, #0xffff
    movk    x2, #0xffff, lsl #16
    movk    x2, #0xffff, lsl #32
    movk    x2, #0xffff, lsl #48
    msr     mair_el1, x2

    movz    x3, #1
    msr     sctlr_el1, x3

    /* Trigger a synchronous abort via unmapped high VA */
    movz    x4, #0
    movk    x4, #0xffff, lsl #48          /* x4 = 0xffff000000000000 */
    ldr     x5, [x4]

hang:
    wfi
    b       hang
