# Phase 10c: Boot Chain Relocation Logic Reconstruction (Full Static Disassembly – Observation Only)

## Scope / constraints
Static analysis only.
- No QEMU execution.
- No patching/modifying binaries.
- No slide guessing.

All addresses below are **pseudo-addresses equal to file offsets** (disassembly base = 0) because the analyzed `iBoot.vma2` payload has **no Mach-O header** (raw AArch64 image). This is explicitly a *display convention* for evidence.

## Inputs (local, git-ignored)
### Primary analyzed artifact
- IPSW: `local_storage/ipsw/UniversalMac_12.1_21C52_Restore.ipsw`
- iBoot Stage2 for Apple Silicon Mac (vma2), extracted from IPSW:
  - IM4P: `local_storage/ipsw/extracted_phase10c/iBoot.vma2.RELEASE.im4p`
  - Extracted IM4P payload: `local_storage/ipsw/extracted_phase10c/iBoot.vma2.RELEASE.payload`
  - Payload SHA256: `3d2ed88a516136a8d150eec999bd6ef244e18f7926cfd8352fe3b7c283f2199c` (see `output/phase10/phase10c/iBoot.vma2.payload.sha256`)

### Other observed artifacts
- `iBoot.j274.RELEASE.im4p` payload appears opaque/non-self-describing (no disassembly proven from bytes in this phase), so analysis focuses on `vma2` iBoot Stage2.

## Tooling used (offline)
- IM4P payload extraction: `output/phase9/phase9d/extract_im4p_payload.py` (DER TLV walk; extracts largest OCTET STRING)
- AArch64 linear-sweep disassembly:
  - `output/phase10/phase10c/disasm_a64.py` (Capstone-based; emits `.word` for undecodable 4-byte slots)
- Outputs:
  - Full disassembly: `output/phase10/phase10c/iBoot.vma2.payload.disasm.txt` (~82k lines)
  - String offsets: `output/phase10/phase10c/iBoot.string_offsets.txt`
  - Disassembly excerpts (see filenames under `output/phase10/phase10c/`)

---

## Primary questions (answered in order)

## 1) Where is the kernel load address decided?
### 1.1 Kernelcache selection paths are explicit
The iBoot payload contains hard-coded kernelcache path strings. Evidence (string offsets from `iBoot.string_offsets.txt`):
- `/System/Library/Caches/com.apple.kernelcaches/kernelcache` at `0x4e8ce`
- `/System/Library/Caches/com.apple.kernelcaches/kernelcache.auxkc` at `0x4e908`
- `/boot/kernelcache` at `0x4eb74`

These are referenced directly via `adr` in code (from `iBoot.string_xrefs.grep.txt`):
- `0x00002b6c: adr x1, #0x4e8ce` (system cache path)
- `0x00002ee4: adr x0, #0x4eb74` (boot path)

Disassembly context:
- `output/phase10/phase10c/excerpt_path_system_kernelcache.txt`
- `output/phase10/phase10c/excerpt_path_boot_kernelcache.txt`

### 1.2 A concrete placement decision block exists (alignment + bounds logic)
A large block computes aligned addresses and enforces bounds before proceeding to Mach-O header handling.
This block is in `output/phase10/phase10c/excerpt_mach_header_labels.txt` around `0x000089cc..0x00008b68`.

Evidence of placement computations (selected instructions):
- Align up to 16KB:
  - `0x000089d0: mov w8, #0x3fff`
  - `0x000089d4: add x8, x26, x8`
  - `0x000089d8: and x9, x8, #0xffffffffffffc000`  *(mask to 0x4000 boundary)*
- Choose a power-of-two granule starting at 2MB and doubling until it is >= a size-like register (`x28`):
  - `0x000089e8: mov w8, #0x200000`
  - `0x000089ec: mov x26, x8`
  - `0x000089f0: lsl x8, x8, #1`
  - `0x000089f4: cmp x26, x28`
  - `0x000089f8: b.lo #0x89ec`
