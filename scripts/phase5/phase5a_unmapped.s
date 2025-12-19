/*
 * Phase 5a unmapped access probe
 *
 * Goal: confirm accesses to unmapped regions fault (graceful failure).
 */

.global _start
.section .text

_start:
    // Intentionally outside mapped DRAM (DRAM is 0x8_0000_0000..0x8_0FFF_FFFF)
    ldr     x2, =0x900000000
    ldr     x3, [x2]          // should fault

    // If we get here, the unmapped access did not fault.
    mov     x20, #0xDEAD
1:
    wfi
    b       1b
