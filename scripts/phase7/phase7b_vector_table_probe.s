/*
 * Phase 7b Boot-chain Simulation: minimal EL1 vector table
 *
 * Goal: observe what the kernel *assumes exists* at the EL1 vector when
 * routing is correct (Phase 7a). No real exception handling is implemented.
 *
 * Behavior: each vector entry emits a distinct UART marker and then ERET.
 * This preserves the crash/loop behavior (the fault re-triggers).
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

.macro UART_PUTC ch
    movz    x10, #\ch
    str     x10, [x9]
.endm

/* Emit a 3-byte tag: A B \n */
.macro EMIT_TAG a, b
    UART_BASE x9
    UART_PUTC \a
    UART_PUTC \b
    UART_PUTC 0x0a
.endm

_start:
    /* Marker: 'B' '7' '\n' */
    EMIT_TAG 0x42, 0x37

    /* Install an aligned EL1 vector base within this image.
     * VBAR requires 2KB alignment; use base+0x800.
     * Build x0 = 0x0000000801000800.
     */
    movz    x0, #0x0800
    movk    x0, #0x0100, lsl #16
    movk    x0, #0x0008, lsl #32

    msr     vbar_el1, x0
    isb

    /* Trigger a synchronous exception deterministically (HVC -> UNDEF here) */
    hvc     #0

hang:
    wfi
    b       hang

/*
 * Vector table placed at offset 0x800 (2KB aligned).
 * Each entry is a stub: emit marker then ERET.
 * Markers:
 *  - S0/SX: sync
 *  - I0/IX: IRQ
 *  - F0/FX: FIQ
 *  - E0/EX: SError
 *  - L0/LX: lower EL AArch64 sync
 *  - l0/lx: lower EL AArch32 sync (rare)
 */

.org 0x800
vector_base:

/* Current EL with SP0 */
.org 0x800 + 0x000
vec_sync_sp0: EMIT_TAG 0x53, 0x30; eret
.org 0x800 + 0x080
vec_irq_sp0:  EMIT_TAG 0x49, 0x30; eret
.org 0x800 + 0x100
vec_fiq_sp0:  EMIT_TAG 0x46, 0x30; eret
.org 0x800 + 0x180
vec_serr_sp0: EMIT_TAG 0x45, 0x30; eret

/* Current EL with SPx (EL1h uses this group) */
.org 0x800 + 0x200
vec_sync_spx: EMIT_TAG 0x53, 0x58; eret
.org 0x800 + 0x280
vec_irq_spx:  EMIT_TAG 0x49, 0x58; eret
.org 0x800 + 0x300
vec_fiq_spx:  EMIT_TAG 0x46, 0x58; eret
.org 0x800 + 0x380
vec_serr_spx: EMIT_TAG 0x45, 0x58; eret

/* Lower EL using AArch64 */
.org 0x800 + 0x400
vec_sync_lel64: EMIT_TAG 0x4c, 0x58; eret
.org 0x800 + 0x480
vec_irq_lel64:  EMIT_TAG 0x4c, 0x49; eret
.org 0x800 + 0x500
vec_fiq_lel64:  EMIT_TAG 0x4c, 0x46; eret
.org 0x800 + 0x580
vec_serr_lel64: EMIT_TAG 0x4c, 0x45; eret

/* Lower EL using AArch32 */
.org 0x800 + 0x600
vec_sync_lel32: EMIT_TAG 0x6c, 0x78; eret
.org 0x800 + 0x680
vec_irq_lel32:  EMIT_TAG 0x6c, 0x69; eret
.org 0x800 + 0x700
vec_fiq_lel32:  EMIT_TAG 0x6c, 0x66; eret
.org 0x800 + 0x780
vec_serr_lel32: EMIT_TAG 0x6c, 0x65; eret

/* Ensure image includes full vector range */
.org 0x1000
