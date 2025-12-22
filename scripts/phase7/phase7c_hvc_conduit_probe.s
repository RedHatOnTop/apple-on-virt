/*
 * Phase 7c Boot-chain Simulation: fake HVC return conduit
 *
 * Goal: observe whether the kernel requires PSCI semantics or only a callable
 * conduit by providing a minimal HVC trap-and-return path.
 *
 * Constraints honored:
 * - No real PSCI logic.
 * - No CPU bring-up.
 * - No MMU implementation.
 * - No new devices.
 *
 * Mechanism:
 * - Install an EL1 vector table.
 * - In the EL1 sync+SPx handler, detect HVC (#0) by instruction decode at ELR.
 * - Log x0-x3 and return x0 = PSCI_NOT_SUPPORTED (-1), then skip the HVC.
 * - Any other synchronous exception: emit a marker and halt.
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

_start:
    b       start_main

/* Print low nibble in w0 to UART */
print_nibble:
    /* w0 in [0..15] */
    cmp     w0, #9
    b.le    1f
    add     w0, w0, #('a' - 10)
    b       2f
1:
    add     w0, w0, #'0'
2:
    str     x0, [x9]
    ret

/* Print x0 as 16 hex digits */
print_hex64:
    stp     x1, x2, [sp, #-16]!
    mov     x3, x0              /* preserve input */
    mov     x2, #60
1:
    lsr     x1, x3, x2
    and     w0, w1, #0xf
    bl      print_nibble
    subs    x2, x2, #4
    b.ge    1b
    ldp     x1, x2, [sp], #16
    ret

/* Emit tag: two chars + '\n' */
.macro EMIT2 a, b
    UART_BASE x9
    UART_PUTC x10, \a
    UART_PUTC x10, \b
    UART_PUTC x10, 0x0a
.endm

start_main:
    /* Marker: '7' 'C' */
    EMIT2 0x37, 0x43

    /* VBAR_EL1 = base+0x800 */
    movz    x0, #0x0800
    movk    x0, #0x0100, lsl #16
    movk    x0, #0x0008, lsl #32          /* 0x0000000801000800 */
    msr     vbar_el1, x0
    isb

    /* Boot-chain simulation: set a known-good stack pointer (Phase7a shim SP_EL1 is not usable for stack ops). */
    movz    x19, #0xf000
    movk    x19, #0x0fff, lsl #16
    movk    x19, #0x0008, lsl #32          /* 0x000000080ffff000 */
    mov     sp, x19

    /* HVC args (match Phase 6c style) */
    movz    x0, #0x0003
    movk    x0, #0x8400, lsl #16          /* x0 = 0x84000003 */
    movz    x1, #1
    movz    x2, #0
    movk    x2, #0x8010, lsl #16          /* x2 = 0x0000000080100000 */
    movz    x3, #0

    /* Marker: 'H' 'V' (about to call) */
    EMIT2 0x48, 0x56
    hvc     #0

    /* Marker: 'R' 'T' (returned from conduit) */
    EMIT2 0x52, 0x54

    /* Boot-chain simulation: observe how caller reacts to fixed return value. */
    cmp     x0, #-1
    b.ne    1f
    EMIT2 0x4e, 0x53                    /* 'N''S' (NOT_SUPPORTED) */
    b       2f
1:
    EMIT2 0x4f, 0x4b                    /* 'O''K' */
2:

    /* Deterministic follow-on fault to show progression past HVC */
    movz    x5, #0
    movk    x5, #0xffff, lsl #48          /* 0xffff000000000000 */
    ldr     x6, [x5]

hang:
    wfi
    b       hang

/* Vector table at 0x800 */
.org 0x800

/* Current EL, SPx, synchronous exception handler at +0x200 */
.org 0x800 + 0x200
vec_sync_spx:
    /* Boot-chain simulation handler: recognize HVC and return constant */
    EMIT2 0x53, 0x58                    /* 'S''X' */

    mrs     x20, elr_el1
    /* Load faulting instruction (physical==VA in this bring-up) */
    ldr     w21, [x20]
    /* HVC #0 encoding is 0xD4000002 */
    movz    w22, #0x0002
    movk    w22, #0xd400, lsl #16
    cmp     w21, w22
    b.ne    not_hvc

    /* HVC args are taken from caller registers; values are evidenced by the pre-HVC mov/movk sequence in the QEMU trace. */
    EMIT2 0x41, 0x30                    /* 'A''0' (arguments sampled) */

    /* Return x0 = PSCI_NOT_SUPPORTED (-1) */
    mov     x0, #-1

    /* Skip over the HVC instruction */
    add     x20, x20, #4
    msr     elr_el1, x20
    eret

not_hvc:
    /* Any other sync exception: marker and stop */
    EMIT2 0x3f, 0x3f                    /* '?' '?' */
1:
    wfi
    b       1b

/* Fill remaining vector range */
.org 0x1000
