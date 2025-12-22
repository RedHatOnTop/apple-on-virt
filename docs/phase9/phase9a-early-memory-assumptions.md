# Phase 9a: Early Kernel Memory Assumptions — Observation (NULL dereference boundary)

## Scope and constraints
This phase is **observation only**.
- No new MMU/VA acceptance rules were added.
- No hardware devices were modified.

The analysis below is restricted to what is directly evidenced by logs and the executed payload source.

## Observed facts (evidence-backed)

### Fault boundary
From `output/phase8/phase8b_validate_run1.qemu.log` (also identical in run2; hashes match):
- Exception: `Taking exception 4 [Data Abort]`
- `ESR = 0x25/0x96000010`
- `FAR = 0x0`
- `ELR = 0x8010000d8`

Disassembly around ELR (same log, `-d in_asm`):
- `0x8010000d4: movz x6, #0`
- `0x8010000d8: ldr  x7, [x6]`  ⟵ faults with `FAR=0x0`

Therefore:
- **`x6` is set to zero immediately prior to the abort**, and the abort is a **load from VA 0** (NULL dereference).

### Where x6 was set
The instruction stream shows it explicitly:
- `movz x6, #0` at `0x8010000d4`.

There is no preceding computation producing a meaningful address in `x6` at this point; it is an explicit constant assignment.

### What code is executing at the fault
The executed blob at this point is the **Phase 8a probe payload**, not a macOS kernel image.

Evidence:
- The log markers printed are those emitted by the probe (`8A`, `P1`, `P2`, `DA`).
- The probe source (`scripts/phase8/phase8a_mmu_acceptance_probe.s`) contains exactly the sequence:
  - high-VA load (expected to be accepted) and then
  - an intentional out-of-contract access:
    - `movz x6, #0`
    - `ldr x7, [x6]`

## Inferred intent (clearly labeled inference)

### Semantic role of x6 at the fault
**Inference:** In this specific failure, `x6` does not represent a kernel structure pointer (per-CPU base, global anchor, allocator state, etc.). It is explicitly set to 0 by the probe as a deliberate negative test.

Rationale:
- The probe comment explicitly labels this as an “Out-of-contract access: should fault and move FAR/ELR”.
- The register is not populated from boot args, ADT, sysregs, or any memory load; it is set directly to an immediate constant.

### What “memory assumption” is actually being tested
**Inference:** The boundary demonstrates a minimal requirement: **address 0 is not (and should not be) implicitly accepted by the Phase 8a layer**, i.e. the acceptance layer is not a blanket “all VA works” mechanism.

## Classification conclusion (Phase 9a)
The `FAR=0x0` abort is classified as:
- **A deliberate NULL dereference / out-of-contract access originating from the Phase 8a probe**, not evidence of a macOS early-kernel memory structure expectation.

## Stop / limitation statement
Because the NULL dereference is probe-induced, **it does not provide evidence to classify macOS kernel-side memory assumptions** at that point.

To observe genuine early-kernel assumptions, a future phase would need evidence from executing the actual kernel path (or a probe that instruments the kernel’s real pointers without fabricating them). This phase does not invent or guess those structures.
