/*
 * Phase 5b UART smoke test payload
 *
 * Purpose:
 *  - Write a single character via UART0 MMIO (for observability)
 *  - Trigger a controlled failure after the write (unmapped MMIO read)
 *
 * Entry:
 *  - PC = 0x8_0010_0000 (APPLE_IBOOT_BASE)
 *  - X0 = ADT pointer (not used here)
 */

.global _start
.section .text

_start:
    /* UART0 base: 0x2_3520_0000 (0x0000_0002_3520_0000) */
    mov     x9, #0x0000
    movk    x9, #0x3520, lsl #16
    movk    x9, #0x0002, lsl #32

    /* Emit '!' */
    mov     x10, #'!'
    strb    w10, [x9]

    /* Controlled failure: read unmapped address 0x9_0000_0000 */
    mov     x11, #0x0000
    movk    x11, #0x0009, lsl #32
    ldr     x12, [x11]

hang:
    wfi
    b       hang
