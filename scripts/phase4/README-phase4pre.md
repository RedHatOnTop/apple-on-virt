# Phase 4-pre: Minimal Boot Environment Setup

**Purpose**: Create executable environment for boot chain testing

---

## Prerequisites

### Windows (WSL2 Required)

1. **Install WSL2 with Ubuntu**:
   ```powershell
   wsl --install -d Ubuntu
   ```

2. **Inside WSL2, install toolchain**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y \
       binutils-aarch64-linux-gnu \
       qemu-system-aarch64 \
       build-essential
   ```

### Linux/macOS

```bash
# Debian/Ubuntu
sudo apt-get install binutils-aarch64-linux-gnu qemu-system-aarch64

# macOS with Homebrew
brew install aarch64-elf-gcc qemu
```

---

## Quick Start

### Step 1: Build Test Payload

```bash
cd /mnt/c/Users/jin14/OneDrive/문서/Projects/apple-on-virt
chmod +x scripts/phase4/build_test_payload.sh
./scripts/phase4/build_test_payload.sh
```

**Output**:
- `output/test_payload.bin` - Raw binary payload
- `output/test_payload.elf` - ELF with symbols
- `output/test_payload.dis` - Disassembly listing

### Step 2: Verify ADT Exists

```bash
ls -lh output/minimal_adt.bin
# Should be 96 bytes from Phase 4a
```

If missing:
```bash
python3 scripts/phase4/minimal_adt_gen.py output/minimal_adt.bin
```

### Step 3: Run QEMU Test

```bash
chmod +x scripts/phase4/run_qemu_test.sh
./scripts/phase4/run_qemu_test.sh
```

**Expected Behavior**:
- QEMU starts
- Test payload executes
- Eventually triggers fault or loops
- Console shows execution or QEMU log captures activity

### Step 4: Examine Results

```bash
# View QEMU log
cat output/qemu_log.txt

# Check for execution markers
grep -i "exception\|fault\|abort" output/qemu_log.txt
```

---

## Test Payload Behavior

The test payload (`test_payload.s`) performs 4 tests:

### TEST 1: Instruction Execution
- Sets x1 = 0xBEEFDEAD
- Verifies instructions execute

### TEST 2: Memory Access
- Writes 0xBABECAFE to DRAM + 0x1000
- Reads back and verifies
- **Fail marker**: x20 = 0x0001DEAD

### TEST 3: ADT Visibility
- Reads ADT header at DRAM + 0x10000
- Checks property_count == 2
- **Fail marker**: x20 = 0x0002DEAD

### TEST 4: Controlled Failure
- Accesses unmapped address 0x2_0000_0000
- Should trigger synchronous abort
- **No fault marker**: x20 = 0x0003DEAD

### Success Path
- All tests pass
- Fault triggers as expected
- QEMU log shows exception

---

## Memory Layout

```
QEMU virt machine (default):

0x0000_0000 - 0x3FFF_FFFF : Flash/ROM region
0x4000_0000 - 0x4FFF_FFFF : RAM region (256MB)

Boot image layout:
0x4000_0000 : Bootloader (sets x0, jumps to payload)
0x4000_1000 : Test payload
0x4001_0000 : ADT (minimal_adt.bin)
```

**Note**: QEMU virt machine uses different RAM base than real Apple Silicon (0x8_0000_0000).
This is acceptable for Phase 4-pre as we're testing execution, not Apple-specific addresses.

---

## Troubleshooting

### QEMU not found
```bash
which qemu-system-aarch64
# If not found:
sudo apt-get install qemu-system-aarch64
```

### Toolchain not found
```bash
which aarch64-linux-gnu-as
# If not found:
sudo apt-get install binutils-aarch64-linux-gnu
```

### Payload build fails
Check that you're in WSL2 (if on Windows):
```bash
uname -a
# Should show "Linux" and "WSL2"
```

### QEMU hangs
This is expected - payload enters infinite loop after tests.
Press `Ctrl+A`, then `X` to exit QEMU.

Or use timeout:
```bash
timeout 5s ./scripts/phase4/run_qemu_test.sh
```

---

## Understanding Results

### Success Indicators

**Execution Verified**:
- QEMU log shows CPU state
- PC advances past entry point
- No immediate crash

**Memory Working**:
- No data abort on DRAM access
- Test progresses past memory test

**ADT Accessible**:
- No data abort on ADT read
- Test progresses past ADT test

**Fault Triggered**:
- Exception logged in QEMU output
- PC at fault instruction

### Failure Indicators

**No Execution**:
- QEMU exits immediately
- No CPU state in log
- **Fix**: Check bootloader, entry point

**Memory Fault**:
- Data abort before ADT test
- x20 = 0x0001DEAD
- **Fix**: Check RAM configuration

**ADT Not Found**:
- Data abort at ADT read OR
- x20 = 0x0002DEAD
- **Fix**: Verify ADT placement

**No Fault**:
- Hangs after fault test
- x20 = 0x0003DEAD
- **Fix**: This is actually informative - shows unmapped access doesn't fault

---

## Next Steps

Once this environment works:

1. **Phase 4b**: Replace test payload with iBoot
2. **Adjust memory map** to Apple Silicon layout (0x8_0000_0000)
3. **Add devices** as needed (UART, watchdog, etc.)
4. **Capture real failures** from iBoot execution

This phase builds the arena. The fight starts later.

---

## Files Created

| File | Purpose |
|------|---------|
| `test_payload.s` | AArch64 assembly test code |
| `build_test_payload.sh` | Build script |
| `run_qemu_test.sh` | QEMU launch script |
| `README-phase4pre.md` | This document |

---

## Known Limitations

### Not Apple Silicon
- Using generic ARMv8-A CPU (cortex-a72)
- No arm64e features (PAC, BTI)
- No Apple system registers
- No Apple memory map

**Acceptable**: Phase 4-pre tests execution, not Apple specifics.

### No Real Devices
- No UART implementation
- No AIC (interrupt controller)
- No PMGR (power management)

**Acceptable**: Add in Phase 4b when needed.

### Simplified Memory
- Using QEMU virt machine default (0x4000_0000)
- Not Apple DRAM base (0x8_0000_0000)

**Acceptable**: Will adjust in Phase 4b.

---

**Phase 4-pre Objective**: Prove code can execute and ADT can be delivered.

**Success = Execution + Observability**

Not success = Perfect Apple emulation (that comes later).
