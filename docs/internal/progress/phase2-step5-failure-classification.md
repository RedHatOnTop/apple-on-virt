# Phase 2 Step 5: Failure Classification

## Objective

Classify how iBoot fails or proceeds.

## Test Environment

### Test Binary

A simple test binary was used to verify the execution path:

```asm
// test_iboot.s
_start:
    mov x1, #0x1234
    mov x2, #0x5678
loop:
    wfi
    b loop
```

### Observed Behavior

With test binary:
- **Result**: Emulator runs, CPU executes WFI loop
- **Classification**: Execution proceeds (expected for test)

## Failure Classification Framework

### Category 1: Immediate Abort

**Definition**: iBoot fails within first few instructions

**Possible Causes**:
- Invalid entry point
- Missing initial CPU state
- Immediate exception

**Observable Signs**:
- Very fast exit (< 1 second)
- CPU exception at low address
- No output on serial

### Category 2: Platform Rejection

**Definition**: iBoot detects incompatible platform and refuses to proceed

**Possible Causes**:
- Unrecognized platform-id
- Unrecognized board-id
- Unrecognized chip-id
- Missing expected Device Tree properties

**Observable Signs**:
- Short execution then halt
- Possible error output on serial
- Consistent failure point

### Category 3: Hardware Missing

**Definition**: iBoot tries to access hardware that doesn't exist

**Possible Causes**:
- Missing interrupt controller
- Missing timer
- Missing UART
- Missing other Apple-specific devices

**Observable Signs**:
- CPU exception (data abort at MMIO address)
- Execution proceeds then fails at specific point
- Address in FAR register indicates missing device

### Category 4: Deeper Execution Failure

**Definition**: iBoot runs significant code before failing

**Possible Causes**:
- Later-stage verification failure
- Missing firmware services
- boot.efi loading attempt

**Observable Signs**:
- Extended execution time
- Multiple phases visible
- Possible partial output

## Current Test Results

### Test Binary Results

| Test | Result |
|------|--------|
| Entry point reached | ✓ PASS |
| CPU executes code | ✓ PASS |
| WFI executes | ✓ PASS |
| Emulator stable | ✓ PASS |

### Real iBoot (Not Yet Tested)

Pending acquisition of iBoot binary from:
- IPSW file extraction
- Apple Developer resources

## Expected iBoot Behavior

Based on documentation, iBoot will likely:

1. **Early Init**: Read Device Tree, check platform identity
2. **Hardware Init**: Try to initialize display, storage
3. **Boot Selection**: Look for boot volume
4. **Fail**: Missing hardware or platform mismatch

Most likely failure: **Category 2 (Platform Rejection)** or **Category 3 (Hardware Missing)**

## Classification Procedure

When testing with real iBoot:

1. Run with timeout (30 seconds)
2. Observe exit behavior:
   - Immediate exit → Category 1
   - Quick exit (1-5 sec) → Category 2
   - Longer run then crash → Category 3 or 4
3. Check serial output
4. If possible, attach debugger and inspect PC/registers

## Deliverables

- ✓ Failure classification framework documented
- ✓ Test environment verified
- ⏳ Real iBoot testing pending binary acquisition