- Candidate base selection and constraints:
  - Reads a global pointer-like value: `0x00008a00: ldr x20, #0x50d50`
  - Alignment constraint: `0x00008a08: tst x20, #0x3fff` and branch on misalignment.
  - Derives an address-like value from masked bits and adds the chosen granule: `0x00008a44..0x00008a50`:
    - `0x00008a44: ldur x8, [x29, #-0x78]`
    - `0x00008a48: and x8, x8, #0x1fffc000`
    - `0x00008a4c: add x20, x8, x26`
  - Later compares computed end vs a limit register `x25`:
    - `0x00008ad4..0x00008ae4: ... cmp x8, x25; b.hs #0x9090`

**What is proven:** iBoot contains explicit code that computes aligned candidate addresses (`x9`, `x20`, `x26`) and performs bounds checks before proceeding.

**What is NOT proven:** the semantic meaning of these addresses (e.g., “kernel physical load base” vs “heap region” vs “mapping window”) cannot be asserted without symbols and without execution; in this report we only describe the arithmetic and control flow.

---

## 2) Does a kernel slide concept exist?
### 2.1 No explicit "slide/kASLR" strings were found
Keyword string search (saved in `output/phase10/phase10c/iBoot.keyword_strings.txt` and `iBoot.more_keywords.txt`) found kernelcache paths and error labels, but did **not** find clear textual indicators like `slide`, `kASLR`, `ASLR`, `random`, or `dyld`.

### 2.2 A “delta” value is computed and stored globally (numeric evidence only)
Within the Mach-O header handling region, iBoot computes a subtraction and stores it into a global page:
- `0x00008b58: ldur x8, [x29, #-0xb0]`
- `0x00008b5c: sub x8, x8, x26`
- `0x00008b60: adrp x9, #0x51000`
- `0x00008b64: str x8, [x9, #0x218]`

This is a **concrete stored delta** between two address-like quantities (`x8` and `x26`).

**What is proven:** a delta is computed and persisted.

**UNKNOWN:** whether this delta is a “kernel slide” vs an unrelated allocator/placement delta.

---

## 3) Who applies relocation / fixups?
### 3.1 iBoot parses IM4P headers in code (evidence of IMG4 container handling)
Disassembly excerpt `output/phase10/phase10c/excerpt_u32_lc_constants.txt` (around `0x0002f654`) shows code building and using a 32-bit constant that corresponds to an ASCII tag check and then branching into validation logic.

Relevant block:
- `0x0002f654: mov w1, #0x3450`
- `0x0002f658: movk w1, #0x494d, lsl #16`
- `0x0002f65c: bl #0x2f32c`
- Followed by defensive patterns (`movi v0.16b,#0xaa` and `stp q0,q0,[sp]`), and `brk` on failure (`0x0002f6f0: brk #0x5519`).

This shows iBoot includes a container-validation routine consistent with handling structured blobs (like IM4P).

### 3.2 Kernelcache Mach-O header identification is explicit
The payload includes label strings:
- `Kernel-mach_header` at `0x4f3e1`
- `AuxKC-mach_header` at `0x4f3fa`

and references them directly:
- `0x00008b7c: adr x0, #0x4f3e1` (Kernel-mach_header)
- `0x00008c48: adr x0, #0x4f3fa` (AuxKC-mach_header)

Around these sites, a function is called with `(x0=label, x1=address-like, x2=0)`:
- `0x00008b78: add x1, x8, x28`
- `0x00008b7c: adr x0, #0x4f3e1`
- `0x00008b84: mov x2, #0`
- `0x00008b88: bl #0x9224`

**What is proven:** iBoot explicitly identifies and processes Mach-O headers for Kernel and AuxKC.

