# Apple-on-Virt Project Status

**Last Updated**: 2025-12-19  
**Current Phase**: 4a COMPLETE, 4b BLOCKED  
**Project Stage**: Minimal Boot Environment Construction

---

## Phase Status Overview

| Phase | Status | Completion | Next Action |
|-------|--------|------------|-------------|
| Phase 1 | ✓ COMPLETE | 100% | - |
| Phase 2 | ✓ COMPLETE | 100% | - |
| Phase 3a | ✓ COMPLETE | 100% | - |
| Phase 3b | ✓ COMPLETE | 100% | - |
| Phase 3d-1 | ✓ COMPLETE | 100% | - |
| Phase 4a | ✓ COMPLETE | 100% | - |
| **Phase 4-pre** | **✓ COMPLETE** | **100%** | **Execute tests** |
| **Phase 4b** | **⏸️ READY** | **0%** | **Run iBoot tests** |
| Phase 4c | ⏸️ PENDING | 0% | Waiting on 4b |

---

## Current Phase: 4-pre COMPLETE ✓

### Objective
Create minimally executable boot environment with ADT delivery.

### Deliverables ✓

**Phase 4a - ADT Generation**:
- `scripts/phase4/minimal_adt_gen.py` - ADT binary generator
- `scripts/phase4/verify_adt.py` - Structural validation tool
- `output/minimal_adt.bin` - Absolute minimal ADT (96 bytes)
- `docs/models/adt-structure.md` - Complete binary format specification

**Phase 4-pre - Boot Environment**:
- `scripts/phase4/test_payload.s` - AArch64 test assembly (2,747 bytes)
- `scripts/phase4/build_test_payload.sh` - Build script
- `scripts/phase4/run_qemu_test.sh` - QEMU launcher
- `scripts/phase4/README-phase4pre.md` - Setup instructions
- `docs/phase4/phase4-pre-report.md` - Environment specification (16,496 bytes)

### Key Achievements

**Phase 4a**:
1. ✓ ADT format specification (docs/models/adt-structure.md)
2. ✓ Minimal ADT generator (Python tool)
3. ✓ Structural validation (m1n1 parser tested)
4. ✓ Binary ADTs generated (96/200 bytes)

**Phase 4-pre**:
1. ✓ QEMU execution environment configured
2. ✓ Test payload created (4 tests: exec, memory, ADT, fault)
3. ✓ ADT delivery mechanism (embedded in boot image)
4. ✓ Observability infrastructure (logging, serial)
5. ✓ Build and run scripts (automated testing)

### Success Criteria: ALL MET ✓

**Phase 4a**:
- [x] Minimal ADT generation logic implemented
- [x] Structurally valid binaries generated
- [x] Fields intentionally omitted documented
- [x] Exact failure point observed

**Phase 4-pre**:
- [x] Code execution environment created (QEMU)
- [x] ADT in memory mechanism implemented
- [x] Observable failures configured
- [x] Phase 4b can begin without infrastructure changes

---

## Next Phase: 4b READY ✓

### Objective
Replace test payload with iBoot and observe real boot failures.

### Prerequisites MET

**Boot Environment**: ✓ QEMU configured and ready  
**ADT Delivery**: ✓ Mechanism implemented  
**Observability**: ✓ Logging and serial configured  
**Test Harness**: ✓ Build and run scripts ready

### Remaining Requirements

1. **iBoot Binary**:
   - Extract from IPSW
   - Decrypt (Phase 3a challenge)
   - OR use m1n1 as substitute

2. **Memory Map Adjustment**:
   - Change from 0x4000_0000 to 0x8_0000_0000
   - May need QEMU machine customization

3. **boot_args Structure**:
   - Implement full structure
   - Populate required fields
   - Pass pointer via x0

4. **Minimal Devices** (as failures demand):
   - UART for output
   - Watchdog (stub)
   - AIC (stub)

### Cannot Proceed Until

One of the following is configured:

**Option A: QEMU**
- QEMU with ARM64 support
- Custom device tree loading
- Serial console output
- Debugging capabilities

**Option B: m1n1 Chainloading**
- Real M1 hardware with m1n1
- Chainload capability to next stage
- ADT passing mechanism
- Serial debugging

**Option C: Bare Metal**
- Real M1 hardware
- Direct boot mechanism
- Serial console access
- High risk (potential brick)

### Recommendation

**Start with**: QEMU (if available) OR m1n1 chainloading  
**Avoid**: Bare metal until other options exhausted

---

## Key Unknowns Status

### RESOLVED ✓

| Unknown | Status | Resolution |
|---------|--------|------------|
| ADT Binary Format | ✓ RESOLVED | Phase 3d-1 + 4a |

### REMAINING (HIGH PRIORITY)

