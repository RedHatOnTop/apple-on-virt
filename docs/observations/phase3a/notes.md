# Phase 3a Observation Notes

**OBSERVATIONS ONLY - NO INTERPRETATION**

---

## Observation 1: IPSW File Structure

**Method**: Examined UniversalMac_11.0.1_20B29_Restore.ipsw

**Observed**:
- IPSW is a ZIP archive
- Contains path: `Firmware/all_flash/iBoot.*.RELEASE.im4p`
- Multiple iBoot variants present:
  - iBoot.j273.RELEASE.im4p (1,154,359 bytes)
  - iBoot.j273a.RELEASE.im4p (1,154,359 bytes)
  - iBoot.j274.RELEASE.im4p (444,887 bytes)
  - iBoot.j293.RELEASE.im4p (460,663 bytes)
  - iBoot.j313.RELEASE.im4p (447,895 bytes)
  - iBoot.t485.RELEASE.im4p (1,162,919 bytes)
- Each has companion `.plist` file (331 bytes each)
- Also contains `iBootData.*.RELEASE.im4p` files (9,733 bytes each)

**Fact**: iBoot binaries are distributed in `.im4p` format, not raw binaries.

---

## Observation 2: IMG4 Payload Format

**Method**: Examined iBoot.j274.RELEASE.im4p with hex editor and Python script

**Observed**:
- File starts with ASN.1 DER SEQUENCE tag (0x30)
- Contains string "IM4P" at offset 4-7
- Contains string "ibot" at offset 16-19
- Contains version string "iBoot-6723.50.2" at offset 21-36
- Total file size: 444,887 bytes

**Fact**: IMG4 Payload files are ASN.1 DER encoded containers.

---

## Observation 3: Payload Extraction

**Method**: Created extract_im4p.py to parse DER structure

**Observed**:
- Found 186 OCTET STRING tags in file
- OCTET STRING tag is 0x04 in DER encoding
- Largest OCTET STRING:
  - Offset: 359,560 bytes from start
  - Length: 56,454 bytes
  - Represents 12.7% of total file size
- Next largest OCTET STRING: 6,796 bytes
- Remaining OCTET STRINGs: < 200 bytes each

**Fact**: IMG4 files contain one large payload and many small metadata fields.

---

## Observation 4: Payload Content

**Method**: Extracted largest OCTET STRING to iBoot.j274.bin, examined header

**Observed**:
- First 4 bytes (little-endian): 0xE3A64E43
- First 4 bytes (big-endian): 0x434EA6E3
- First 64 bytes (hex):
```
43 4E A6 E3 54 4E C9 43 CB 12 8A 68 E9 1C 41 C2
58 0D 30 4D 3B AD 32 07 A2 81 D5 0F 0B 12 30 E0
77 86 68 84 91 F0 C7 8A 1C 53 08 D6 12 CB B8 46
02 3E 1D AF C4 F4 BF BE 73 2E 84 58 84 D9 A1 E3
```

**Searched for known magic numbers**:
- Mach-O 64-bit (0xFEEDFACF): NOT FOUND
- Mach-O 32-bit (0xFEEDFACE): NOT FOUND
- LZFSE (bvx2/bvx$/bvxn): NOT FOUND
- LZMA (0x5D 0x00 0x00): NOT FOUND
- complzss: NOT FOUND

**Fact**: Payload does not contain recognizable binary format or compression signature.

---

## Observation 5: File Size Analysis

**Observed sizes**:
- im4p container: 444,887 bytes
- Extracted payload: 56,454 bytes
- Ratio: 12.7% of container is payload
- Remaining 388,433 bytes (87.3%): metadata/signature

**Comparison to expected iBoot size**:
- If payload were compressed Mach-O, uncompressed might be 200-500 KB
- If payload were encrypted Mach-O, size matches typical iBoot (~50-60 KB compressed)
- Large metadata overhead suggests extensive signature/certificate chain

**Fact**: Payload is much smaller than container, with large metadata overhead.

---

## Observation 6: Attempted Execution

**Method**: Attempted to load iBoot.j274.bin into emulator

**NOT PERFORMED**: Payload is not executable binary.

**Reason**: Unknown magic number indicates encrypted or obfuscated format.

---

## Observation 7: Documentation Cross-Reference

**Checked**: docs/collected/device-tree/apple-device-tree-adt.md

**Statement found**:
> "Preboot volume DeviceTree.{model}.im4p (needs img4tool to extract)."

**Interpretation**: Tool called "img4tool" is referenced for extraction.

**Fact**: Project documentation acknowledges img4tool is required tool.

---

## Observation 8: Tool Availability

**Method**: Searched project directories, checked system

**Observed**:
- img4tool: NOT FOUND in project
- img4tool: NOT FOUND in system PATH
- WSL environment: encountered errors (unrelated to tool search)

**Fact**: img4tool is not available in current environment.

---

## Summary of Factual Observations

1. iBoot is distributed in IMG4 (.im4p) format
2. IMG4 is ASN.1 DER encoded
3. Payload size is ~13% of container
4. Payload magic is 0xE3A64E43 (unknown format)
5. Payload is not Mach-O
6. Payload is not standard compression
7. Documentation references img4tool for extraction
8. img4tool is not available

---

## Assumptions Invalidated

**ASSUMPTION**: iBoot binaries can be extracted with standard tools  
**FACT**: iBoot binaries require specialized tool (img4tool) or are encrypted

---

## Questions Raised (NOT ANSWERED)

1. Is payload encrypted or encoded?
2. What is 0xE3A64E43 magic number?
3. Where to obtain img4tool?
4. Can iBoot be decrypted without hardware?
5. Are there alternative iBoot sources?

---

**End of Observations**
