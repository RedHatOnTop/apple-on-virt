# Phase 3a Blocker

**Date**: 2025-12-18  
**Status**: BLOCKED - ENCRYPTED PAYLOAD

## Issue

iBoot binary is encrypted inside `.im4p` container.

## Context

- Extracted `iBoot.j274.RELEASE.im4p` from IPSW (444,887 bytes)
- File is in IMG4 Payload format (ASN.1 DER encoded)
- Successfully extracted largest OCTET STRING (56,454 bytes)
- Payload magic: 0xE3A64E43 (not Mach-O, not known compression)
- **Payload is ENCRYPTED**

## Extraction Attempt Results

Created `extract_im4p.py` to parse ASN.1 DER structure:
- Found 186 OCTET STRINGs in file
- Largest payload: 56,454 bytes at offset 359560
- Extracted to `iBoot.j274.bin`
- No Mach-O magic (0xFEEDFACF/0xFEEDFACE)
- No compression magic (bvx*, complzss, LZMA)
- Unknown magic 0xE3A64E43 indicates encryption

## Required Tool

`img4tool` - mentioned in documentation but not available

## Alternative Approaches Considered

1. **Manual ASN.1 parsing**: Complex, requires understanding IMG4 structure
2. **Try different IPSW files**: Same format, same problem
3. **Use Device Tree instead**: Wrong phase, need iBoot observation first

## Impact on Phase 3a

**CANNOT PROCEED** with original Phase 3a goals:
- Cannot load real iBoot binary
- Cannot observe real iBoot behavior
- Cannot answer primary questions:
  1. Where does iBoot expect DRAM?
  2. Does iBoot read FDT?
  3. Which MMIO regions accessed?
  4. What is earliest failure?

## Observations Available WITHOUT Real iBoot

Can observe with test binary:
- Memory access patterns (if logging added)
- MMIO access attempts (if devices mapped)
- Exception behavior

## Recommendation

**BLOCK Phase 3a** until either:
1. img4tool is obtained/built
2. Alternative extraction method found
3. Phase 3a scope is redefined to work without real iBoot

## Alternative: Modified Phase 3a

Could proceed with LIMITED observation:
- Add MMIO region logging to emulator
- Add memory access tracing
- Run test binaries that probe specific addresses
- Document what infrastructure is needed

This would not answer the primary questions but would prepare observability infrastructure for when real iBoot becomes available.
