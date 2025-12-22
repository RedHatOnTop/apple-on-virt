/*
 * Phase 8a MMU Acceptance Probe Payload
 *
 * Purpose: trigger SCTLR_EL1.M=1 and then perform a high-VA access which should
 * be accepted by the Phase 8a minimal MMU acceptance layer, followed by an
 * access outside the allowed ranges to demonstrate that the failure point moves.
 *
 * Load address: 0x801000000 (APPLE_KERNEL_BASE)
 */

.global _start
.section .text

/* UART0 base: 0x0000000235200000 */
.macro UART_BASE reg
    movz    \reg, #0
    movk    \reg, #0x3520, lsl #16
    movk    \reg, #0x2, lsl #32
.endm

.macro UART_PUTC reg, ch
    movz    \reg, #\ch
    str     \reg, [x9]
.endm

.macro EMIT2 a, b
    UART_BASE x9
    UART_PUTC x10, \a
    UART_PUTC x10, \b
    UART_PUTC x10, 0x0a
.endm

_start:
    /* Marker: '8''A' */
    EMIT2 0x38, 0x41

    /* VBAR_EL1 = base+0x800 */
    movz    x0, #0x0800
    movk    x0, #0x0100, lsl #16
    movk    x0, #0x0008, lsl #32          /* 0x0000000801000800 */
    msr     vbar_el1, x0
    isb

    /* Known-good stack */
    movz    x19, #0xf000
    movk    x19, #0x0fff, lsl #16
    movk    x19, #0x0008, lsl #32          /* 0x000000080ffff000 */
    mov     sp, x19

    /* Attempt MMU-related sysreg writes (expected to be stubbed/logged). */
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

    msr     sctlr_el1, xzr                /* write 0 */
    movz    x3, #1
    msr     sctlr_el1, x3                 /* attempt enable (M=1) */

    /* Post-MMU progress marker */
    EMIT2 0x50, 0x31                      /* 'P''1' */

    /* High VA load: should be accepted (VA -> DRAM_BASE) */
    movz    x4, #0
    movk    x4, #0xffff, lsl #48          /* x4 = 0xffff000000000000 */
    ldr     x5, [x4]

    /* Marker after accepted high-VA access */
    EMIT2 0x50, 0x32                      /* 'P''2' */

    /* Out-of-contract access: should fault and move FAR/ELR */
    movz    x6, #0
    ldr     x7, [x6]

hang:
    wfi
    b       hang

/* Vector table at +0x800 */
.org 0x800

/* Current EL, SPx, synchronous exception handler at +0x200 */
.org 0x800 + 0x200
vec_sync_spx:
    EMIT2 0x44, 0x41                      /* 'D''A' */
1:
    wfi
    b       1b

.org 0x1000
