# Phase 10b: Kernel Relocation & Slide Semantics Reconstruction (Observation Only)

## Scope / constraints
Observation-only.
- No QEMU execution.
- No jumping to kernel entry.
- No MMU/VA acceptance changes.
- No boot-chain changes.
- No guessing slide values.

## Inputs (not regenerated)
- Decompressed kernelcache (MH_FILESET, arm64e):
  - `local_storage/ipsw/extracted_phase9e/kernelcache.release.mac13g.decompressed` *(git-ignored)*
- Phase 10a outputs:
  - `output/phase10/phase10a/segments.csv`
  - `output/phase10/phase10a/summary.txt`

Phase 10b evidence outputs (generated, git-ignored):
- `output/phase10/phase10b/loadcmd_counts.txt`
- `output/phase10/phase10b/fileset_entries.txt`
- `output/phase10/phase10b/reloc_loadcmd_presence.txt`
- `output/phase10/phase10b/entry_pc_occurrences.txt`
- `output/phase10/phase10b/qword_range_counts.txt`

---

## 1) Fileset-level relocation properties (structure)
### Evidence: load command inventory
From `output/phase10/phase10b/loadcmd_counts.txt`:
- `filetype=12` (MH_FILESET)
- Load command IDs present (counts):
  - `0x00000019` (LC_SEGMENT_64): `7`
  - `0x00000005` (LC_UNIXTHREAD): `1`
  - `0x0000001b` (LC_UUID): `1`
  - `0x00000032` (LC_BUILD_VERSION): `1`
  - `0x80000034` (LC_DYLD_CHAINED_FIXUPS): `1`
  - `0x80000035` (LC_FILESET_ENTRY | LC_REQ_DYLD): `342`

### Evidence: MH_FILESET contains multiple Mach-O images
From `output/phase10/phase10b/fileset_entries.txt` (parsed from `LC_FILESET_ENTRY`):
- `entries=342`
- All entries’ `inner_magic=0xfeedfacf` (Mach-O 64-bit) (`inner_magic counts: 342`).

Observed `LC_FILESET_ENTRY` name examples (first/last entries shown in the file):
- `com.apple.AGXFirmwareKextG13GRTBuddy ...`
- ...
- `com.apple.kernel vmaddr=0xfffffe0007c70000 fileoff=0xc6c000 inner_magic=0xfeedfacf`

### VM address distribution of sub-images (fileset entries)
From `fileset_entries.txt`:
- `vmaddr_min=0xfffffe000700c000`
- `vmaddr_max=0xfffffe0007c70000`

**Observation:** the fileset encodes *per-subimage* `vmaddr` values in a high-VA region and they differ across entries (not a single identical base).

**What is NOT proven here:** whether these `vmaddr` values are (a) strict fixed requirements, or (b) preferred addresses that a loader rebases as part of boot-time placement.

---

## 2) Load command relocation signals (presence/absence)
From `output/phase10/phase10b/reloc_loadcmd_presence.txt`:

### Recorded presence/absence
- `LC_DYLD_INFO (0x00000022) present=False`
- `LC_DYLD_INFO_ONLY (0x80000022) present=False`
- `LC_SEGMENT_SPLIT_INFO (0x0000001e) present=False`
- `LC_REEXPORT_DYLIB (0x0000001f) present=False`
- `LC_NOTE (0x00000031) present=False`
- `LC_UUID (0x0000001b) present=True`
- `LC_BUILD_VERSION (0x00000032) present=True`
- `LC_DYLD_CHAINED_FIXUPS (0x80000034) present=True`

### General roles (descriptive only)
- `LC_UUID`: identifies a unique build UUID for the Mach-O.
- `LC_BUILD_VERSION`: records minimum platform/build metadata.
- `LC_DYLD_CHAINED_FIXUPS`: points to linkedit fixup information that a loader can process to “fix up” pointers.
- The absence of `LC_DYLD_INFO(_ONLY)` means classic dyld info blobs are not present in this top-level header.

### Chained fixups header (byte-level decode)
Also from `reloc_loadcmd_presence.txt`:
- `chained_fixups_linkedit=(101466112, 2546)` meaning:
  - `dataoff = 101,466,112`
  - `datasize = 2,546 (0x9f2)`

Decoded `dyld_chained_fixups_header` at that `dataoff`:
- `version=0`
- `starts_offset=0x1c`
- `imports_offset=0x9f2`
- `symbols_offset=0x9f2`
- `imports_count=0`
- `imports_format=1`
- `symbols_format=0`

Notes (strictly numeric):
- `imports_offset` equals `datasize` (reported in the file as “within” false because the check was `<`, not `<=`).

---

## 3) Absolute vs relative addressing signals (static-only)
### A) Entry PC appears as an absolute value (rare)
From `output/phase10/phase10b/entry_pc_occurrences.txt`:
- `entry_pc=0xfffffe0007d44528`
- `occurrences_le8=1` when searching the entire file for the exact 8-byte little-endian value.

**Observation:** the entry PC exists as explicit metadata and also appears once as a raw 64-bit value in the file contents.

### B) High-VA pointers exist in the binary (coarse statistic)
Using Phase 10a’s observed kernel VA span:
- `min_va=0xfffffe0007004000`
- `max_va=0xfffffe000d0cc000`

From `output/phase10/phase10b/qword_range_counts.txt` (scanning aligned 8-byte words across the file):
- `total_qwords=12685312`
- `qwords_in_kernel_va_span=203065`
- `fraction=0.016008`

**Observation:** a non-trivial number of 64-bit values inside the binary fall numerically within the kernel’s own VM span.

**What is NOT proven:** whether these values are live pointers requiring rebasing, offsets, constants, data tables, or something else.

---

## 4) Boot-chain responsibility classification
### Classification (A/B/C)
**B) Designed to be relocated by the boot chain.**

Evidence supporting B:
- The kernelcache contains `LC_DYLD_CHAINED_FIXUPS` and a valid-looking `dyld_chained_fixups_header` (byte-decoded fields above).
- The presence of explicit fixup metadata is a structural signal that some loader is expected to process relocation-like data rather than treating the file as purely “already-final” in-memory bytes.

Critical evidence that is still missing (limits):
- This phase cannot prove what slide (if any) is chosen at boot, or whether the loader always uses slide=0.
- This phase does not prove which component performs the fixups (iBoot vs boot.efi vs other), only that fixup data exists.

### What a next phase would require (no assumptions)
To prove *actual slide semantics* (not just presence of fixup structures), we would need one of:
- Boot-chain logs/behavior showing chosen load address or applied slide, or
- A separate, static artifact that records the chosen slide/base (e.g., boot args, bootloader data structure), or
- Controlled execution observation (explicitly forbidden in this phase).

## STOP condition statement
This phase stops at: “fixup metadata exists and can be decoded from bytes; therefore relocation processing is structurally implied.”
It does not attempt to derive or guess any specific slide value.
