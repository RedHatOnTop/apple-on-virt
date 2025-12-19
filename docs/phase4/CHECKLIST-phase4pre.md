# Phase 4-pre Execution Checklist

**Purpose**: Step-by-step validation of Phase 4-pre environment

---

## Prerequisites

### Windows Users (WSL2 Required)

- [ ] WSL2 installed (`wsl --install -d Ubuntu`)
- [ ] Ubuntu instance running
- [ ] Can access project files from WSL (`/mnt/c/Users/...`)

### Linux/macOS Users

- [ ] Native shell available
- [ ] Project files accessible

---

## Toolchain Installation

### Inside WSL2/Linux

```bash
# Update package list
sudo apt-get update

# Install cross-compiler
sudo apt-get install -y binutils-aarch64-linux-gnu

# Install QEMU
sudo apt-get install -y qemu-system-aarch64

# Verify installations
aarch64-linux-gnu-as --version
qemu-system-aarch64 --version
```

**Checklist**:
- [ ] `aarch64-linux-gnu-as` found
- [ ] `qemu-system-aarch64` found
- [ ] Both versions displayed correctly

---

## Build Test Payload

```bash
cd /mnt/c/Users/jin14/OneDrive/문서/Projects/apple-on-virt

# Make scripts executable
chmod +x scripts/phase4/build_test_payload.sh
chmod +x scripts/phase4/run_qemu_test.sh

# Build payload
./scripts/phase4/build_test_payload.sh
```

**Expected Output**:
```
Building test payload...
✓ Test payload built:
  ELF:    output/test_payload.elf
  Binary: output/test_payload.bin
  Size:   XXX bytes
  Disasm: output/test_payload.dis
```

**Checklist**:
- [ ] Build completes without errors
- [ ] `output/test_payload.bin` exists
- [ ] `output/test_payload.elf` exists
- [ ] `output/test_payload.dis` exists
- [ ] File sizes reasonable (~512 bytes for .bin)

---

## Verify ADT Exists

```bash
ls -lh output/minimal_adt.bin
```

**Expected**:
```
-rw-r--r-- 1 user user 96 Dec 19 XX:XX output/minimal_adt.bin
```

**If Missing**:
```bash
python3 scripts/phase4/minimal_adt_gen.py output/minimal_adt.bin
```

**Checklist**:
- [ ] ADT file exists
- [ ] Size is exactly 96 bytes

---

## Run QEMU Test

```bash
./scripts/phase4/run_qemu_test.sh
```

**Expected Behavior**:
1. Script shows configuration
2. Builds bootloader
3. Creates boot image
4. Launches QEMU
5. QEMU runs (may appear to hang - this is normal)
6. Press `Ctrl+A`, then `X` to exit QEMU

**Checklist**:
- [ ] Script runs without errors
- [ ] Boot image created
- [ ] QEMU starts
- [ ] QEMU displays output OR runs silently
- [ ] Can exit QEMU with `Ctrl+A`, `X`

---

## Examine Results

### Check QEMU Log

```bash
cat output/qemu_log.txt
```

**Look For**:
- CPU state dumps
- Exception messages
- Memory access logs
- PC (program counter) values

**Checklist**:
- [ ] Log file exists
- [ ] Log is not empty
- [ ] Log contains CPU or exception information

### Search for Exceptions

```bash
grep -i "exception\|abort\|fault" output/qemu_log.txt
```

**Expected**: Either exception logged OR no output (both are valid)

**Checklist**:
- [ ] Command runs
- [ ] Results noted (exception found OR not found)

### Check Boot Image

```bash
hexdump -C output/boot_image.bin | head -30
```

**Expected**: Bootloader code at start, ADT data at offset 0x10000

**Checklist**:
- [ ] Hexdump shows data
- [ ] Bootloader instructions visible (ARM opcodes)
- [ ] ADT visible at appropriate offset

---

## Test Result Interpretation

### Success Scenarios

**Scenario 1: Exception Logged**
- QEMU log contains exception at ~0x200000000
- Test 4 (controlled fault) worked
- ✓ SUCCESS

