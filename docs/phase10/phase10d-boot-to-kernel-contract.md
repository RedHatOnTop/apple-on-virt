# Phase 10d: Boot-Chain → Kernel Entry Contract Reconstruction (Static, Boot-Feasible)

## Scope / hard constraints
Static-only reconstruction from bytes and metadata.
- No QEMU execution
- No kernel jump
- No slide/TTBR guessing
- No emulator changes

All iBoot instruction addresses below are **pseudo-addresses equal to file offsets** in `output/phase10/phase10c/iBoot.vma2.payload.disasm.txt` (disassembly base=0).

---

## Evidence table (primary)
| Domain | Artifact | Evidence used |
|---|---|---|
| Kernel | `output/phase10/phase10a/summary.txt` | `LC_UNIXTHREAD` fields (pc/sp/cpsr), VA span, `entry_in` segment |
| Kernel | `output/phase10/phase10a/segments.csv` | segment vmaddr/vmsize contiguity (Phase10a result) |
| Kernel | Phase 10b report | kernelcache contains `LC_DYLD_CHAINED_FIXUPS` (static presence) |
| Boot chain | `output/phase10/phase10c/iBoot.vma2.payload.disasm.txt` | placement arithmetic, mach_header handling call sites, EL1 context restore + `eret` primitives |
| Boot chain | `output/phase10/phase10d/entry_like_eret_context.txt` | concrete `msr elr_el1` + `eret` sequences |

---

## 1) Kernel-side expectations (static only)

### 1.1 Entry metadata source (proven)
From `output/phase10/phase10a/summary.txt`:
- `mach_o_filetype=12` (MH_FILESET)
- Entry metadata is present as `LC_UNIXTHREAD` fields:
  - `entry_pc=0xfffffe0007d44528`
  - `entry_sp=0x0`
  - `entry_cpsr=0x0`

No entrypoint is guessed.

### 1.2 Entry PC containment (proven)
From `summary.txt`:
- `entry_in=('__TEXT_EXEC', 869672)`

So `entry_pc ∈ __TEXT_EXEC` (provably, from Mach-O metadata parse).

### 1.3 VA span + contiguity (proven)
From `summary.txt`:
- `min_va=0xfffffe0007004000`
- `max_va=0xfffffe000d0cc000`
- `va_span=0x60c8000 (101482496 dec)`

This is a contiguous *observed* kernel VM range (Phase10a extraction result). No claim is made about runtime mapping beyond “these are the vmaddrs in the fileset”.

### 1.4 What the kernel artifact does *not* encode (explicit)
From the same metadata, and by absence of fields:
- No slide value is encoded as a single scalar in `LC_UNIXTHREAD` (pc is absolute; no separate “slide” field exists in that command).
- No TTBR configuration is encoded.
- No runtime SP is encoded (entry_sp is `0x0`).
- No x0–xN register contract is encoded.

---

## 2) Boot-chain observable guarantees (static)

### 2.1 Pre-handoff steps (provable)
These are directly observed in `iBoot.vma2.payload.disasm.txt` excerpts:

1) **Kernelcache path selection exists** (string-address xrefs)
- `/System/Library/Caches/com.apple.kernelcaches/kernelcache` via:
  - `0x00002b6c: adr x1, #0x4e8ce`
- `/boot/kernelcache` via:
  - `0x00002ee4: adr x0, #0x4eb74`

2) **Size/validity checks exist** (error message xrefs)
- `Kernelcache too large`:
  - `0x00007fb4: adr x0, #0x4f30f`
- `Kernelcache image not valid`:
  - `0x0000800c: adr x0, #0x4f326`
  - `0x000081c4: adr x0, #0x4f326`

3) **Placement arithmetic exists** (alignment/granularity/bounds)
- 16KB alignment mask:
  - `0x000089d8: and x9, x8, #0xffffffffffffc000`
  - `0x00008acc: and x26, x8, #0xffffffffffffc000`
- 2MB granule start and doubling loop:
  - `0x000089e8: mov w8, #0x200000`
  - `0x000089f0: lsl x8, x8, #1`
  - `0x000089f8: b.lo #0x89ec`
- bounds check vs a limit register:
  - `0x00008ae0: cmp x8, x25`
  - `0x00008ae4: b.hs #0x9090`

4) **Delta/offset storage exists**
- `0x00008b5c: sub x8, x8, x26`
- `0x00008b64: str x8, [x9, #0x218]`

**Important limit:** we do not assert “this is the kernel slide”; we only assert “a delta between two address-like values is stored”.

5) **Mach-O header handling for Kernel/AuxKC is explicit**
- `Kernel-mach_header` label call site:
  - `0x00008b7c: adr x0, #0x4f3e1`
  - `0x00008b88: bl #0x9224`
