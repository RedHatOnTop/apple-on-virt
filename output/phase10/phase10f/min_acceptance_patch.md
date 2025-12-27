# Phase 10f: Minimal Acceptance Patch (Conceptual)

## Scope
This document describes the **conceptual** change required to enable kernel VA acceptance.
This is NOT executable code — it's a specification for implementation.

---

## 1. Current State (Problem)

### File: `target/arm/tcg/tlb_helper.c`
### Function: `apple_mmu_acceptance_translate()`

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
    return false;  // <-- Kernel VAs rejected here
}

if (va >= DRAM_BASE && va < DRAM_BASE + DRAM_SIZE) {
    *pa = (hwaddr)va;
    return true;
}

return false;
```

**Problem Summary**:
- `HIGH_BASE = 0xffff000000000000` doesn't match kernel `0xfffffe00_...` prefix
- `DRAM_SIZE = 256MB` is too small for 97MB kernel span
- Kernel VAs fail both checks and return `false`

---

## 2. Proposed Solution (Option A: Single Window)

### Approach
Replace the existing high-VA window with a kernel-specific window.

### Conceptual Change

```c
const uint64_t DRAM_BASE = 0x800000000ULL;
const uint64_t DRAM_SIZE = 0x10000000ULL; /* 256MB (unchanged for identity) */

// OLD: const uint64_t HIGH_BASE = 0xffff000000000000ULL;
// NEW: Use kernel VA prefix
const uint64_t KERNEL_HIGH_BASE = 0xfffffe0000000000ULL;
const uint64_t KERNEL_HIGH_SIZE = 0x100000000ULL; /* 4GB (generous) */

*is_high_va = false;

// Accept kernel VAs
if (va >= KERNEL_HIGH_BASE) {
    uint64_t off = va - KERNEL_HIGH_BASE;
    if (off < KERNEL_HIGH_SIZE) {
        *pa = DRAM_BASE + off;
        *is_high_va = true;
        return true;
    }
    return false;
}

// Identity region (unchanged)
if (va >= DRAM_BASE && va < DRAM_BASE + DRAM_SIZE) {
    *pa = (hwaddr)va;
    return true;
}

return false;
```

### Why This Works

**Kernel entry PC test**:
- VA: `0xfffffe0007d44528`
- Check: `0xfffffe0007d44528 >= 0xfffffe0000000000` → **TRUE**
- Offset: `0xfffffe0007d44528 - 0xfffffe0000000000 = 0x7d44528`
- Size: `0x7d44528 < 0x100000000` (4GB) → **TRUE**
- PA: `0x800000000 + 0x7d44528 = 0x807d44528`
- **Result**: ACCEPTED ✓

### Requirements

**Physical Memory Layout**:
The kernel must be loaded at the correct physical address:

```
Kernel min_va = 0xfffffe0007004000
Expected PA = 0x800000000 + (0xfffffe0007004000 - 0xfffffe0000000000)
            = 0x800000000 + 0x7004000
            = 0x807004000
```

**Boot Chain Responsibility**:
- iBoot must load kernelcache at PA `0x807004000` (or equivalent)
- Or, adjust the mapping formula to match actual load address

---

## 3. Alternative Solution (Option B: Dual Window)

### Approach
Keep existing window AND add kernel window (maximizes compatibility).

### Conceptual Change

```c
const uint64_t DRAM_BASE = 0x800000000ULL;
const uint64_t DRAM_SIZE = 0x10000000ULL; /* 256MB */

// Window 1: Original (for compatibility)
const uint64_t HIGH_BASE = 0xffff000000000000ULL;
const uint64_t HIGH_SIZE = 0x10000000ULL; /* 256MB */

// Window 2: Kernel (new)
const uint64_t KERNEL_HIGH_BASE = 0xfffffe0000000000ULL;
const uint64_t KERNEL_HIGH_SIZE = 0x100000000ULL; /* 4GB */

*is_high_va = false;

// Check window 1 (original high-VA)
if (va >= HIGH_BASE && va < HIGH_BASE + HIGH_SIZE) {
    uint64_t off = va - HIGH_BASE;
    *pa = DRAM_BASE + off;
    *is_high_va = true;
    return true;
}

// Check window 2 (kernel VA)
if (va >= KERNEL_HIGH_BASE && va < KERNEL_HIGH_BASE + KERNEL_HIGH_SIZE) {
    uint64_t off = va - KERNEL_HIGH_BASE;
    *pa = DRAM_BASE + off;  // Or: DRAM_BASE + HIGH_SIZE + off for non-overlapping
    *is_high_va = true;
    return true;
}

