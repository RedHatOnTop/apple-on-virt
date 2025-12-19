# Failure Containment

This document describes how the emulator handles guest failures and ensures safe operation.

## Design Principles

1. **Guest failures do not crash the emulator**
2. **Failures are observable and recoverable**
3. **Host and guest state are isolated**

## Failure Types and Handling

### 1. CPU Exceptions

**Cause**: Guest code triggers ARM exception (undefined instruction, data abort, etc.)

**Handling**:
- QEMU's ARM CPU model catches the exception
- Exception is delivered to guest via exception vector
- If no exception handler: CPU loops at exception vector

**Observation**:
- Timeout behavior changes
- Register state shows exception occurred
- PC points to exception vector

**Recovery**: Restart emulator

### 2. Memory Access Faults

**Cause**: Guest accesses unmapped or protected memory

**Handling**:
- QEMU memory system catches the access
- Returns error to CPU
- CPU generates data/instruction abort exception

**Observation**:
- Same as CPU exception
- FAR register contains faulting address

**Recovery**: Restart emulator

### 3. Invalid iBoot Binary

**Cause**: Phase 2 loads corrupted or wrong binary

**Handling**:
- Binary loaded to memory
- CPU starts executing
- Invalid instructions cause exceptions

**Observation**:
- Immediate exception after start
- PC at exception vector
- Instruction at entry point invalid

**Recovery**: Provide correct binary

### 4. Platform State Mismatch

**Cause**: iBoot expects different platform state

**Handling**:
- iBoot may read wrong values
- May cause iBoot to fail or hang

**Observation**:
- Timeout behavior
- No output on serial
- CPU state shows iBoot execution stopped

**Recovery**: Adjust platform state

## State Isolation

### Guest-Accessible State

| Region | Address | Size |
|--------|---------|------|
| DRAM | 0x40000000 | 1GB |
| MMIO | 0x20000000 | 512MB |

Guest can only access these regions.

### Host-Only State

| Structure | Location | Purpose |
|-----------|----------|---------|
| ApplePlatformBootLayer | C heap | Platform config |
| AppleMachineState | C heap | Machine state |
| QEMU internal | Various | Emulator state |

Guest cannot access host state.

### Memory Boundaries

```
Guest Memory (accessible via CPU):
    0x40000000 - 0x80000000: DRAM
    0x20000000 - 0x40000000: MMIO

Host Memory (not guest-accessible):
    ApplePlatformBootLayer structure
    QEMU internal structures
    Host process heap
```

## Watchdog Considerations

Phase 1.5 does not implement a hardware watchdog. Infinite loops are detected via:

1. **Timeout Testing**: External timeout (e.g., `timeout 3s`)
2. **Serial Silence**: No output indicates hang
3. **Manual Inspection**: QEMU monitor access

Future phases may add:
- Software watchdog timer
- Automatic timeout mechanism
- Heartbeat monitoring

## Recovery Procedures

### From CPU Exception

1. Stop emulator (Ctrl-C or timeout)
2. Check logs for exception info
3. Analyze failure cause
4. Restart with fixes

### From Hang

1. Stop emulator (Ctrl-C or timeout)
2. Use QEMU monitor (if accessible) to check state
3. Analyze CPU state and memory
4. Identify hang location

### From Platform Mismatch

1. Stop emulator
2. Review platform state requirements
3. Update `platform_state.h` values
4. Rebuild and restart

## Known Issues

### Shutdown Assertion

A device cleanup assertion occurs during QEMU shutdown. This:
- Does NOT affect guest execution
- Does NOT corrupt state
- Only manifests on exit

The emulator functionality is not impacted.

## Testing Failure Containment

### Test 1: Invalid Entry Point

```bash
# Create binary with invalid instruction
echo -ne '\x00\x00\x00\x00' > /tmp/invalid.bin

# Load and run (should handle gracefully)
./qemu-system-apple64e -M apple-silicon-bringup \
    -device loader,file=/tmp/invalid.bin,addr=0x40100000
```

Expected: Exception, then hang or loop

### Test 2: Memory Bounds

Guest code attempting to access 0xFFFFFFFF should:
1. Generate data abort
2. Not crash emulator

### Test 3: Timeout Behavior

```bash
timeout 3s ./qemu-system-apple64e -M apple-silicon-bringup
echo "Exit code: $?"
```

Expected: Exit code 124 (timeout)

## Summary

The emulator provides:
- **Exception Handling**: QEMU ARM CPU handles all exceptions
- **Memory Protection**: Unmapped regions cause faults, not crashes
- **State Isolation**: Guest cannot access host state
- **Observable Failures**: Failures can be detected and diagnosed

Guest failures are contained and do not compromise emulator stability.
