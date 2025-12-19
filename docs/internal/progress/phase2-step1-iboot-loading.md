# Phase 2 Step 1: iBoot Binary Handling

## Objective

Load an unmodified iBoot binary into memory.

## Implementation

### iBoot Loader Module

**Files Created:**
- `hw/apple/iboot_loader.h` - Interface definition
- `hw/apple/iboot_loader.c` - Implementation

### Load Address

**Documented in `platform_state.h`:**

```c
#define APPLE_IBOOT_BASE    0x40100000  /* iBoot load address */
#define APPLE_IBOOT_SIZE    0x00F00000  /* 15MB max size */
```

### Memory Placement

```
0x40000000  +------------------+
            | Device Tree      | (64KB)
0x40010000  +------------------+
            | Boot Args        | (960KB)
0x40100000  +------------------+ <- iBoot loaded here
            | iBoot Binary     | (up to 15MB)
            |                  |
0x41000000  +------------------+
            | Kernel Region    |
```

### API

```c
/* Load iBoot from file */
int apple_iboot_load(const char *filename, IBootLoadInfo *info);

/* Get entry point */
uint64_t apple_iboot_get_entry(const IBootLoadInfo *info);
```

### Usage

iBoot is loaded via the `-kernel` option:

```bash
./qemu-system-apple64e -M apple-silicon-bringup \
    -kernel /path/to/iBoot.bin \
    -nographic
```

### Constraints Met

- ✅ iBoot treated as opaque code
- ✅ No disassembly
- ✅ No patching
- ✅ Load address documented (0x40100000)

## Quality Gate

**iBoot must be resident in memory before execution.**

Verification:
- `apple_iboot_load()` returns 0 on success
- `IBootLoadInfo.loaded` is true
- Info report shows load address and size

## Deliverables

1. ✅ iBoot loader code (`iboot_loader.c`, `iboot_loader.h`)
2. ✅ Documentation of memory placement (this file)