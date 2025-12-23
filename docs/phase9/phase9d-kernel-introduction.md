# Phase 9d: Real macOS Kernel Artifact Introduction (Observation-Only)

## Preconditions (hard gate)
### Real kernel artifact exists locally
A real macOS kernelcache artifact was located inside the local IPSW archives and extracted to an ignored path.

- IPSW source (local, not committed):
  - `local_storage/ipsw/UniversalMac_12.1_21C52_Restore.ipsw`
- Extracted kernelcache container (ignored path):
  - `local_storage/ipsw/extracted_phase9d/kernelcache.release.mac13g`
  - Size: `24248091` bytes
  - SHA256: `2f5c38ddb2321a90f993d664ee6757e964dedd06233bc69cc2d3851f18d8d85e`

Git safety:
- `local_storage/**` is ignored by `.gitignore`.
- No kernel artifacts were (or will be) added to git.

## Step 1: Kernel artifact inspection (offline)
### Container format
The extracted file is an Apple `IM4P` container (DER/ASN.1-wrapped).
Evidence (first bytes):
- `0x30 0x84 ... 0x16 0x04 'IM4P' ...`

Extracted IM4P IA5String fields (evidence file generated):
- `output/phase9/phase9d/kernelcache.release.mac13g.im4p_strings.txt`
Key strings include:
- `IM4P`
- `krnl`
- `KernelManagement_host-262.60.4`

### Payload extraction
The largest OCTET STRING within the IM4P container was extracted verbatim (no modification) to:
- `local_storage/ipsw/extracted_phase9d/kernelcache.release.mac13g.im4p_payload`
- Size: `24247835` bytes
- SHA256: `8824eec2a56175cddbef3a02264d29be0f9530c8f23003bdb17feadd7b65a5b9`

### Payload type
`file(1)` identifies the extracted payload as **LZFSE compressed**:
- `...: lzfse compressed, compressed tables`
- Magic bytes: `bvx2 ...`

This was also confirmed for other kernelcache.release.* entries (macOS 11.0.1 t485/j273/mac13g): all extracted IM4P payloads are `bvx2` / LZFSE.

## Entry point determination (constraint gate)
A safe, evidence-backed entrypoint cannot be determined from the artifact as-is because:
- The extracted payload is LZFSE-compressed (not a Mach-O header), so Mach-O load commands / LC_MAIN / LC_UNIXTHREAD are not visible without decompression.

Per Phase 9d rules:
- **We MUST NOT guess an entrypoint.**
- If the entrypoint cannot be proven from the format, we must STOP.

## Execution (Step 3)
Not performed.
- No trampoline was built.
- No QEMU runs were executed.
Reason: cannot prove a kernel entrypoint from the available artifact bytes without introducing additional decoding/decompression steps.

## Attribution
No kernel execution occurred in this phase.
All observations are strictly about the on-disk kernelcache container and its extracted compressed payload.

## Classification verdict
**D) Insufficient evidence (ambiguous) — STOP.**

Rationale:
- A real kernel artifact exists and was verified.
- However, the executable kernel bytes and entrypoint are not directly observable due to LZFSE compression.
- Proceeding to control transfer would require either guessing an entrypoint or adding new artifact-processing behavior.

## Evidence artifacts
- `local_storage/ipsw/extracted_phase9d/kernelcache.release.mac13g` (IM4P container; ignored)
- `local_storage/ipsw/extracted_phase9d/kernelcache.release.mac13g.im4p_payload` (LZFSE/bvx2 payload; ignored)
- `output/phase9/phase9d/kernelcache.release.mac13g.im4p_strings.txt` (IA5String evidence)
