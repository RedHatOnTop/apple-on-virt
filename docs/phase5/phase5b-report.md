# Phase 5b Report: Console (UART) Contract

## Scope
Implement the minimal UART contract required for observable guest output. DRAM/memory mapping from Phase 5a is unchanged.

## UART MMIO address used
* UART0 base: `0x0000_0002_3520_0000`
* UART0 size: `0x0000_4000` (16KB)

Source: `docs/collected/memory-model/soc-address-map.md` (UART0 entry) and `docs/constraints/emulator-responsibility.md`.

## Implementation (minimal)
Files changed:
* `emulator/qemu-apple-silicon/hw/apple/platform/platform_state.h`
  * Added constants: `APPLE_UART0_BASE`, `APPLE_UART0_SIZE`
* `emulator/qemu-apple-silicon/hw/apple/apple_machine.[ch]`
  * Added a single MMIO `MemoryRegion` at `APPLE_UART0_BASE`
  * Read behavior: returns a fixed non-zero value (`0xFF..`) (dummy)
  * Write behavior: accepts any write and emits the low byte to host `stderr`

### Fields intentionally omitted
* No interrupts
* No FIFO
* No baud / timing
* No attempt to match any Apple UART register layout

## Registers accessed (observed)
From the Phase 5b smoke test payload:
* Write: offset `0x0` (byte write)

No other UART offsets are accessed in this phase.

## Evidence (logs)
### Build
In WSL:
```
./scripts/phase5/build_phase5b_uart_smoketest.sh
```

### Run
```
qemu-system-aarch64 \
  -M apple-silicon-bringup -m 256M \
  -nographic -monitor none \
  -dtb output/minimal_adt_with_memory.bin \
  -kernel output/phase5b_uart_smoketest.bin \
  -d guest_errors
```

Observed (first lines):
```
!Invalid read at addr 0x900000000, size 8, region '(null)', reason: rejected
```

Notes:
* The `!` is emitted by the UART0 MMIO write.
* The subsequent failure is an unmapped read at `0x900000000` (not UART-related).
* Additional `Invalid read at addr 0x200...` lines may follow due to exception/vector fetch behavior after the fault.

## Why Phase 5b is complete
* UART writes no longer crash (device exists and accepts writes).
* At least one character is emitted to host output.
* The subsequent failure is an unmapped access (not UART-related) and is reproducible.
