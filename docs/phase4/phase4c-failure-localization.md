# Phase 4-C: Failure Localization

**Date**: 2025-12-19  
**Status**: ✓ QUALITY GATE PASSED

---

## 1. OBSERVED FAILURE

### From Phase 4-B

**Test Case**: Minimal ADT (96 bytes)

**Failure Marker**: x20 = 0x0001FA11

**Failure Label**: `no_chosen_node`

**Last PC**: 0x4400103c

---

## 2. FAILURE CLASSIFICATION

### Classification Options (per Phase 4 spec)

| Option | Description | Applies? |
|--------|-------------|----------|
| Missing MMIO region | Unmapped hardware address | NO |
| Missing device description | ADT node/property missing | **YES** |
| Invalid CPU state | Wrong EL, registers, etc. | NO |
| Unsupported instruction | PAC, BTI, etc. | NO |
| UNKNOWN | Cannot determine | NO |

### Selected Classification

**MISSING DEVICE DESCRIPTION**

---

## 3. EVIDENCE

### Evidence 1: ADT Header Valid

**Source**: CPU trace  
**Quote**:
```
X01=0000000000000002  // property_count = 2 (valid)
X02=0000000000000000  // child_count = 0 (valid but empty)
```

**Interpretation**: ADT structure is parseable

### Evidence 2: Property Parsing Succeeded

**Source**: CPU trace  
**Quote**:
```
X04=00000000656d616e  // "name" in LE
X05=00000000656d616e  // comparison matched
```

**Interpretation**: First property correctly identified

### Evidence 3: Failure at Child Lookup

**Source**: CPU trace, instruction at PC 0x4400103c  
**Quote**:
```
cbz     w2, no_chosen_node  // Branch taken (w2 = 0)
```

**Interpretation**: Failure is NOT parsing, it's missing content

### Evidence 4: No MMIO Access

**Source**: CPU trace  
**Quote**: No addresses outside 0x4400xxxx or 0x4401xxxx accessed

**Interpretation**: Not a hardware/MMIO issue

### Evidence 5: No Invalid Instructions

**Source**: CPU trace  
**Quote**: All instructions executed successfully until intentional halt

**Interpretation**: Not an instruction compatibility issue

---

## 4. ROOT CAUSE

### Direct Cause

The minimal ADT has `child_count = 0`.

The iBoot surrogate expects a `/chosen` child node (as real iBoot does).

### Missing Element

**Node**: `/chosen`

**Location**: First child of root node

**Purpose**: Contains boot arguments, kernel info, etc.

---

## 5. QUALITY GATE C EVALUATION

### Requirements

- [x] **Failure classifiable with evidence**: YES - "Missing device description"
- [x] **Evidence quoted from logs**: YES - See Section 3

### Classification Confidence

**HIGH**: Clear evidence that:
1. ADT format is valid (parsing succeeded)
2. ADT content is incomplete (no /chosen node)
3. No other failure type applies

---

## 6. NO FIXES APPLIED

Per Phase 4 rules:
- NO fixes
- NO stubbing  
- NO guessing

Classification only.

---

## 7. PHASE 4-C: COMPLETE

**Classification**: MISSING DEVICE DESCRIPTION

**Specific**: /chosen node not present in minimal ADT

**Next Phase**: 4-D (Minimal Platform Adjustment)