- `AuxKC-mach_header` label call site:
  - `0x00008c48: adr x0, #0x4f3fa`

### 2.2 EL1 context restore + `eret` mechanism (proven shape)
From `output/phase10/phase10d/entry_like_eret_context.txt`:

**Context restore → `eret` (candidate handoff primitive)**
- `0x00010188: ldr x0, [sp, #0x108]`
- `0x00010190: msr elr_el1, x0`
- `0x00010194: ldr w1, [sp, #0x100]`
- `0x00010198: msr spsr_el1, x1`
- restores x0–x30 from stack
- adjusts `sp_el0` based on memory read
- `0x000101f4: eret`

**What is guaranteed by this shape (only):** iBoot can transfer control to an EL1 target address by writing `ELR_EL1` from a memory-backed frame and executing `eret`, with the ability to restore general-purpose registers from that frame.

**Not proven:** that this is the *final* boot→kernel handoff site.

---

## 3) Address contract synthesis (kernel ↔ boot-chain)

### Proven (direct evidence)
- Kernel entry PC is a **high VA** value from `LC_UNIXTHREAD`: `0xfffffe0007d44528`.
- Kernel entry PC lies within `__TEXT_EXEC` (Mach-O metadata containment).
- iBoot computes **aligned address-like bases** with 16KB alignment and 2MB granularity and checks bounds.
- iBoot stores a **delta** between two address-like values.
- iBoot has an **ELR_EL1 + `eret`** transfer primitive that sources ELR/SPSR from a memory frame.

### Plausible (supported by cross-evidence, but not fully proven)
- The stored delta might relate to reconciling “preferred” vs “actual” placement (kernelcache has a preferred high-VA layout; iBoot performs placement arithmetic and stores a delta).

Marked as plausible because:
- kernelcache-side: absolute VA layout is present,
- boot-chain-side: a delta is stored,
- but the exact semantic identity (slide vs other) is unproven.

### Unknown (hard boundary)
- Whether `LC_UNIXTHREAD.pc` is used as-is, or is rebased by an iBoot-computed delta.
- Whether dyld chained fixups (`LC_DYLD_CHAINED_FIXUPS` present in kernelcache) are applied by iBoot before entry.
- The exact runtime kernel entry VA and the exact register/stack contract at handoff.

---

## 4) Boot-feasibility boundary (static-only answer)

Question: “Based on static evidence alone, is there a theoretical path to a bootable handoff without violating architectural rules?”

**Answer: YES, but only as ‘boot-feasible with constraints’.**

Justification (tied to evidence):
- The kernel artifact provides a concrete entry VA and confirms it resides in executable text.
- The boot chain demonstrates it can configure EL1 state and transfer control via `ELR_EL1` + `eret`.
- However, critical details needed for an *honest* boot-capable environment are not statically provable from the current boot-chain artifact subset (exact final ELR_EL1 value source, fixup application responsibility, and the entry register contract).

**Minimal additional things a future phase would need to observe (not implement here):**
- Identify the *actual* handoff path that populates the EL1 context frame containing ELR_EL1/SPSR_EL1.
- Prove whether a delta/slide is applied to `LC_UNIXTHREAD.pc` and/or segment vmaddrs.
- Prove whether chained fixups are applied pre-entry (via a proven call path in boot chain) or are assumed already resolved.

---

## Constraint vs unknown matrix
| Topic | Proven | Plausible | Unknown |
|---|---:|---:|---:|
| Entry source is `LC_UNIXTHREAD` | ✅ |  |  |
| Entry PC in `__TEXT_EXEC` | ✅ |  |  |
| Kernel has contiguous high-VA span in metadata | ✅ |  |  |
| iBoot enforces 16KB alignment + 2MB granularity | ✅ |  |  |
| iBoot stores a placement delta | ✅ (delta exists) | ✅ (might be slide) | ✅ (semantic identity) |
| iBoot uses ELR_EL1 + `eret` to transfer to EL1 | ✅ |  |  |
| Final kernel entry VA value used by iBoot |  |  | ✅ |
| Kernel register contract at entry (x0–xN, SP) |  |  | ✅ |
| iBoot applies dyld chained fixups |  |  | ✅ |

---

## Phase classification (required)
**B) Entry contract partially reconstructible, boot-feasible with constraints.**

One-paragraph justification:
Static artifacts prove (1) the kernel’s entrypoint is an absolute high VA derived from `LC_UNIXTHREAD` and lies within `__TEXT_EXEC`, and (2) iBoot performs bounded, aligned placement arithmetic, stores a delta between address-like values, and contains an EL1 context restore + `eret` transfer mechanism. Static artifacts do not prove which boot-chain routine performs the final handoff, whether the entry PC is rebased, whether chained fixups are applied, or what register/SP contract is established; therefore the contract is only partially reconstructible without execution or additional boot-stage binaries.
