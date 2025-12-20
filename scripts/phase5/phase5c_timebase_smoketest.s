/*
 * Phase 5c: Timebase smoke test payload
 *
 * Contract exercised:
 *  - CNTFRQ_EL0 is readable (non-zero expected)
 *  - CNTVCT_EL0 is readable and monotonic across successive reads
 *
 * Entry:
 *  - PC = 0x8_0010_0000 (APPLE_IBOOT_BASE)
 *  - X0 = ADT pointer (unused)
 */

.global _start
.section .text

_start:
    /* UART0 base: 0x2_3520_0000 (0x0000_0002_3520_0000) */
    mov     x9, #0x0000
    movk    x9, #0x3520, lsl #16
    movk    x9, #0x0002, lsl #32

    /* Marker: start */
    mov     x10, #'T'
    strb    w10, [x9]

    /* Read timer frequency and virtual count */
    mrs     x1, cntfrq_el0
    mrs     x2, cntvct_el0
    mrs     x3, cntvct_el0

    /* Monotonic check: x3 >= x2 */
    cmp     x3, x2
    b.hs    1f
    mov     x10, #'!'
    strb    w10, [x9]
1:
    /* Expose values for -d cpu logs */
    mov     x20, x1
    mov     x21, x2
    mov     x22, x3

    /* Controlled failure: read unmapped address 0x9_0000_0000 */
    mov     x11, #0x0000
    movk    x11, #0x0009, lsl #32
    ldr     x12, [x11]

hang:
    wfi
    b       hang
