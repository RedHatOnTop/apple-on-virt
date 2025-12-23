# Phase 10d — Entry Path Disassembly (Annotated, Static)

All addresses below are **pseudo-addresses == file offsets** in:
- `output/phase10/phase10c/iBoot.vma2.payload.disasm.txt`

## 1) Kernelcache path selection evidence
From `excerpt_path_system_kernelcache.txt` / `excerpt_path_boot_kernelcache.txt`:
- `/System/Library/Caches/com.apple.kernelcaches/kernelcache` referenced via:
  - `0x00002b6c: adr x1, #0x4e8ce`
- `/boot/kernelcache` referenced via:
  - `0x00002ee4: adr x0, #0x4eb74`

## 2) Kernel load progress + error markers
From `excerpt_load_kernel_start.txt` / `excerpt_kernelcache_errors.txt`:
- `load-kernel-start` marker referenced at:
  - `0x00007938: adr x8, #0x4f285`
- `Kernelcache too large` error string referenced at:
  - `0x00007fb4: adr x0, #0x4f30f`
- `Kernelcache image not valid` referenced at:
  - `0x0000800c: adr x0, #0x4f326`
  - `0x000081c4: adr x0, #0x4f326`

## 3) Placement arithmetic block (alignment + bounds)
From `excerpt_mach_header_labels.txt` (selected lines):
- 16KB align-up and mask:
  - `0x000089d0: mov w8, #0x3fff`
  - `0x000089d8: and x9, x8, #0xffffffffffffc000`
- 2MB granule loop:
  - `0x000089e8: mov w8, #0x200000`
  - `0x000089f0: lsl x8, x8, #1`
  - `0x000089f8: b.lo #0x89ec`
- bounds check:
  - `0x00008ae0: cmp x8, x25`
  - `0x00008ae4: b.hs #0x9090`

## 4) Kernel/AuxKC Mach-O header handling labels
From `excerpt_mach_header_labels.txt`:
- Kernel label call site:
  - `0x00008b7c: adr x0, #0x4f3e1`  ("Kernel-mach_header")
  - `0x00008b78: add x1, x8, x28`
  - `0x00008b84: mov x2, #0`
  - `0x00008b88: bl #0x9224`
- AuxKC label call site:
  - `0x00008c48: adr x0, #0x4f3fa` ("AuxKC-mach_header")
  - `0x00008c50: bl #0x984c`

## 5) EL1 context restore + ERET primitive (candidate handoff mechanism)
From `entry_like_eret_context.txt` (context restore):
- `0x00010188: ldr x0, [sp, #0x108]`
- `0x00010190: msr elr_el1, x0`
- `0x00010194: ldr w1, [sp, #0x100]`
- `0x00010198: msr spsr_el1, x1`
- restores x0–x30 from stack frame
- updates `sp_el0`
- `0x000101f4: eret`

**Annotation:** This proves an ELR_EL1-driven transfer-of-control mechanism exists; whether it is the boot→kernel handoff path remains unproven in Phase 10d.
