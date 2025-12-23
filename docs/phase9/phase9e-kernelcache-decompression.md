# Phase 9e: Kernelcache Decompression & Executable-State Observation

## Scope
Artifact interpretation only.
- No QEMU execution.
- No trampoline.
- No entrypoint guessing.
- No emulator/boot-chain/hardware/MMU changes.

## Inputs (pre-verified, ignored by git)
- IM4P container:
  - `local_storage/ipsw/extracted_phase9d/kernelcache.release.mac13g`
- Extracted IM4P payload (verbatim; LZFSE/bvx2):
  - `local_storage/ipsw/extracted_phase9d/kernelcache.release.mac13g.im4p_payload`

Git safety:
- `local_storage/**` is ignored by `.gitignore`.
- These artifacts are not committed.

## Step 1 — Decompression (LZFSE)
### Tooling used
Decompression used an already-present, standard `lzfse` CLI inside WSL:
- `lzfse -h` prints: `Usage: lzfse -encode|-decode [-i input_file] [-o output_file] [-h] [-v]`
- Tool path observed: `/usr/local/bin/lzfse`

### Exact command
Run from repo root (WSL):
```bash
IN=local_storage/ipsw/extracted_phase9d/kernelcache.release.mac13g.im4p_payload
OUTDIR=local_storage/ipsw/extracted_phase9e
OUT=$OUTDIR/kernelcache.release.mac13g.decompressed
mkdir -p "$OUTDIR"
rm -f "$OUT"
lzfse -decode -i "$IN" -o "$OUT"
sha256sum "$OUT" | tee "$OUTDIR/kernelcache.release.mac13g.decompressed.sha256"
file "$OUT" | tee "$OUTDIR/kernelcache.release.mac13g.decompressed.file"
```

### Output artifact
- Output path (ignored):
  - `local_storage/ipsw/extracted_phase9e/kernelcache.release.mac13g.decompressed`
- Size (from `ls -l`): `101482496` bytes
- SHA256:
  - `e5e1824c593e11feedf7e3c2430f5f5e2f77f2e00513c077690fcea0c18981c5`

If decompression were incorrect, subsequent header parsing would likely fail to identify a valid Mach-O magic (`0xfeedfacf`) at offset 0; the next step confirms that magic.

## Step 2 — Format identification
`file(1)` on the decompressed output reports:
- `Mach-O 64-bit arm64e ... filetype=12`

Evidence (first 16 bytes):
- `cf fa ed fe 0c 00 00 01 02 00 00 00 0c 00 00 00`
  - `0xfeedfacf` Mach-O 64-bit magic
  - `cputype=0x0100000c` (arm64/arm64e family as reported by tools)
  - `filetype=12` (Mach-O MH_FILESET)

## Step 3 — Entry metadata observability (NO JUMP)
The decompressed Mach-O was scanned for entry-related load commands.

### Method
A small offline parser (read-only) enumerated Mach-O load commands and checked:
- `LC_MAIN` (`0x80000028`)
- `LC_UNIXTHREAD` (`0x00000005`)

Evidence output (saved):
- `output/phase9/phase9e/macho_entry_report.txt`

### Observed results
- `LC_MAIN`: **not present** (`LC_MAIN=None`)
- `LC_UNIXTHREAD`: **present** with ARM thread state flavor `6`:
  - `LC_UNIXTHREAD=(18446741874817647912, 0, 0, 6, 68)`
  - Interpreting that tuple strictly as produced by the parser:
    - `pc = 18446741874817647912` (`0xfffffe...` high virtual address)
    - `sp = 0`
    - `cpsr = 0`
    - `flavor = 6`
    - `count = 68`

This establishes that **entry metadata exists** in the artifact (via `LC_UNIXTHREAD`) without asserting anything about whether that address is currently mapped/executable in our emulator.

## Step 4 — Classification
**A) Executable kernel binary with provable entry metadata.**

Justification (evidence-backed):
- The decompressed output is an unambiguous Mach-O 64-bit arm64e file (`file(1)`, Mach-O magic bytes).
- It contains a provable entry-PC value in `LC_UNIXTHREAD` (extracted from bytes by deterministic parsing).

## What is explicitly UNKNOWN (do not guess)
- Whether the `LC_UNIXTHREAD` `pc` corresponds to a valid executable mapping in the Phase 5/8 environment.
- Whether additional kernelcache indirection (MH_FILESET contents) changes the effective entrypoint at runtime.
- Whether `sp=0` / `cpsr=0` are meaningful for actual execution (this report does not assume they are).

## Warning: why guessing is forbidden
Even though an entry PC is present in metadata, **we do not**:
- jump to it,
- assume it is mapped,
- assume it matches `APPLE_KERNEL_BASE`,
- or infer required VA acceptance/mappings.

Those would be execution/bring-up steps and would violate Phase 9e’s artifact-only scope.
