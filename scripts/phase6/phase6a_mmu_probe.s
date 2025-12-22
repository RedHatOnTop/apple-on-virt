/*
 * Phase 6a MMU Observation Payload (OS-side probe)
 *
 * This payload is NOT an MMU implementation.
 * It only attempts the standard EL1 MMU enable sequence (TTBR/TCR/MAIR/SCTLR)
 * so the emulator can log the sysreg writes and the first failure afterwards.
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

    /* Marker: 'M' then '\n' */
    movz    x10, #0x4d
    str     x10, [x9]
    movz    x10, #0x0a
    str     x10, [x9]

    /* Attempt MMU-related sysreg writes (expected to be stubbed/logged) */
    movz    x0, #0x1000
    movk    x0, #0x8000, lsl #16          /* x0 = 0x0000000080001000 */

    msr     ttbr0_el1, x0
    msr     ttbr1_el1, x0

    movz    x1, #0x3520
    msr     tcr_el1, x1

    movz    x2, #0xffff
    movk    x2, #0xffff, lsl #16
    movk    x2, #0xffff, lsl #32
    movk    x2, #0xffff, lsl #48          /* x2 = 0xffffffffffffffff */
    msr     mair_el1, x2

    movz    x3, #0
    msr     sctlr_el1, x3                 /* write 0 */
    movz    x3, #1
    msr     sctlr_el1, x3                 /* attempt enable (M=1) */

    /* First post-MMU action: access a high VA (will fail without translation) */
    movz    x4, #0
    movk    x4, #0xffff, lsl #48          /* x4 = 0xffff000000000000 */
    ldr     x5, [x4]

hang:
    wfi
    b       hang
