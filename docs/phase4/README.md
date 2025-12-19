# Phase 4: Minimal Boot Environment Construction

**Status**: Phase 4a Complete  
**Current Phase**: 4a (ADT Generation)  
**Next Phase**: 4b (Boot Chain Integration)

---

## Phase Overview

Phase 4 constructs the MINIMAL components required to:
1. Pass ADT format validation
2. Progress past ADT parsing
3. Fail at the NEXT boot stage (not ADT-related)

**Design Philosophy**: Controlled failure engineering, NOT Apple emulation.

---

## Phase 4 Structure

### Phase 4a: Minimal ADT Generation ✓ COMPLETE

**Objective**: Create structurally valid ADT binary

**Deliverables**:
- ADT binary generator (Python)
- Minimal ADT variants (96-200 bytes)
- Structural validation tools
- Format compliance verification

**Report**: [phase4a-report.md](./phase4a-report.md)

**Key Artifacts**:
- `scripts/phase4/minimal_adt_gen.py` - Generator tool
- `output/minimal_adt.bin` - Absolute minimal ADT
- `output/minimal_adt_with_placeholders.bin` - With chosen/memory nodes

**Result**: ADT is structurally valid per docs/models/adt-structure.md

---

### Phase 4b: Boot Chain Integration (BLOCKED)

**Objective**: Integrate minimal ADT into boot environment

**Prerequisites**:
- Boot environment (QEMU or hardware)
- boot_args structure knowledge
- Entry point configuration
- Serial output capture

**Blocked By**:
- No boot environment configured
- No boot.efi/iBoot test harness
- No mechanism to pass ADT to boot chain

**Planned Deliverables**:
- Boot argument structure implementation
- ADT memory layout configuration
- Boot entry point stub
- Error capture infrastructure

---

### Phase 4c: Iterative Property Addition (NOT STARTED)

**Objective**: Add ONLY properties that boot chain explicitly requires

**Method**:
1. Boot with minimal ADT
2. Capture failure message
3. Add ONLY the missing node/property
4. Repeat until non-ADT failure

**Stop Condition**: Failure unrelated to ADT content

---

## Current Status

### Completed ✓
- [x] ADT binary format specification (Phase 3d-1)
- [x] Minimal ADT generator implementation
- [x] Structural validation
- [x] Format compliance verification

### In Progress
- [ ] Boot environment setup

### Blocked
- [ ] Boot chain integration (waiting on environment)
- [ ] Real boot testing (waiting on integration)
- [ ] Iterative property addition (waiting on boot tests)

---

## Usage

### Generate Minimal ADT

```bash
# Absolute minimal (root node only)
python scripts/phase4/minimal_adt_gen.py output/minimal_adt.bin

# With placeholder nodes (chosen, memory)
python scripts/phase4/minimal_adt_gen.py output/minimal_adt_with_placeholders.bin --with-placeholders
```

### Verify ADT Structure

```bash
# Validate binary format
python scripts/phase4/verify_adt.py output/minimal_adt.bin
```

**Note**: m1n1 parser validation will fail due to missing `/arm-io/pmgr`. This is expected and does NOT indicate format errors.

### Inspect Binary

```powershell
# View hex dump (Windows)
Format-Hex -Path output\minimal_adt.bin -Count 96

# Linux/macOS
hexdump -C output/minimal_adt.bin
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| [phase4a-report.md](./phase4a-report.md) | ADT generation phase report |
| [../models/adt-structure.md](../models/adt-structure.md) | Binary format specification |

---

## Next Steps

### Immediate (Phase 4b Prerequisites)

1. **Determine boot environment**:
   - QEMU with Apple Silicon support?
   - Real M1 hardware with m1n1?
   - Bare metal ARM64 with custom bootloader?

2. **Understand boot_args structure**:
   - How to pass ADT pointer
   - How to pass ADT size
   - Entry point requirements

3. **Set up debugging**:
   - Serial console output
   - Early boot logging
   - Failure message capture

### Phase 4b Execution

Once environment is ready:
1. Implement boot_args packer
2. Load minimal ADT into memory
3. Jump to boot entry point
4. Capture first failure

### Expected First Failure

**Most Likely**: Missing required nodes/properties  
**Examples**:
- "Missing /chosen node"
- "Missing boot-args property"
- "Invalid memory configuration"

**Response**: Add ONLY what's explicitly required, nothing more.

---

## Design Constraints (Reminder)

**DO**:
- ✓ Create structurally valid ADT
- ✓ Add only explicitly required elements
- ✓ Document all omissions
- ✓ Stop at first non-ADT failure

**DO NOT**:
- ✗ Guess semantic requirements
- ✗ Add "helpful" properties
- ✗ Try to match real Apple DTs
- ✗ Aim for successful boot

**Success Metric**: Progress PAST ADT parsing to next failure stage.

---

## References

### Internal
- [Phase 3d-1: ADT Structure Extraction](../models/adt-structure.md)
- [Emulator Responsibility](../constraints/emulator-responsibility.md)
- [Unknowns Tracking](../constraints/unknowns.md)

### External
- m1n1 ADT parser: `local_storage/m1n1/proxyclient/m1n1/adt.py`
- m1n1 Rust ADT: `local_storage/m1n1/rust/src/adt.rs`
- Asahi Linux ADT docs: `docs/external/Asahi Linux Docs/docs/fw/adt.md`

---

## END OF PHASE 4 README