**Scenario 2: QEMU Hangs**
- No exception logged
- QEMU continues running
- Payload in infinite loop
- ✓ ACCEPTABLE (fault didn't trigger, but execution worked)

**Scenario 3: Immediate Exit**
- QEMU exits quickly
- Log shows CPU state
- May indicate early hang
- ✓ PARTIAL SUCCESS (execution started)

### Failure Scenarios

**Scenario A: Build Fails**
- Error during `build_test_payload.sh`
- ✗ Check toolchain installation

**Scenario B: QEMU Crashes**
- QEMU exits with error
- ✗ Check QEMU installation or boot image

**Scenario C: No Log Output**
- `qemu_log.txt` empty or missing
- ✗ Check QEMU command line options

---

## Validation Checklist

### Infrastructure

- [ ] WSL2/Linux environment ready
- [ ] Toolchain installed and working
- [ ] QEMU installed and working
- [ ] Project files accessible

### Build

- [ ] Test payload builds successfully
- [ ] ADT file present (96 bytes)
- [ ] Boot image created
- [ ] No build errors

### Execution

- [ ] QEMU starts
- [ ] Boot image loads
- [ ] Code executes (based on log or behavior)
- [ ] Can exit QEMU

### Observability

- [ ] QEMU log file created
- [ ] Log contains information (CPU state or exceptions)
- [ ] Serial output connected (if used)
- [ ] Can examine results

---

## Documentation Update

After successful execution, update:

**File**: `docs/phase4/phase4-pre-report.md`

**Section**: 8. TEST RESULTS

**Add**:
1. Test execution date/time
2. Test outcome (success/partial/failure)
3. QEMU log excerpts
4. Screenshots (if applicable)
5. Any unexpected behavior
6. Register states (if captured)

---

## Phase 4-pre Completion Criteria

### All Must Be True

- [x] Infrastructure created (scripts, payload, docs)
- [ ] Tests executed successfully
- [ ] Results documented
- [ ] Execution proven (code ran)
- [ ] ADT accessibility confirmed (or failure logged)
- [ ] Faults observable (logged or reproducible)

### Phase 4-pre Complete When

✓ Infrastructure complete (DONE)  
✓ Tests run (PENDING)  
✓ Results captured (PENDING)  
✓ Phase 4b can begin (READY)

---

## Next Steps After Completion

### Immediate

1. **Update Report**: Add test results to phase4-pre-report.md
2. **Capture Artifacts**: Save screenshots, logs, notes
3. **Mark Complete**: Update STATUS.md

### Transition to Phase 4b

1. **Obtain iBoot**: Extract and (attempt to) decrypt
2. **Adjust Memory**: Change base to 0x8_0000_0000
3. **Add Devices**: Implement UART first
4. **Run iBoot**: Replace test payload
5. **Iterate**: Fix failures one by one

---

## Troubleshooting

### WSL2 Can't Find Files

**Problem**: `/mnt/c/Users/...` path doesn't exist

**Solution**:
```bash
# Check WSL mount
ls /mnt/c/

# If empty, check WSL config
cat /etc/wsl.conf

# Should have:
[automount]
enabled = true
```

### Toolchain Not Found

**Problem**: `aarch64-linux-gnu-as: command not found`

**Solution**:
```bash
sudo apt-get update
sudo apt-get install binutils-aarch64-linux-gnu
which aarch64-linux-gnu-as
```

### QEMU Not Found

**Problem**: `qemu-system-aarch64: command not found`

**Solution**:
```bash
sudo apt-get install qemu-system-aarch64
which qemu-system-aarch64
```

### Build Script Not Executable

**Problem**: `Permission denied: ./build_test_payload.sh`

**Solution**:
```bash
chmod +x scripts/phase4/build_test_payload.sh
chmod +x scripts/phase4/run_qemu_test.sh
```

### QEMU Hangs

**Expected**: Payload enters infinite loop after tests

**Solution**: 
- Press `Ctrl+A`, then `X` to exit
- OR use timeout: `timeout 5s ./scripts/phase4/run_qemu_test.sh`

---

## Quick Reference

### Build Command
```bash
./scripts/phase4/build_test_payload.sh
```

### Run Command
```bash
./scripts/phase4/run_qemu_test.sh
```

### Exit QEMU
Press: `Ctrl+A`, then `X`

### View Log
```bash
cat output/qemu_log.txt
```

### Clean Build
```bash
rm output/test_payload.* output/bootloader.* output/boot_image.bin
```

---

**Phase 4-pre Checklist Complete**: When all boxes checked and results documented.

**Next**: Phase 4b - Real boot chain testing.