### 3.3 Chained fixups handling is NOT proven from this iBoot payload alone
In Phase 10b, the kernelcache Mach-O contains `LC_DYLD_CHAINED_FIXUPS` (proven from kernelcache bytes).
For iBoot.vma2 payload, this Phase 10c analysis **did not** prove a specific routine that applies dyld chained fixups to the kernelcache:
- No direct strings like `dyld_chained_fixups`/`fixups` were found.
- However, raw occurrences of the 32-bit values `0x80000034` and `0x80000035` exist in the binary (see `output/phase10/phase10c/u32_hits_80000034.txt` and `u32_hits_80000035.txt`). This suggests tables or comparisons may exist, but without a proven control-flow connection to kernelcache processing, “who applies fixups” remains **UNKNOWN**.

STOP boundary for this sub-question: without symbol names and without a clearly identified fixup-application call path tied to kernelcache processing, we cannot prove fixup application responsibility.

---

## 4) What address-space assumptions are enforced?
### 4.1 Alignment and size granularity assumptions are explicit
From the placement block (see §1.2):
- 16KB alignment via masking with `0xffffffffffffc000`.
- 2MB granule growth (`0x200000` doubled until >= a size-like value).

### 4.2 Pointer Authentication (PAC) is used
The disassembly contains PAC instructions in multiple routines, e.g.:
- `0x00007f74: pacibsp`
- `0x00008048: retab`
- `0x00007fdc: paciza x16`

This is a concrete address-space/control-flow hardening feature.

### 4.3 TTBR/TCR/SCTLR/VBAR programming is not proven here
A simple grep over the full linear disassembly did not yield clear `msr/mrs` sysreg setup lines in the extracted evidence set for this phase. This does not prove they are absent; it only means we did not establish a reliable, evidenced sysreg-configuration routine tied to kernel placement within the constraints of this phase.

---

## 5) Are there security-conditional branches?
Evidence of security-oriented conditional control flow exists:
- Pointer-authenticated indirect branch setup with `paciza` and guard `tbz`/`brk` patterns (e.g., `0x00007f50..0x00007f5c` shows `eor`/`tbz` then `brk` on mismatch).
- Multiple `brk` sites on invariant violation (e.g., `0x0002f6f0: brk #0x5519`).

**UNKNOWN:** secure-boot-state-specific branching (e.g., based on SEP/AMFI state) is not proven from strings or clearly identified decision variables in this static pass.

---

## What Is Proven vs What Remains Unknown

### Proven (from bytes + disassembly)
1. **iBoot Stage2 (vma2) contains explicit kernelcache path strings** and code references to them (`adr` sites at `0x00002b6c`, `0x00002ee4`).
2. **iBoot prints/logs a “load-kernel-start” marker string** (e.g., `0x00007938: adr x8, #0x4f285`) and prints kernelcache error strings:
   - `Kernelcache too large` at `0x00007fb4`.
   - `Kernelcache image not valid` at `0x0000800c` and `0x000081c4`.
3. **A placement/selection routine exists** with concrete arithmetic:
   - 16KB alignment masking.
   - 2MB-granule selection by doubling.
   - bounds checks against a limit register.
4. **Mach-O header handling for kernel + auxKC is explicit** via label strings and call sites (e.g., `0x00008b7c` and `0x00008c48`).
5. **A delta is computed and stored globally** (`0x00008b5c..0x00008b64`).
6. **PAC is used** (`pacibsp`, `retab`, `paciza`).

### Unknown (cannot be proven without additional artifacts or execution)
1. The **exact semantic identity** of the computed placement addresses (physical vs virtual; kernel region vs scratch region).
2. Whether the stored delta is **specifically the kernel slide** (as opposed to another placement delta).
3. **Who applies dyld chained fixups** to the kernelcache:
   - kernelcache contains fixup metadata (Phase 10b), but this iBoot payload does not yield a proven fixup-application routine tied to kernel processing.
4. TTBR/TCR/SCTLR/VBAR configuration (if present) and the exact VA-size/TBI policy used by iBoot when transitioning to kernel execution.

## STOP condition (met)
Phase 10c stops here because:
- We located and described the static kernelcache loading/validation/placement-related logic **as far as it can be proven from this raw iBoot payload**.
- Further claims (especially slide semantics and fixup responsibility) would require either additional boot-stage binaries (e.g., other vma2 stages) or execution/trace, both out of scope.
