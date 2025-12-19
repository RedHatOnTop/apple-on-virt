# Device Tree Observations - Phase 3b

**Question**: What form of device tree or platform description is actually used?

---

## Observation 1: ADT Format (Apple Device Tree)

**Source**: `docs/external/Asahi Linux Docs/docs/fw/adt.md`  
**Extracted**: `docs/collected/device-tree/apple-device-tree-adt.md`

**Observed Fact**:
```
Format: Binary format "very similar to, but different from" Open Firmware standard
Structure: Hierarchy of nodes with untyped byte array properties
Byte Order: Mixed (reader/producer defined), NOT big-endian like Linux FDT
Content: Hardware description, serial numbers, WiFi keys
```

**Context**: Apple Device Tree (ADT) is the platform description format used on real Apple Silicon.

**Confidence**: HIGH
- Asahi Linux successfully parses ADT from real hardware
- m1n1 includes `adt.py` parser
- Extractable from running macOS via `ioreg -p IODeviceTree`

---

## Observation 2: ADT Source and Modification

**Source**: `docs/collected/device-tree/apple-device-tree-adt.md`

**Observed Fact**:
```
"Missing details filled in by iBoot during boot"

Source files: DeviceTree.{model}.im4p on Preboot volume
Final ADT: Modified by iBoot before passing to kernel (NOT static file)
```

**Context**: ADT is dynamically constructed during boot, not a static artifact.

**Confidence**: HIGH
- Explicit statement in Asahi documentation
- Explains why static extraction is insufficient

---

## Observation 3: ADT Memory Location

**Source**: `docs/collected/boot-chain/macho-boot-interface.md`

**Observed Fact**:
```
Device Tree location in physical memory:
- Within Kernel Image Region
- After kASLR slide gap
- At /chosen/memory-map.DeviceTree

Passed to kernel via boot_args structure in x0
```

**Context**: ADT is placed in memory by iBoot before kernel entry.

**Confidence**: HIGH
- Part of documented boot protocol
- m1n1 uses this mechanism

---

## Observation 4: m1n1 Device Tree Handling

**Source**: `docs/external/Asahi Linux Docs/docs/sw/m1n1-user-guide.md`

**Observed Fact**:
```
m1n1 can:
- Load embedded Device Trees (FDTs) as payloads
- Perform automatic DT selection based on platform
- Pass FDTs to Linux kernel

Format: FDT (Flattened Device Tree) for Linux, NOT ADT
```

**Context**: m1n1 bridges Apple boot ecosystem to Linux ecosystem by converting/providing FDT.

**Confidence**: HIGH
- m1n1 successfully boots Linux on Apple Silicon
- Uses FDT for Linux, receives ADT from iBoot

---

## Observation 5: ADT Extraction Methods

**Source**: `docs/collected/device-tree/apple-device-tree-adt.md`

**Observed Fact**:
```
Methods to view/extract ADT:
1. m1n1 adt.py tool
2. macOS: ioreg -p IODeviceTree
3. Preboot volume: DeviceTree.{model}.im4p (requires img4tool)
```

**Context**: ADT is observable on running systems via multiple methods.

**Confidence**: HIGH
- Multiple validated extraction paths documented

---

## Observation 6: FDT vs ADT Distinction

**Source**: `docs/external/Asahi Linux Docs/docs/sw/m1n1-user-guide.md`

**Observed Fact**:
```
m1n1 receives: ADT from iBoot (Apple format)
m1n1 provides: FDT to Linux (standard format)

m1n1 acts as format bridge
```

**Context**: Two distinct device tree formats in use:
- ADT: Apple → iBoot → macOS/m1n1
- FDT: m1n1 → Linux

**Confidence**: HIGH
- Documented conversion performed by m1n1
- Successful Linux boot proves FDT compatibility

---

## UNKNOWN

### ADT Binary Format Specification

**Question**: What is the exact binary structure of ADT?

**Evidence**:
- "Similar to but different from Open Firmware"
- No explicit format specification in documentation
- Parser exists (adt.py) but format details: UNKNOWN

### Required ADT Properties

**Question**: Which ADT properties are mandatory for boot?

**Evidence**:
- Hardware description included
- Serial numbers included
- WiFi keys included
- Minimum required set: UNKNOWN

### ADT Property Byte Order Rules

**Question**: What determines byte order for each property?

**Evidence**:
- "Mixed" byte order (not uniform)
- "Reader/producer defined"
- Specific rules: UNKNOWN

### Dynamic Modifications by iBoot

**Question**: What exactly does iBoot add/modify in ADT?

**Evidence**:
- "Missing details filled in by iBoot"
- Static file insufficient
- Specific modifications: UNKNOWN

---

## Summary

**CONFIRMED**: 
1. Apple Silicon uses ADT (Apple Device Tree), NOT FDT
2. ADT is binary format, different from Open Firmware/FDT
3. ADT is dynamically modified by iBoot during boot
4. ADT location passed in boot_args structure via x0

**CONFIDENCE**: HIGH - Multiple sources, validated by m1n1 real hardware operation

**PREVIOUSLY UNKNOWN → NOW OBSERVED**:
- Device tree format: ADT (not FDT)
- ADT is modified dynamically (not static file)
- m1n1 bridges ADT→FDT for Linux compatibility

**CRITICAL UNKNOWN**: Exact ADT binary format specification

---

**Observation Date**: 2025-12-18  
**Sources**: Asahi Linux Docs (adt.md, macho-boot-protocol.md, m1n1-user-guide.md)  
**Validation**: m1n1 successfully parses ADT and boots Linux on real Apple Silicon