// Identity region
if (va >= DRAM_BASE && va < DRAM_BASE + DRAM_SIZE) {
    *pa = (hwaddr)va;
    return true;
}

return false;
```

### Trade-off

| Aspect | Option A (Single) | Option B (Dual) |
|--------|------------------|-----------------|
| Simplicity | ✅ Simpler | ❌ More complex |
| Compatibility | ❌ Breaks existing | ✅ Preserves existing |
| Debugging | ✅ Single path | ⚠️ Multiple paths |
| Risk | ⚠️ May affect other components | ✅ Safer |

**Recommendation**: Start with **Option A** for Phase 11. If compatibility issues arise, switch to Option B.

---

## 4. Physical Memory Mapping Verification

### Option A Mapping Formula

```
VA_RANGE = [KERNEL_HIGH_BASE, KERNEL_HIGH_BASE + KERNEL_HIGH_SIZE)
         = [0xfffffe0000000000, 0xfffffe0100000000)

PA_OFFSET = VA - KERNEL_HIGH_BASE

PA = DRAM_BASE + PA_OFFSET

Example:
  VA = 0xfffffe0007004000 (kernel __TEXT start)
  PA_OFFSET = 0xfffffe0007004000 - 0xfffffe0000000000 = 0x7004000
  PA = 0x800000000 + 0x7004000 = 0x807004000
```

### Boot Chain Requirement

**iBoot must place kernel at PA = `0x807004000`**

If iBoot loads at a different PA, the mapping formula must be adjusted:

```c
// If kernel loaded at KERNEL_PA_BASE:
*pa = KERNEL_PA_BASE + off;
```

---

## 5. Implementation Checklist

### Before Implementation
- [ ] Verify kernel physical load address from iBoot analysis
- [ ] Confirm `DRAM_BASE` alignment matches actual physical memory
- [ ] Check for dependencies on `HIGH_BASE` value in other code

### Implementation Steps
1. Update `tlb_helper.c` constants (`KERNEL_HIGH_BASE`, `KERNEL_HIGH_SIZE`)
2. Update acceptance logic to use new constants
3. Verify `is_high_va` flag is set correctly for kernel VAs
4. Test with known kernel VA → PA translations

### Verification
- [ ] Compile without errors
- [ ] Static analysis confirms no regressions
- [ ] Unit test with kernel VA range (if available)
- [ ] Review against Phase 8a acceptance contract

---

## 6. Risk Assessment

### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Wrong PA calculation | Medium | High | Verify kernel load address |
| Size too small | Low | High | Use generous 4GB bound |
| Breaks existing functionality | Medium | Medium | Use Option B (dual window) |
| Misaligned pages | Low | Medium | Ensure 4KB/16KB alignment |

### Non-Risks (Verified Safe)

- ✅ Architectural validity — VAs are canonical
- ✅ ARMv8-A compliance — no violation of canonicality rules
- ✅ Page table walk — unchanged downstream logic
- ✅ Permission checks — unchanged
- ✅ Exception handling — unchanged

---

## 7. Success Criteria

Phase 10f is **COMPLETE** when:

1. ✅ VA rejection points identified and documented
2. ✅ Canonicality of kernel VAs confirmed
3. ✅ Acceptance patch conceptually designed (this document)
4. ✅ Safety boundary defined (enables Phase 11)
5. ⏳ Implementation deferred to Phase 11 (non-blocking)

**Note**: This phase does NOT require implementing the patch — only defining it conceptually.

---

## 8. Connection to Phase 11

**Before Phase 11 execution**:
- Implement this patch (either Option A or B)
- Rebuild QEMU
- Verify kernel VAs are now accepted

**After Phase 11 execution**:
- If kernel faults, it's now a **semantic** failure (not structural)
- Faults indicate missing page tables, wrong permissions, etc.
- These are debuggable with standard ARMv8 diagnostics

---

## References

- Phase 10e acceptance contract: `output/phase10/phase10e/acceptance_contract.md`
- Phase 10e VA gap analysis: `output/phase10/phase10e/va_gap_analysis.md`
- This phase's rejection points: `output/phase10/phase10f/va_rejection_points.md`
- This phase's canonicality: `output/phase10/phase10f/canonicality_analysis.md`
