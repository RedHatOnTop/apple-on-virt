# Fork Policy

This document defines the policy for the QEMU fork used in the Apple Silicon platform reconstruction project.

## Core Principles

### 1. No Upstreaming

This fork will NEVER be submitted upstream to QEMU.

**Rationale:**
- Our changes are too invasive and single-purpose
- QEMU upstream requires generic, multi-platform solutions
- Apple Silicon specifics don't belong in upstream QEMU
- We prioritize our goals over upstream compatibility

### 2. No Multi-Machine Support

This fork supports exactly ONE machine: `apple-silicon-bringup`.

**Rationale:**
- Simplifies implementation
- Reduces attack surface
- Focuses development effort
- Eliminates machine selection complexity

### 3. No Generic ARM Support

This fork does NOT support generic ARM64 systems.

**Rationale:**
- ARM virt machine is not Apple Silicon
- SBSA reference is not Apple Silicon
- Generic boards add complexity without value
- Clear scope prevents feature creep

### 4. No Accelerator Support

This fork uses TCG (software emulation) only.

**Rationale:**
- KVM requires compatible host CPU
- HVF is macOS-only
- TCG provides cross-platform consistency
- Debugging is easier without hardware acceleration

## What We Modify

### Allowed Modifications

1. **Machine Models**
   - Add apple-silicon-bringup machine
   - Disable all generic ARM machines
   - Customize machine initialization

2. **CPU Models**
   - Add apple-arm64e CPU type
   - Extend with Apple-specific features
   - Implement arm64e semantics

3. **Device Models**
   - Add Apple-compatible devices
   - Implement Apple interrupt controller
   - Add Apple timer device

4. **Build System**
   - Add apple64e target
   - Disable unnecessary targets
   - Customize build configuration

5. **Memory Layout**
   - Implement Apple Silicon memory map
   - Add secure region handling
   - Configure MMIO ranges

### Prohibited Modifications

1. **Core TCG**
   - Do not modify TCG core
   - Do not change instruction semantics
   - Extend via CPU model instead

2. **Core Memory System**
   - Do not change MemoryRegion internals
   - Use public APIs only
   - Extend via device callbacks

3. **Generic Infrastructure**
   - Do not change QOM core
   - Do not modify block layer core
   - Do not change main loop

## Version Policy

### Base Version

- Fork based on QEMU 9.2.4
- No automatic upstream sync
- Manual backports only when critical

### Update Policy

We will NOT automatically track QEMU upstream because:
- Breaking changes are common
- Our modifications are invasive
- Stability is more important than latest features

### When to Update

Consider upstream sync only when:
1. Critical security fix needed
2. Specific bug fix required
3. Major TCG improvement available
4. ARM64 correctness fix needed

### How to Update

1. Create branch from current state
2. Manually merge specific commits
3. Resolve conflicts preserving our changes
4. Full regression testing required

## Code Organization

### Our Code

All Apple-specific code lives in clearly marked locations:

```
hw/apple/           # Apple machine model
target/apple-arm64e/ # Apple CPU model (future)
```

### Modified QEMU Code

When modifying QEMU files:
- Add clear comments marking our changes
- Keep modifications minimal
- Document why change is needed

Example:
```c
/* Apple-on-Virt: Added apple-silicon-bringup machine */
arm_ss.add(when: 'CONFIG_APPLE_SILICON_BRINGUP', 
           if_true: files('../apple/apple_machine.c'))
```

## Build Configuration

### Supported Configuration

Only one build configuration is supported:

```bash
./configure --target-list=apple64e-softmmu \
            --disable-docs \
            --disable-gtk \
            --disable-sdl
```

### Required Options

- `--target-list=apple64e-softmmu`: Only our target
- No KVM/HVF: TCG only
- Minimal UI: Console only

### Disabled Features

- Documentation build
- GUI frontends
- User mode emulation
- All non-Apple targets

## Testing Policy

### What We Test

1. Machine initialization
2. Idle loop execution
3. Memory access
4. Device registration
5. GDB attachment

### What We Do NOT Test

1. Generic ARM machines (disabled)
2. KVM acceleration (disabled)
3. GUI functionality (disabled)
4. User mode emulation (disabled)

## Documentation

### Required Documentation

Every major change must include:
1. Code comments explaining purpose
2. Phase completion report
3. Update to relevant docs

### Documentation Location

- `docs/`: Project documentation
- Code comments: Implementation details
- Git commits: Change rationale

## Summary

This fork exists for ONE purpose: Apple Silicon platform reconstruction.

- No upstreaming
- No multi-machine
- No generic ARM
- No accelerators

All decisions serve this single purpose.
