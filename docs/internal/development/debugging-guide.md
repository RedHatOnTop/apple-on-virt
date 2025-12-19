# Debugging Guide

This document describes how to debug the Apple Silicon platform emulator.

## GDB Debugging

### Status

GDB support is compiled into the emulator via QEMU's gdbstub. However, there is a known issue with shutdown-time assertions when using GDB options.

### Current Workaround

For Phase 1.5 and Phase 2, use alternative debugging methods:

1. **Serial Output**: Configure serial output to observe boot progress
2. **QEMU Monitor**: Use the QEMU monitor for state inspection
3. **Timeout Testing**: Verify execution by timeout behavior

### Expected Resolution

The shutdown assertion is a QEMU infrastructure issue unrelated to our machine model. It will be addressed in a future phase by:
1. Proper device tree registration for cleanup
2. Investigation of the DEVICE assertion path

## Alternative Debugging Methods

### 1. Serial Console

```bash
./qemu-system-apple64e -M apple-silicon-bringup \
    -serial stdio \
    -display none
```

This outputs serial data to stdout for debugging.

### 2. QEMU Monitor

```bash
./qemu-system-apple64e -M apple-silicon-bringup \
    -monitor stdio \
    -display none
```

Monitor commands for debugging:
- `info registers` - View CPU registers
- `x /fmt addr` - Examine memory
- `info mtree` - View memory tree
- `info cpus` - View CPU status

### 3. Logging

```bash
./qemu-system-apple64e -M apple-silicon-bringup \
    -d cpu,int,exec \
    -D qemu.log
```

Log options:
- `cpu` - CPU state changes
- `int` - Interrupts
- `exec` - Execution trace
- `in_asm` - Guest assembly
- `guest_errors` - Guest errors

## Failure Modes

### CPU Exception

If the guest code causes an exception:
1. CPU takes the exception
2. Exception vector is executed
3. Since no exception handler exists, CPU enters infinite loop
4. Observable via timeout behavior

### Memory Fault

If guest accesses invalid memory:
1. QEMU catches the access
2. Returns error/exception to guest
3. Does NOT crash emulator

### Invalid Instruction

If guest executes invalid instruction:
1. CPU raises undefined instruction exception
2. Exception handler runs (or loops)
3. Observable via execution trace

## Verification Tests

### Basic Execution

```bash
# Should timeout (exit 124) - proves idle loop is running
timeout 3s ./qemu-system-apple64e -M apple-silicon-bringup -display none
echo $?  # Expected: 124
```

### Machine Availability

```bash
./qemu-system-apple64e -M help | grep apple
# Expected: apple-silicon-bringup
```

### CPU Availability

```bash
./qemu-system-apple64e -cpu help | grep cortex-a76
# Expected: cortex-a76
```

## Known Issues

### Shutdown Assertion

**Symptom**: `DEVICE: Object ... is not an instance of type device`

**When**: During QEMU shutdown/cleanup

**Impact**: Does not affect guest execution, only cleanup

**Root Cause**: Device cleanup path accessing non-device object

**Status**: Tracked for future fix

## Phase 2 Debugging Strategy

When loading iBoot:

1. **Verify Load**: Check iBoot is placed at `APPLE_IBOOT_BASE`
2. **Serial Output**: iBoot may output to serial
3. **Timeout Behavior**: If iBoot fails, CPU will loop
4. **Memory Inspection**: Use monitor to check memory state

### Memory Addresses for Debugging

| Region | Address | Use |
|--------|---------|-----|
| Device Tree | 0x40000000 | Check FDT is present |
| iBoot | 0x40100000 | Verify iBoot loaded |
| Entry Point | 0x40100000 | CPU starts here |