# Phase 2 Step 2: Execution Handoff

## Objective

Transfer CPU execution to iBoot entry point.

## Implementation

### CPU State at Handoff

The machine initialization sets CPU state for iBoot entry:

```c
/* Entry point */
cpu->env.pc = APPLE_IBOOT_BASE;  /* 0x40100000 */

/* Stack pointer (top of DRAM minus 4KB) */
cpu->env.xregs[31] = APPLE_DRAM_BASE + APPLE_DRAM_SIZE - 0x1000;
/* = 0x40000000 + 0x40000000 - 0x1000 = 0x7FFFF000 */

/* Device Tree address in X0 (ARM boot convention) */
cpu->env.xregs[0] = APPLE_DT_BASE;  /* 0x40000000 */
```

### Register State

| Register | Value | Purpose |
|----------|-------|---------|
| PC | 0x40100000 | iBoot entry point |
| SP (X31) | 0x7FFFF000 | Stack pointer |
| X0 | 0x40000000 | Device Tree address |
| X1-X30 | 0 | Unused |

### Exception Level

- **EL**: EL1 (default for QEMU ARM aarch64)
- This is appropriate for iBoot which typically runs at EL1

### Memory Map at Handoff

```
0x00000000  +------------------+
            | Reserved         | (256MB, not accessible)
0x10000000  +------------------+
            | Secure           | (256MB, not accessible)
0x20000000  +------------------+
            | MMIO             | (512MB)
0x40000000  +------------------+ <- X0 (Device Tree)
            | DRAM             |
            |   Device Tree    |
0x40100000  +------------------+ <- PC (Entry Point)
            |   iBoot          |
            |                  |
0x7FFFF000  +------------------+ <- SP (Stack)
            |   Stack Space    | (4KB)
0x80000000  +------------------+
```

### Handoff Sequence

1. Machine initialization completes
2. QEMU event loop starts
3. CPU fetches first instruction from PC (0x40100000)
4. iBoot execution begins

### Verification

When iBoot is loaded, the following is output:

```
=== Phase 2: iBoot Execution Handoff ===
Entry Point: 0x40100000
Stack Pointer: 0x7ffff000
Device Tree (X0): 0x40000000
```

## Quality Gate

**CPU fetches instructions from iBoot region.**

Verification:
- PC is set to APPLE_IBOOT_BASE
- SP is valid (within DRAM)
- First instruction fetch is from iBoot region

## Constraints Met

- ✅ PC set to iBoot entry
- ✅ Correct EL (EL1)
- ✅ Stack pointer valid
- ✅ Minimal context (only DT address in X0)