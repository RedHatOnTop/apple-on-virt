# Phase 10d — Boot-Chain → Kernel Address Contract Reconstruction (Static)

## Scope
Static only (no execution, no emulator changes, no slide guessing).

## Evidence inputs
Kernel-side (static):
- `output/phase10/phase10a/summary.txt` (kernelcache Mach-O entry + VA span)
- `output/phase10/phase10a/segments.csv` (segment vmaddrs)
- `docs/phase10/phase10b-kernel-relocation-semantics.md` (kernelcache has `LC_DYLD_CHAINED_FIXUPS`)

Boot-chain-side (static iBoot Stage2 vma2):
- Full disasm: `output/phase10/phase10c/iBoot.vma2.payload.disasm.txt` (pseudo-addresses == file offsets)
- Key excerpts copied for convenience:
  - `output/phase10/phase10d/excerpt_mach_header_labels.txt`
  - `output/phase10/phase10d/excerpt_kernelcache_errors.txt`
  - `output/phase10/phase10d/excerpt_load_kernel_start.txt`
  - `output/phase10/phase10d/excerpt_path_system_kernelcache.txt`
  - `output/phase10/phase10d/excerpt_path_boot_kernelcache.txt`
  - `output/phase10/phase10d/entry_like_eret_context.txt`

---

## Q1: What address does the boot chain believe the kernel entry PC to be?

### Kernel artifact provides an absolute entry VA
From `output/phase10/phase10a/summary.txt`:
- `entry_pc = 0xfffffe0007d44528`
- entry is inside `__TEXT_EXEC` (also in that summary).

### Boot-chain: proven handoff *primitive* uses ELR_EL1 + ERET
A clear “restore EL1 context and `eret`” sequence exists at:
- `0x00010188..0x000101f4` (see `output/phase10/phase10d/entry_like_eret_context.txt`)

Key instructions (verbatim):
- `0x00010188: ldr x0, [sp, #0x108]`
- `0x00010190: msr elr_el1, x0`
- `0x00010194: ldr w1, [sp, #0x100]`
- `0x00010198: msr spsr_el1, x1`
- restores x0..x30 from stack, adjusts `sp_el0`, then:
- `0x000101f4: eret`

**What is proven:** iBoot has a mechanism to transfer control by programming `ELR_EL1` from a memory slot and then performing `eret`.

**UNKNOWN (not provable from this artifact slice):** whether the value loaded from `[sp+0x108]` in this routine is the kernel entry VA specifically.

### Symbolic expression (evidence-backed forms only)
Because we cannot prove which routine constitutes the *final* boot→kernel handoff, we can only provide evidence-backed candidate forms:

1) **If** iBoot uses the kernelcache’s `LC_UNIXTHREAD.pc` *directly*:
- `kernel_entry_runtime_va = LC_UNIXTHREAD.pc`  (no slide)

2) **If** iBoot rebases/slides and then uses a stored EL1 context frame:
- `kernel_entry_runtime_va = *(ctx_frame + ELR_EL1_field)`
  - evidenced by `ldr x0, [sp, #0x108]; msr elr_el1, x0; eret`

3) **If** iBoot computes a delta and applies it to the entry:
- `kernel_entry_runtime_va = LC_UNIXTHREAD.pc + delta`
  - evidence that a delta is computed/stored exists (`0x00008b5c..0x00008b64` stores a subtraction result), but its semantic identity as “kernel slide” is **UNKNOWN**.

---

## Q2: What address assumptions are enforced at the handoff boundary?

### Proven boot-chain address constraints (placement arithmetic)
In `excerpt_mach_header_labels.txt`, iBoot enforces / computes address-like values with specific alignment and size granularity:

1) **16KB alignment**
- `0x000089d0: mov w8, #0x3fff`
- `0x000089d8: and x9, x8, #0xffffffffffffc000`
- later repeated: `0x00008ac4..0x00008acc` aligns `x26` similarly.

2) **2MB granule growth**
- `0x000089e8: mov w8, #0x200000`
- `0x000089f0: lsl x8, x8, #1`
- `0x000089f8: b.lo #0x89ec` (loop until granule >= `x28`)

3) **Bounds checks vs a limit**
- `0x00008ae0: cmp x8, x25`
- `0x00008ae4: b.hs #0x9090`

**Interpretation limits:** These are arithmetic+control-flow facts only; “what exactly is being placed” (kernel physical base vs another region) is not proven.

### Register expectations at handoff
From the `eret` restore stub (`0x0001019c..0x000101d8`), iBoot can restore **all** general-purpose registers x0–x30 from a memory frame before `eret`.

**UNKNOWN:** which registers are populated with boot arguments for kernel entry (x0–xN roles) because the call path that populates the frame is not proven.

### TTBR/MMU assumptions
From `entry_like_eret_context.txt` around `0x0000f200..0x0000f340`, iBoot contains explicit sysreg programming of EL1 state (e.g. `msr sctlr_el1`, `msr tcr_el1`, `msr ttbr0_el1`, `msr mair_el1`).

**UNKNOWN:** the exact configuration used at kernel handoff (which values, and whether TTBR1 is used) is not tied to the kernel entry path in this phase.

---

## Q3: Is the kernel treated as position-independent at entry?

Kernelcache-side evidence (Phase 10b):
- kernelcache contains `LC_DYLD_CHAINED_FIXUPS` and a decoded fixups header.

Boot-chain-side evidence (iBoot vma2):
- iBoot clearly recognizes kernel Mach-O headers via label strings:
  - `Kernel-mach_header` referenced at `0x00008b7c` (`adr x0, #0x4f3e1`)
  - `AuxKC-mach_header` referenced at `0x00008c48` (`adr x0, #0x4f3fa`)
- A stored delta exists: `0x00008b5c..0x00008b64`.

**Cannot be proven (STOP boundary):**
- We do not have a proven call site showing dyld chained fixups application to the kernelcache prior to handoff.
- Therefore: **Cannot be proven** whether iBoot assumes “already-final VA” vs “relocated VA”.

Verdict for Q3: **Cannot be proven** from this static artifact set.

---

## Q4: Minimum address model an emulator must eventually satisfy (declarative)
This is a *property list* derived from static evidence only.

Kernel-side required property for first instruction fetch:
- The kernel’s entry VA (from `LC_UNIXTHREAD`) must be translatable to the physical location containing `__TEXT_EXEC` bytes:
  - `entry_pc = 0xfffffe0007d44528` (Phase 10a)
  - `entry_pc ∈ __TEXT_EXEC` (Phase 10a)

Boot-chain-side required placement properties (if mirroring iBoot behavior):
- Candidate placement bases are **16KB-aligned** (mask `0xffffffffffffc000`).
- Placement granularity selection starts at **2MB** (`0x200000`) and may double.

Explicit unknowns:
- Whether the runtime entry VA equals the absolute `LC_UNIXTHREAD.pc` or a rebased value.
- Whether iBoot transitions with a particular TTBR split and/or expects a high-VA kernel mapping at entry.

---

## Phase classification
**B) Entry contract partially reconstructible, boot-feasible with constraints.**

Justification:
- We can prove alignment/granularity constraints and the existence of an ELR_EL1+ERET handoff primitive.
- We cannot prove the final `kernel_entry_runtime_va` computation or register contract without additional boot-chain artifacts or execution.
