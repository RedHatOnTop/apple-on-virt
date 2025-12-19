/*
 * Phase 5a memory contract probe
 *
 * Goal: detect whether DRAM is writable at 0x8_0000_0000.
 *
 * Contract under test:
 * - DRAM exists at 0x8_0000_0000
 *
 * Result markers (x20):
 * - 0x0001BEEF: write/read succeeded
 * - 0x0002BEEF: write/read mismatch (unexpected)
 *
 * Note: If access faults before marker, QEMU log should show abort at the
 *       faulting instruction.
 */

.global _start
.section .text

_start:
    // x2 = 0x8_0000_0000
    ldr     x2, =0x800000000

    // Write/read test value
    mov     x4, #0xCAFE
    movk    x4, #0xBABE, lsl #16

    str     x4, [x2]
    ldr     x5, [x2]
    cmp     x4, x5
    b.ne    mismatch

    mov     x20, #0xBEEF
    movk    x20, #0x0001, lsl #16
    b       done

mismatch:
    mov     x20, #0xBEEF
    movk    x20, #0x0002, lsl #16

 done:
    wfi
    b       done
