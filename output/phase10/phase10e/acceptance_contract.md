# Phase 10e: Kernel VA Acceptance Contract

## Scope
Static analysis only. This document defines the minimum VA acceptance model required for Phase 11 execution to be epistemically meaningful.

---

## 1. Kernel VA Semantics Analysis (Static Evidence Only)

### Question: Are kernel VAs absolute requirements or relocatable preferences?

### Evidence Assessment

#### Evidence FOR Absolute/Fixed VA Interpretation

1. **Entry PC is a single absolute value**
   - From `LC_UNIXTHREAD`: `entry_pc = 0xfffffe0007d44528`
   - No "base + offset" encoding; the value is stored as-is
   - Source: `output/phase10/phase10a/summary.txt`

2. **Segment vmaddrs are contiguous and specific**
   - All 7 segments form a contiguous block from `0xfffffe0007004000` to `0xfffffe000d0cc000`
   - No gaps, no overlaps—suggests a pre-determined layout
   - Source: `output/phase10/phase10a/segments.csv`

3. **Entry PC appears only once in binary**
   - `occurrences_le8=1` when searching for the 8-byte LE value
   - Not a pattern repeated across relocation tables
   - Source: `output/phase10/phase10b/entry_pc_occurrences.txt`

#### Evidence FOR Relocatable/Preferred VA Interpretation

1. **LC_DYLD_CHAINED_FIXUPS present**
   - The kernelcache contains chained fixup metadata
   - `chained_fixups_linkedit=(101466112, 2546)`
   - This is a structural signal that some loader may process relocations
   - Source: `output/phase10/phase10b/reloc_loadcmd_presence.txt`

2. **iBoot computes and stores a delta**
   - `0x00008b5c: sub x8, x8, x26`
   - `0x00008b64: str x8, [x9, #0x218]`
   - A delta between address-like values is persisted
   - Source: `output/phase10/phase10c/iBoot.vma2.payload.disasm.txt`

3. **iBoot performs placement arithmetic**
   - 16KB alignment: `and x9, x8, #0xffffffffffffc000`
   - 2MB granularity: `mov w8, #0x200000` with doubling loop
   - Bounds checking against limit registers
   - Source: Phase 10c analysis

4. **High-VA pointers exist throughout binary**
   - `qwords_in_kernel_va_span=203065` out of `total_qwords=12685312`
   - ~1.6% of 8-byte values fall within kernel VA range
   - These may be fixup targets
   - Source: `output/phase10/phase10b/qword_range_counts.txt`

### Synthesis: What Can Be Concluded?

**Conclusion: The kernel VA layout is PREFERRED, not ABSOLUTE, but the relocation mechanism is OPAQUE.**

Justification:
- The presence of `LC_DYLD_CHAINED_FIXUPS` proves the Mach-O format supports relocation
- iBoot's delta computation proves the boot chain has relocation-related logic
- However, we cannot prove:
  - Whether iBoot actually applies fixups (no proven call path)
  - What slide value (if any) is used
  - Whether the kernel expects to run at its preferred VAs or accepts relocation

**For Phase 11 purposes**: We must treat the observed VAs as the *expected runtime VAs* unless we can prove otherwise. The emulator must accept these VAs.

---

## 2. Boot Chain Responsibility Boundary

### Question: Who is structurally capable of relocating the kernel?

| Component | Capability | Evidence |
|-----------|------------|----------|
| iBoot | **Capable** | Contains placement arithmetic, delta storage, Mach-O header parsing |
| Kernel | **Unknown** | No evidence of self-relocation in static analysis |
| Emulator | **Not responsible** | Emulator should accept whatever VA the boot chain provides |

### Question: Who is structurally required to accept the final VA?

| Component | Requirement | Evidence |
|-----------|-------------|----------|
| iBoot | Must know final VA to set ELR_EL1 | `msr elr_el1, x0` before `eret` |
| Emulator MMU | Must translate final VA to PA | TLB fill path in `tlb_helper.c` |
| Physical memory | Must contain kernel code at translated PA | DRAM backing |

### Responsibility Matrix

