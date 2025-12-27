# Phase 10e: VA Acceptance Gap Analysis

## Scope
Static analysis only. No execution, no slide guessing, no MMU changes.

---

## 1. Precise VA Span Restatement

### Kernel VA Span (from Phase 10a)
From `output/phase10/phase10a/summary.txt` and `segments.csv`:

| Metric | Value |
|--------|-------|
| min_va | `0xfffffe0007004000` |
| max_va | `0xfffffe000d0cc000` |
| va_span | `0x60c8000` (101,482,496 bytes ≈ 96.8 MB) |
| entry_pc | `0xfffffe0007d44528` |

Segment layout (contiguous):
```
__TEXT        0xfffffe0007004000 .. 0xfffffe000700c000
__PRELINK_TEXT 0xfffffe000700c000 .. 0xfffffe0007c70000
__TEXT_EXEC   0xfffffe0007c70000 .. 0xfffffe000abd0000  (contains entry_pc)
__DATA_CONST  0xfffffe000abd0000 .. 0xfffffe000b790000
__PRELINK_INFO 0xfffffe000b790000 .. 0xfffffe000ba60000
__DATA        0xfffffe000ba60000 .. 0xfffffe000c1a4000
__LINKEDIT    0xfffffe000c1a4000 .. 0xfffffe000d0cc000
```

### Emulator Acceptance Span (from Phase 8a)
From `emulator/qemu-apple-silicon/target/arm/tcg/tlb_helper.c` lines 311-328:

```c
const uint64_t DRAM_BASE = 0x800000000ULL;
const uint64_t DRAM_SIZE = 0x10000000ULL; /* 256MB */
const uint64_t HIGH_BASE = 0xffff000000000000ULL;
```

Accepted VA ranges:
1. **High-VA window**: `[0xffff000000000000, 0xffff000010000000)` → PA `[0x800000000, 0x810000000)`
2. **Identity window**: `[0x800000000, 0x810000000)` → PA identity

| Metric | Value |
|--------|-------|
| HIGH_BASE | `0xffff000000000000` |
| Acceptance ceiling | `0xffff000010000000` (HIGH_BASE + 256MB) |
| Acceptance size | `0x10000000` (256 MB) |

---

## 2. Gap Quantification

### Numeric Gap
```
Kernel min_va:        0xfffffe0007004000
Emulator HIGH_BASE:   0xffff000000000000
─────────────────────────────────────────
Offset from HIGH_BASE: 0xfe0007004000 (279,173,095,440,384 bytes)
```

The kernel's lowest VA is **~254 TiB** above the emulator's HIGH_BASE.

### Acceptance Test
```
Kernel entry_pc:      0xfffffe0007d44528
Emulator ceiling:     0xffff000010000000

entry_pc - HIGH_BASE = 0xfe0007d44528
Acceptance bound:     0x0000000010000000 (256 MB)

0xfe0007d44528 >> 0x10000000  →  REJECTED
```

**Result**: The kernel entry PC is not within the emulator's current acceptance window.

---

## 3. Gap Classification

### Classification: **STRUCTURAL**

The gap is **structural**, not semantic or contractual, for the following reasons:

#### Evidence for Structural Classification

1. **Fixed bit-pattern mismatch**
   - Kernel VAs use prefix `0xfffffe00_...`
   - Emulator accepts prefix `0xffff0000_...` (within 256MB offset)
   - These are different 16-bit prefixes in the upper VA bits

2. **No overlap exists**
   - Kernel span: `[0xfffffe0007004000, 0xfffffe000d0cc000)`
   - Emulator high-VA: `[0xffff000000000000, 0xffff000010000000)`
   - Intersection: ∅ (empty set)

3. **Not a size issue alone**
   - Even if emulator accepted infinite size from HIGH_BASE, the kernel VAs would still not match because they start at a different base prefix

#### Why NOT Semantic
A semantic gap would imply the addresses are "correct" but interpreted differently. Here, the addresses are numerically disjoint—no interpretation can bridge them without either:
- Changing the kernel's VA layout, or
- Changing the emulator's acceptance base

#### Why NOT Contractual
A contractual gap would imply both sides agree on the address space but disagree on responsibilities. Here, there is no address overlap to even begin a contract negotiation.

---

## 4. Root Cause Analysis

### Hypothesis A: Emulator HIGH_BASE is incorrect
The emulator uses `0xffff000000000000` as HIGH_BASE, which is a generic AArch64 high-VA canonical form. However, the macOS kernel uses `0xfffffe00_...` addresses.

**Evidence supporting this hypothesis:**
- Phase 10a shows all kernel segments use `0xfffffe00_...` prefix
- This is consistent with Apple's known kernel VA layout for arm64e

### Hypothesis B: Kernel expects relocation to a different base
The kernel's Mach-O contains `LC_DYLD_CHAINED_FIXUPS` (Phase 10b), suggesting relocation capability.

**Evidence against this as the sole explanation:**
- Even with relocation, the *preferred* VAs in the Mach-O are `0xfffffe00_...`
- iBoot's placement arithmetic (Phase 10c) shows 16KB alignment and 2MB granularity, but no evidence of rebasing to `0xffff0000_...`
- The stored delta in iBoot (Phase 10c: `0x00008b5c..0x00008b64`) is a subtraction, not a base change

### Hypothesis C: Different VA size / TCR configuration
The `0xfffffe00_...` prefix suggests a specific VA size configuration (likely 48-bit or larger with specific TCR.T1SZ).

**Evidence:**
- `0xfffffe0007004000` in binary: `1111111111111111111111100000000000000111000000000100000000000000`
- Upper 16 bits: `0xfffe` (not `0xffff`)
- This is consistent with a 48-bit VA space where bits [63:48] are sign-extended from bit 47

---

## 5. Gap Summary Table

| Aspect | Kernel | Emulator | Gap Type |
|--------|--------|----------|----------|
| VA prefix | `0xfffffe00_...` | `0xffff0000_...` | Structural |
| VA span start | `0xfffffe0007004000` | `0xffff000000000000` | ~254 TiB offset |
| VA span size | ~97 MB | 256 MB | Emulator larger (irrelevant due to base mismatch) |
| Entry PC | `0xfffffe0007d44528` | N/A | Outside acceptance |

---

## 6. Implications for Phase 11

### Without Resolution
If Phase 11 attempts kernel entry with current emulator configuration:
- First instruction fetch at `0xfffffe0007d44528` will fail
- `apple_mmu_acceptance_translate()` will return `false`
- Fault will be delivered before any kernel code executes
- **Failure would be structural, not semantic**—no useful debugging information

### With Resolution
To make Phase 11 execution *epistemically meaningful*:
- The emulator must accept VAs in the `0xfffffe00_...` range
- OR the kernel must be loaded at VAs the emulator accepts (requires understanding relocation)

---

## References
- Phase 10a: `output/phase10/phase10a/summary.txt`, `segments.csv`
- Phase 8a: `docs/phase8/phase8a-mmu-acceptance.md`
- Emulator source: `emulator/qemu-apple-silicon/target/arm/tcg/tlb_helper.c:300-333`
