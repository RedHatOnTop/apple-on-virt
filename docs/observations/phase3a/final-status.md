# Phase 3a Final Status

**Date**: 2025-12-18  
**Status**: CANNOT PROCEED AS DESIGNED  
**Reason**: iBoot binaries in IPSW are ENCRYPTED

---

## Summary

Phase 3a was designed to observe real iBoot behavior to validate or invalidate assumptions. This requires executing an unmodified iBoot binary.

**Finding**: iBoot binaries in IPSW files are encrypted and cannot be extracted with available tools.

---

## What Was Attempted

1. **IPSW Acquisition**: ✓ SUCCESS
   - UniversalMac_11.0.1_20B29_Restore.ipsw (macOS 11.0.1)
   - UniversalMac_12.1_21C52_Restore.ipsw (macOS 12.1)

2. **File Extraction**: ✓ SUCCESS
   - Extracted `iBoot.j274.RELEASE.im4p` (Mac mini M1)
   - Size: 444,887 bytes

3. **Payload Extraction**: ✓ PARTIAL SUCCESS
   - Created `extract_im4p.py` to parse ASN.1 DER structure
   - Successfully extracted largest OCTET STRING
   - Payload size: 56,454 bytes

4. **Binary Extraction**: ✗ FAILED
   - Payload is encrypted (magic: 0xE3A64E43)
   - Not Mach-O format
   - Not standard compression
   - Decryption requires Apple keys/process

---

## Observations Made

### IPSW Structure

- IPSW is a ZIP archive
- Contains multiple iBoot variants per device model:
  - j274 (Mac mini M1)
  - j273/j273a (MacBook Pro 13" M1)
  - j293 (MacBook Pro 14" M1 Pro)
  - j313 (MacBook Pro 16" M1 Pro/Max)
  - t485 (Unknown model)
- Each variant is ~400-1,100 KB

### IMG4 Format

- ASN.1 DER encoded container
- Contains multiple OCTET STRINGs
- Largest OCTET STRING is the payload (~13% of im4p size)
- Payload is encrypted, not directly executable

### Encryption

- Apple encrypts iBoot in IPSW files
- Decryption normally happens:
  - During device restore process
  - By iBoot1 when loading iBoot2
  - Using hardware-backed keys
- No publicly available decryption for macOS iBoot

---

## Why This Blocks Phase 3a

Phase 3a PRIMARY QUESTIONS:
1. Where does iBoot expect DRAM? - **CANNOT ANSWER**
2. Does iBoot read FDT? - **CANNOT ANSWER**
3. Which MMIO regions accessed? - **CANNOT ANSWER**
4. What is earliest failure? - **CANNOT ANSWER**

All questions require executing real iBoot code.

---

## Alternative Sources Considered

### 1. Extracted from Running macOS

On real hardware, iBoot2 is loaded into memory unencrypted. Could potentially extract from:
- Memory dump
- /System/Library/Caches/com.apple.kernelcaches/
- BUT: Requires Apple Silicon hardware (not available)

### 2. Asahi Linux m1n1

Asahi's m1n1 is an open-source bootloader that:
- Understands Apple platform
- Implements device tree handling
- Could serve as reference

BUT: m1n1 is NOT iBoot, behavior may differ

### 3. Device Tree Files

IPSW contains DeviceTree .im4p files:
- Also encrypted
- Same extraction problem

---

## Recommendation

**ABORT Phase 3a as currently defined.**

### Path 1: Reference Implementation Study

Instead of observing iBoot, study Asahi Linux m1n1:
- Open source, readable
- Implements Apple boot protocol
- Shows expected platform state
- Reveals MMIO access patterns

**Advantages**:
- No encryption issues
- Well-documented
- Can be studied without execution

**Disadvantages**:
- Not iBoot, may have different assumptions
- May not expose iBoot-specific quirks

### Path 2: Hypothesis-Driven Development

Proceed to Phase 3b with ASSUMPTIONS based on documentation:
- DRAM at 0x8_0000_0000 (per docs)
- ADT format Device Tree (per docs)
- AIC at 0x2_3b10_0000 (per docs)
- UART at 0x2_3520_0000 (per docs)

Implement based on docs, test with m1n1 or synthetic tests.

**Advantages**:
- Can proceed without iBoot
- Documentation is detailed
- m1n1 can validate

**Disadvantages**:
- Assumptions may be wrong
- No way to observe real iBoot
- May require rework

### Path 3: Wait for Decryption Method

Pause project until:
- Decryption method found
- Unencrypted iBoot obtained
- Apple Silicon hardware acquired

**Advantages**:
- Eventually get real observations
- Avoid wrong assumptions

**Disadvantages**:
- Indefinite delay
- May never be possible

---

## Recommended Path: Hybrid Approach

1. **Study m1n1** for Apple platform understanding
2. **Implement Phase 3b** based on documentation
3. **Test with synthetic workloads** that probe platform
4. **Iterate** based on what breaks

This allows progress while maintaining observability of what we DON'T know.

---

## Artifacts Created

1. `extract_im4p.py` - ASN.1 DER parser for IMG4 files
2. `blocker.md` - Detailed analysis of extraction failure
3. `extraction.md` - IPSW structure documentation
4. `setup.md` - Phase 3a original goals
5. `final-status.md` - This document

---

## Conclusion

Phase 3a **CANNOT BE COMPLETED** as designed due to iBoot encryption.

**Invalidated Assumption**: That iBoot binaries in IPSW are extractable with basic tools.

**Proven Fact**: iBoot in IPSW is encrypted and requires Apple's decryption process.

**Next Action**: Decide on Path 1, 2, or 3 above before proceeding to Phase 3b.

---

**Phase 3a Status: BLOCKED**  
**Project Status: AWAITING DIRECTION**
