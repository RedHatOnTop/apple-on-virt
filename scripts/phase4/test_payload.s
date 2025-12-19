/*
 * Minimal AArch64 Test Payload for Phase 4-pre
 * 
 * Purpose: Verify execution environment
 * - Test instruction execution
 * - Test memory access
 * - Test ADT visibility
 * - Trigger controlled failure
 */

.global _start
.section .text

_start:
    /* TEST 1: Instruction Execution
     * Set x1 to a marker value to prove we executed
     */
    mov     x1, #0xDEAD
    movk    x1, #0xBEEF, lsl #16
    
    /* TEST 2: Memory Access (write then read)
     * Write marker to DRAM base + 0x1000
     * DRAM base: 0x8_0000_0000
     */
    mov     x2, #0x8000
    movk    x2, #0x0000, lsl #16
    movk    x2, #0x0000, lsl #32
    movk    x2, #0x0008, lsl #48      // x2 = 0x8_0000_0000
    
    add     x3, x2, #0x1000            // x3 = DRAM + 0x1000
    mov     x4, #0xCAFE
    movk    x4, #0xBABE, lsl #16
    str     x4, [x3]                   // Write to memory
    
    ldr     x5, [x3]                   // Read back
    cmp     x4, x5
    b.ne    memory_fail                // Branch if read != write
    
    /* TEST 3: ADT Visibility
     * ADT located at DRAM + 0x10000 (0x8_0001_0000)
     * Read first 8 bytes (should be property_count, child_count)
     */
    add     x6, x2, #0x10000           // x6 = DRAM + 0x10000 (ADT location)
    ldr     x7, [x6]                   // Read first 8 bytes of ADT
    
    /* Check if ADT header looks valid
     * property_count should be 2 (from minimal ADT)
     * child_count should be 0 or 2
     */
    and     x8, x7, #0xFFFFFFFF        // Extract property_count (lower 32 bits)
    cmp     x8, #2
    b.ne    adt_fail                   // Branch if property_count != 2
    
    /* TEST 4: Controlled Failure
     * Access unmapped MMIO to trigger fault
     * Use 0x2_0000_0000 (likely unmapped)
     */
    mov     x9, #0x2000
    movk    x9, #0x0000, lsl #16
    movk    x9, #0x0000, lsl #32
    movk    x9, #0x0002, lsl #48       // x9 = 0x2_0000_0000
    
    ldr     x10, [x9]                  // This should trigger fault
    
    /* Should never reach here if fault works */
    b       unexpected_success

memory_fail:
    /* Memory test failed */
    mov     x20, #0xDEAD
    movk    x20, #0x0001, lsl #16      // x20 = 0x0001DEAD (memory fail marker)
    b       hang

adt_fail:
    /* ADT test failed */
    mov     x20, #0xDEAD
    movk    x20, #0x0002, lsl #16      // x20 = 0x0002DEAD (ADT fail marker)
    b       hang

unexpected_success:
    /* Fault didn't trigger */
    mov     x20, #0xDEAD
    movk    x20, #0x0003, lsl #16      // x20 = 0x0003DEAD (no fault marker)
    b       hang

hang:
    /* Infinite loop - examine x20 for failure type */
    wfi
    b       hang
