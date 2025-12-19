# DRAM Observations - Phase 3b

**Question**: Where does DRAM appear to be mapped on real Apple Silicon?

---

## Observation 1: DRAM Base Address

**Source**: `docs/external/Asahi Linux Docs/docs/hw/soc/memmap.md`  
**Extracted**: `docs/collected/memory-model/soc-address-map.md`

**Observed Fact**:
```
DRAM base address: 0x8_0000_0000
Size: 8 GB or 16 GB (model dependent)
```

**Context**: M1 (T8103) memory map from Asahi Linux hardware probing.

**Confidence**: HIGH
- Multiple sources confirm this address
- Asahi Linux documentation based on real hardware measurement
- Consistent across M1 hardware

---

## Observation 2: Boot Protocol DRAM Reference

**Source**: `docs/external/Asahi Linux Docs/docs/fw/macho-boot-protocol.md`  
**Extracted**: `docs/collected/boot-chain/macho-boot-interface.md`

**Observed Fact**:
```
"Start of RAM: 0x8_0000_0000"

Memory Layout (Physical):
- Bottom Range: 0x8_0000_0000 to boot_args->phys_base
- Kernel Image Region: Starts at boot_args->phys_base
- Free Memory: boot_args->top_of_kdata to boot_args->mem_size
- Top Range: Above 0x8_0000_0000 + boot_args->mem_size_actual
```

**Context**: XNU boot protocol documentation describing how iBoot lays out memory before kernel entry.

**Confidence**: HIGH
- Documented boot protocol
- Used by m1n1 successfully
- Describes real hardware behavior

---

## Observation 3: m1n1 Boot Entry Point

**Source**: `docs/external/Asahi Linux Docs/docs/sw/m1n1-dev-guide.md`

**Observed Fact**:
```
"The entry point is at 0x800 with translation disabled and the physical 
address to the XNU boot_args structure in r0."

"Raw binaries can be loaded anywhere (at 16K aligned offsets)."
```

**Context**: m1n1 bootloader entry point behavior when loaded by iBoot.

**Confidence**: HIGH
- m1n1 successfully boots on real hardware
- Describes tested behavior

---

## Observation 4: Physical vs Virtual Addressing

**Source**: `docs/collected/boot-chain/macho-boot-interface.md`

**Observed Fact**:
```
"Physical Addresses: The only true addresses for the emulator in this phase."

MMU: OFF at entry

Virtual addresses computed as:
vaddr = paddr + ba.virt_base - ba.phys_base
```

**Context**: Boot protocol specifies MMU is disabled when kernel entry occurs.

**Confidence**: HIGH
- Explicit statement in boot protocol
- Consistent with early boot requirements

---

## UNKNOWN

### DRAM Size Determination

**Question**: How is actual DRAM size communicated?

**Evidence**: 
- Documentation mentions 8 GB or 16 GB variants
- `boot_args->mem_size` and `boot_args->mem_size_actual` fields exist
- Exact mechanism for detection: UNKNOWN

### Lower Memory Region

**Question**: What exists below 0x8_0000_0000?

**Evidence**:
- No explicit statement found
- Memory map shows MMIO devices in 0x2_xxxx_xxxx range
- Lower regions: UNKNOWN

### DRAM Alignment Requirements

**Question**: Are there alignment requirements for regions within DRAM?

**Evidence**:
- "16K aligned offsets" mentioned for m1n1 loading
- Kernel/payload alignment: UNKNOWN beyond 16K hint

---

## Summary

**CONFIRMED**: DRAM base address is `0x8_0000_0000` on M1 hardware.

**CONFIDENCE**: HIGH - Multiple independent sources, real hardware validation via m1n1.

**PREVIOUSLY UNKNOWN → NOW OBSERVED**: 
- Conflict resolved: Current emulator uses 0x40000000, real hardware uses 0x8_0000_0000

---

**Observation Date**: 2025-12-18  
**Sources**: Asahi Linux Docs (memmap.md, macho-boot-protocol.md, m1n1-dev-guide.md)  
**Validation**: m1n1 boots successfully on real Apple Silicon using these addresses
