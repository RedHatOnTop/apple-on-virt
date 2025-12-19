---
title: Apple Custom Instructions
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/cpu/apple-instructions.md
project-relevance:
  Emulator must decode and execute (or stub) these instructions to prevent illegal instruction faults in guest code.
confidence: high
---

## Extracted Facts

### Instruction Range
- Apple proprietary instructions occupy the `0x0020xxxx` range.

### Defined Instructions

#### Memory & Compression
- **MUL53** (`0x002000xx` range): 53-bit multiplication (specific opcodes defined in external gist).
- **wkdmc** (`00200800 | rD<<5 | rS`): Compress memory page.
    - rS: Source page address.
    - rD: Destination buffer address.
- **wkdmd** (`00200c00 | rD<<5 | rS`): Decompress memory page.
    - rS: Source compressed data.
    - rD: Destination page address.

#### AMX (Apple Matrix Coprocessor)
- Range: `0x00201000` - `0x002012df`.
- If disabled/unsupported, faults with `ESR_EL2 = 0xfe000003`.

#### Guarded Execution (GXF)
- **genter** (`0x00201420 | imm5`): Enter guarded mode.
    - imm5 -> `ESR_GLx[5:0]`.
    - PC -> `S3_6_C15_C8_1`.
- **gexit** (`0x00201400`): Exit guarded mode.

#### Address Translation
- **at_as1elx** (`0x00201440 | rA`): Translate address (PAR_EL1 equivalent).
    - Returns result in `rA` (MAIR attr + PA + Flags).
    - Avoids modifying system PAR_EL1 register(?).

#### Barriers
- **sdsb** (`0x00201460` - `0x00201463`): Speculative Data Store Barrier?
    - 0: osh, 1: nsh, 2: ish (used by iBoot), 3: sy.

## Explicit Non-Facts / Unknowns
- Detailed behavior of AMX instructions is not in the text (refers to external gist).
- Exact bit encoding of `at_as1elx` result flags (only `0x80x` noted as unmapped).

## Notes for Future Phases
- `wkdmc`/`wkdmd` should be implemented for performance/correctness if OS uses swap/memory compression heavily.
- `AMX` can likely be stubbed to fault (as disabled) initially.
- `at_as1elx` is critical for some macOS low-level memory management routines.
