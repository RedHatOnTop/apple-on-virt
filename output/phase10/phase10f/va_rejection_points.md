# Phase 10f: VA Rejection Points

## Scope
Static analysis of emulator code paths that reject or mask kernel high VAs.
No execution, no dynamic probing.

---

## 1. Primary Rejection Point

### File: `target/arm/tcg/tlb_helper.c`
### Function: `apple_mmu_acceptance_translate()`
### Lines: 300-333

```c
const uint64_t DRAM_BASE = 0x800000000ULL;
const uint64_t DRAM_SIZE = 0x10000000ULL; /* 256MB */
const uint64_t HIGH_BASE = 0xffff000000000000ULL;

*is_high_va = false;

if (va >= HIGH_BASE) {
    uint64_t off = va - HIGH_BASE;
    if (off < DRAM_SIZE) {
        *pa = DRAM_BASE + off;
        *is_high_va = true;
        return true;
    }
    return false;  // <-- REJECTION POINT 1
}

if (va >= DRAM_BASE && va < DRAM_BASE + DRAM_SIZE) {
    *pa = (hwaddr)va;
    return true;
}

return false;  // <-- REJECTION POINT 2
```

**Rejection Logic:**
- **Condition**: `va >= HIGH_BASE` but `off >= DRAM_SIZE`
- **Equivalent**: `va >= 0xffff000000000000` AND `va - 0xffff000000000000 >= 0x10000000`
- **Simplified**: `va >= 0xffff000010000000`
- **Kernel VA check**:
  - Kernel `entry_pc` = `0xfffffe0007d44528`
  - Condition: `0xfffffe0007d44528 >= 0xffff000000000000` → TRUE
  - Offset: `0xfffffe0007d44528 - 0xffff000000000000 = 0xfe0007d44528`
  - Size check: `0xfe0007d44528 >= 0x10000000` → TRUE
  - **Result**: REJECTED

**Classification**: EMULATOR POLICY
- This is NOT an ARM architectural rule
- This is a hard-coded policy limit in QEMU Apple Silicon fork
- The 256MB bound (`DRAM_SIZE`) is arbitrary for kernel VA acceptance

---

## 2. Secondary Rejection (Implicit)

### File: `target/arm/tcg/tlb_helper.c`
### Function: `arm_cpu_tlb_fill_align()`
### Lines: 357-423

```c
if (env->apple_mmu_acceptance_enabled &&
    apple_mmu_acceptance_translate(address, &pa, &is_high_va)) {
    // Accepted: fill TLB entry
    out->phys_addr = pa & TARGET_PAGE_MASK;
    // ...
    return true;
}

// If not accepted by Apple MMU, fall through to standard translation
// which may fault for other reasons
```

**Rejection Logic**:
- If `apple_mmu_acceptance_translate()` returns `false`, the function continues
- Eventually calls `get_phys_addr()` which performs proper page table walk
- **However**: The current acceptance function returns `false` for kernel VAs
- This prevents even attempting a page table walk

**Classification**: EMULATOR POLICY
- The acceptance layer is a QEMU-specific addition
- It intercepts translation before page table walk
- Standard ARMv8 behavior would proceed to page table walk

---

## 3. Architectural VA Parameter Calculation (Reference)

### File: `target/arm/helper.c`
### Function: `aa64_va_parameters()`
### Lines: 12241-12390+

```c
ARMVAParameters aa64_va_parameters(CPUARMState *env, uint64_t va,
                                    ARMMMUIdx mmu_idx, bool data,
                                    bool el1_is_aa32)
{
    // ...

    if (!regime_has_2_ranges(mmu_idx)) {
        select = 0;
        tsz = extract32(tcr, 0, 6);
        // ...
    } else {
        /*
         * Bit 55 is always between the two regions, and is canonical for
         * determining if address tagging is enabled.
         */
        select = extract64(va, 55, 1);  // <-- TTBR selection based on bit 55

        if (!select) {
            // TTBR0 (lower half)
            tsz = extract32(tcr, 0, 6);  // T0SZ field
            // ...
        } else {
            // TTBR1 (upper half)
            tsz = extract32(tcr, 16, 6);  // T1SZ field
            // ...
        }
    }

    // ...
}
```

**Analysis**:
- This function determines which TTBR to use based on VA bit 55
- For `0xfffffe0007d44528`:
  - Binary: `1111111111111111111111100000000000000111000000000100000000000000`
  - Bit 55 value: `1` (selects TTBR1, kernel page table)
- **This function does NOT reject VAs** — it only classifies them
- The rejection happens BEFORE this function is called (in acceptance layer)

**Classification**: ARCHITECTURAL (Correct)
- This is standard ARMv8-A behavior
- Does NOT reject non-canonical VAs directly
- Only selects translation regime (TTBR0 vs TTBR1)

---

## 4. No Canonicality Enforcement in QEMU

### Search Results

**Finding**: QEMU does NOT enforce ARMv8-A canonicality rules at the architecture level.

**Evidence**:
- No `if (va & ~(0xffffffffULL >> tsz))` checks found
- No explicit sign-extension validation before page table walk
- Page table walk itself will fault if descriptors are invalid
- But the VA itself is not rejected for non-canonicality

**Implication**:
- If the acceptance layer accepted `0xfffffe00_...` addresses
- QEMU would proceed to page table walk
- The walk would succeed or fail based on actual page table contents
- **This is the desired behavior** for Phase 11

---

## 5. Summary of Rejection Points

| Location | Type | Condition | Effect |
|----------|------|-----------|--------|
| `tlb_helper.c:324` | **POLICY** | `va >= HIGH_BASE && (va - HIGH_BASE) >= DRAM_SIZE` | Returns `false` immediately |
| `tlb_helper.c:332` | **POLICY** | `va < HIGH_BASE && va < DRAM_BASE` | Returns `false` immediately |
| `helper.c:aa64_va_parameters` | **ARCH** | N/A | No rejection, only TTBR selection |

---

## 6. Root Cause

**The kernel VAs are rejected because:**

1. They have the prefix `0xfffffe00_...`
2. The emulator only accepts `0xffff0000_...` + 256MB
3. The bounds check `off < DRAM_SIZE` fails
4. **Not** because of ARMv8-A canonicality rules

**The fix is architectural:**
- Change `HIGH_BASE` from `0xffff000000000000` to `0xfffffe0000000000`
- Or add a second acceptance window for kernel VAs
- Increase `DRAM_SIZE` to cover kernel span (4GB recommended)

---

## 7. What This Does NOT Affect

- **Page table walk logic** — unchanged
- **Permission checks** — unchanged
- **MMU fault handling** — unchanged
- **Exception levels** — unchanged
- **Translation regimes** — unchanged

The acceptance layer is a policy wrapper around the standard ARM translation machinery. Removing/changing it does not violate ARMv8-A semantics.

---

## References

- Phase 10e: `output/phase10/phase10e/va_gap_analysis.md`
- Phase 8a: `docs/phase8/phase8a-mmu-acceptance.md`
- Emulator source: `emulator/qemu-apple-silicon/target/arm/tcg/tlb_helper.c:300-333`
- Emulator source: `emulator/qemu-apple-silicon/target/arm/helper.c:12241+`
- Linux kernel memory layout: https://www.kernel.org/doc/html/v6.3/arm64/memory.html