```
┌─────────────────────────────────────────────────────────────────┐
│                    Boot Chain Responsibility                     │
├─────────────────────────────────────────────────────────────────┤
│  iBoot                                                          │
│  ├── Load kernelcache from storage                              │
│  ├── Parse Mach-O headers                                       │
│  ├── (Possibly) apply chained fixups                            │
│  ├── (Possibly) compute slide and rebase                        │
│  ├── Place kernel in physical memory                            │
│  ├── Configure EL1 state (ELR_EL1, SPSR_EL1)                   │
│  └── Execute eret to transfer control                           │
├─────────────────────────────────────────────────────────────────┤
│  Emulator MMU Acceptance Layer                                  │
│  ├── Accept VA presented by kernel code                         │
│  ├── Translate VA → PA according to configured model            │
│  └── Provide PA to memory subsystem                             │
├─────────────────────────────────────────────────────────────────┤
│  Kernel                                                         │
│  ├── Execute from entry_pc                                      │
│  ├── Access memory via VAs in its segment layout                │
│  └── (Later) configure its own page tables                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Minimum Acceptance Contract Definition

### Contract Goal
Define the smallest VA acceptance model that:
1. Allows Phase 11 execution to proceed past the first instruction fetch
2. Does not mask errors behind known structural constraints
3. Is justified by static evidence

### Contract Specification

#### Option A: Exact Kernel VA Range Acceptance

Accept only the observed kernel VA span:

```
VA_MIN  = 0xfffffe0007004000
VA_MAX  = 0xfffffe000d0cc000
VA_SIZE = 0x60c8000 (≈97 MB)
```

**Mapping rule:**
```
if (va >= VA_MIN && va < VA_MAX) {
    offset = va - VA_MIN;
    pa = DRAM_BASE + KERNEL_OFFSET + offset;
    // where KERNEL_OFFSET is the physical offset where kernel is loaded
}
```

**Justification:**
- Matches exactly what the kernel artifact declares
- Any access outside this range is a genuine kernel bug or missing emulation
- Minimal attack surface for false positives

**Limitation:**
- Requires knowing where kernel is physically loaded (KERNEL_OFFSET)
- Does not account for potential slide

#### Option B: High-VA Prefix Acceptance (Recommended)

Accept all VAs with the `0xfffffe00_...` prefix, bounded by reasonable size:

```
KERNEL_HIGH_BASE = 0xfffffe0000000000
KERNEL_HIGH_SIZE = 0x100000000 (4 GB, generous bound)
```

**Mapping rule:**
```
if (va >= KERNEL_HIGH_BASE && va < KERNEL_HIGH_BASE + KERNEL_HIGH_SIZE) {
    offset = va - KERNEL_HIGH_BASE;
    pa = DRAM_BASE + offset;
}
```

**Justification:**
- Covers the observed kernel VA range (`0xfffffe0007004000` to `0xfffffe000d0cc000`)
- Allows for potential slide within the `0xfffffe00_...` space
- Still rejects accesses to other VA regions (e.g., `0xffff0000_...`)
- 4 GB is generous but bounded—won't accept arbitrary addresses

**Why 4 GB?**
- Kernel span is ~97 MB
- 4 GB provides ~40x headroom for:
  - Potential slide variations
  - Additional kernel data structures
  - Boot arguments, device tree, etc.
- Still far smaller than accepting all high VAs

#### Option C: Dual-Window Acceptance

Maintain existing `0xffff0000_...` window AND add `0xfffffe00_...` window:

```
Window 1 (existing): 0xffff000000000000 + 256MB → DRAM_BASE
Window 2 (new):      0xfffffe0000000000 + 4GB   → DRAM_BASE + 0x10000000
```

**Justification:**
- Preserves existing boot chain compatibility
- Adds kernel VA acceptance
- Separates physical regions to avoid overlap

---

## 4. Recommended Contract

### Primary Recommendation: Option B (High-VA Prefix Acceptance)

```c
/* Phase 10e acceptance contract */
const uint64_t KERNEL_HIGH_BASE = 0xfffffe0000000000ULL;
const uint64_t KERNEL_HIGH_SIZE = 0x100000000ULL; /* 4 GB */
const uint64_t DRAM_BASE = 0x800000000ULL;

if (va >= KERNEL_HIGH_BASE && va < KERNEL_HIGH_BASE + KERNEL_HIGH_SIZE) {
    uint64_t offset = va - KERNEL_HIGH_BASE;
    *pa = DRAM_BASE + offset;
    return true;
}
```

### Why This Contract?

1. **Evidence-backed**: Kernel VAs are in `0xfffffe00_...` range (Phase 10a)
2. **Bounded**: 4 GB is finite and reasonable
3. **Debuggable**: Accesses outside this range will fault, providing diagnostic info
4. **Non-speculative**: Does not assume slide values or relocation behavior
5. **Minimal**: Does not accept arbitrary high VAs

### Physical Memory Requirement

For this contract to work, the kernel must be loaded at:
```
PA_BASE = DRAM_BASE + (kernel_min_va - KERNEL_HIGH_BASE)
        = 0x800000000 + (0xfffffe0007004000 - 0xfffffe0000000000)
        = 0x800000000 + 0x7004000
        = 0x807004000
```

This is within the first 256 MB of DRAM (offset `0x7004000` ≈ 112 MB), which is acceptable.

---

## 5. Contract Validation Criteria

Before Phase 11 execution, verify:

| Criterion | Check |
|-----------|-------|
| Kernel loaded at correct PA | `kernel_pa_base == 0x807004000` (or equivalent) |
| Entry PC translates correctly | `VA 0xfffffe0007d44528 → PA 0x807d44528` |
| First segment accessible | `VA 0xfffffe0007004000 → PA 0x807004000` |
| Last segment accessible | `VA 0xfffffe000d0cbfff → PA 0x80d0cbfff` |

---

## References
- Phase 10a: Kernel VA model (`output/phase10/phase10a/`)
- Phase 10b: Relocation semantics (`output/phase10/phase10b/`)
- Phase 10c: iBoot analysis (`output/phase10/phase10c/`)
- Phase 10d: Boot-to-kernel contract (`output/phase10/phase10d/`)
- Phase 8a: Current MMU acceptance (`docs/phase8/phase8a-mmu-acceptance.md`)