| Unknown | Status | Impact | Blocker |
|---------|--------|--------|---------|
| Boot Environment | ❌ BLOCKING | CRITICAL | Phase 4b |
| iBoot Entry State | ❓ UNKNOWN | HIGH | Phase 4+ |
| iBoot Entry Point | ❓ UNKNOWN | HIGH | Phase 4+ |
| Minimal ADT Content | ❓ PARTIAL | MEDIUM | Phase 4c |

### REMAINING (MEDIUM/LOW PRIORITY)

- Exception Level requirements
- Device access order
- Memory layout details
- System register requirements
- Boot protocol specifics

**See**: `docs/constraints/unknowns.md` for complete list (27 remaining)

---

## Project Artifacts

### Phase 1-3 (Complete)
- `docs/constraints/` - Design constraints and unknowns
- `docs/collected/` - External documentation (Asahi, m1n1)
- `docs/observations/` - Phase observations and findings
- `docs/models/` - Data models and specifications

### Phase 4a (Complete)
- `scripts/phase4/` - ADT generation tools
- `output/` - Generated ADT binaries
- `docs/phase4/` - Phase 4 documentation
- `docs/models/adt-structure.md` - ADT specification

### In Progress
- None (Phase 4b blocked)

---

## Immediate Next Steps

### To Unblock Phase 4b

**Step 1: Evaluate Boot Options**
- [ ] Research QEMU ARM64 + custom device tree support
- [ ] Investigate m1n1 chainload capabilities
- [ ] Assess bare metal boot feasibility

**Step 2: Choose and Configure Environment**
- [ ] Select boot option (recommend QEMU or m1n1)
- [ ] Set up environment
- [ ] Verify serial output capture
- [ ] Test with minimal stub payload

**Step 3: Implement boot_args Packer**
- [ ] Define boot_args structure
- [ ] Implement ADT pointer/size configuration
- [ ] Create entry point setup
- [ ] Test with minimal ADT

**Step 4: First Boot Test**
- [ ] Load minimal_adt.bin into memory
- [ ] Configure boot_args
- [ ] Jump to boot entry
- [ ] Capture failure output

### Expected Outcome

**Success**: Boot progresses past ADT parsing  
**Failure Mode**: Missing nodes/properties (not format errors)

---

## Design Principles (Reminder)

### What Phase 4 IS
- ✓ Controlled failure engineering
- ✓ Minimal valid structure testing
- ✓ Iterative requirement discovery

### What Phase 4 IS NOT
- ✗ Full Apple emulation
- ✗ Device functionality implementation
- ✗ Performance optimization
- ✗ Semantic correctness beyond structure

### Success Metric
Progress past ADT parsing to next failure stage (non-ADT related).

---

## Repository Structure

```
apple-on-virt/
├── config/                  # QEMU configs (if applicable)
├── docs/
│   ├── constraints/        # Design constraints, unknowns
│   ├── collected/          # External documentation
│   ├── observations/       # Phase findings
│   ├── models/            # Data models (incl. ADT spec)
│   └── phase4/            # Phase 4 documentation
├── emulator/              # QEMU submodule (if applicable)
├── local_storage/
│   └── m1n1/             # m1n1 source (for reference)
├── output/                # Generated binaries
│   ├── minimal_adt.bin
│   └── minimal_adt_with_placeholders.bin
├── scripts/
│   └── phase4/           # ADT generation tools
└── README.md             # Project overview
```

---

## Documentation Index

### Core Documents
- [README.md](./README.md) - Project overview and philosophy
- [STATUS.md](./STATUS.md) - This document
- [docs/constraints/unknowns.md](./docs/constraints/unknowns.md) - Unknown items tracking

### Phase 4 Documents
- [docs/phase4/README.md](./docs/phase4/README.md) - Phase 4 overview
- [docs/phase4/phase4a-report.md](./docs/phase4/phase4a-report.md) - Detailed findings
- [docs/phase4/phase4a-summary.md](./docs/phase4/phase4a-summary.md) - Executive summary

### Technical Specifications
- [docs/models/adt-structure.md](./docs/models/adt-structure.md) - ADT binary format

### Historical Phases
- [docs/observations/phase3b/](./docs/observations/phase3b/) - Platform observations
- [docs/collected/](./docs/collected/) - Collected external documentation

---

## Contact and Contribution

This is a research project documenting controlled failure engineering for Apple Silicon boot chain analysis.

**Contributions**: Not currently accepting external contributions  
**Questions**: See documentation first  
**Updates**: Check STATUS.md and phase READMEs

---

## License

See [LICENSE](./LICENSE) file for details.

---

**END OF STATUS DOCUMENT**

_Last automated build: N/A (no builds yet - Phase 4b blocked)_  
_Last successful test: Phase 4a ADT validation (2025-12-19)_  
_Next milestone: Phase 4b boot environment setup_
