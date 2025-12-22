# Phase 7b: EL1 Vector Content Expectations (Observation)

## Scope note (boot-chain simulation)
This phase uses a **boot-chain simulation** payload to install a minimal EL1 vector table (distinguishable entry stubs) and then trigger a deterministic exception. No real exception handling is implemented.

- EL1 entry is provided by the Phase 7a shim (`output/phase7/phase7a_handoff_el1.bin`).
- Vector table payload: `scripts/phase7/phase7b_vector_table_probe.s` → `output/phase7/phase7b_vector_table_probe.bin`.
- Each vector entry:
  1) emits a 2-byte UART marker (eg `SX`)
  2) executes `ERET`

This preserves “natural failure” by returning to the faulting instruction, which re-triggers the exception.

## 1) Which vector entries are hit
Across runs 1–3, the exception consistently vectors to:
- **Current EL, SPx, Synchronous** (offset `0x200` from `VBAR_EL1`)

Evidence (run1; same in run2/run3):
- `Phase6b: MSR VBAR_EL1 value=0x801000800 pc=0x801000030 EL=1`
- `Taking exception 1 [Undefined Instruction] on CPU 0`
- `...to EL1 PC 0x801000a00 PSTATE 0x3c5`

Vector offset proof:
- `0x801000a00 - 0x801000800 = 0x200` → sync exception with SPx.

Console marker evidence (run1):
- After `B7`, repeated `SX` is emitted, indicating execution reached the **SPx synchronous** vector stub.

## 2) What happens immediately after vector entry
The vector stub code at `0x801000a00` executes and reaches `ERET`:
- `0x801000a24:  d69f03e0  eret`

Immediately after returning, execution re-enters the same exception repeatedly (because the faulting instruction is re-executed).

## 3) Whether the kernel attempts to return or continues
Observed behavior indicates a **return attempt path is expected** at minimum:
- The minimal stub’s `ERET` is executed successfully.
- The system repeatedly returns to the faulting context and re-triggers the same synchronous exception.

This does **not** mean the kernel expects exceptions to be “handled” by firmware/emulator; it only demonstrates that the environment must provide executable vector content capable of returning (or at least transferring control deterministically).

## 4) Boundary statement: vector existence vs behavior
**Vector existence requirement (minimum reality):**
- There must be valid, executable code at the EL1 vector target address (and `VBAR_EL1` must point to it).

**Vector behavior requirement (NOT implemented here):**
- Whether the OS expects the vector to log, panic, or recover is OS-specific and requires real handler logic.

Phase 7b shows that merely having vectors *exist* (with trivial `ERET`) changes the failure mode from:
- **Phase 7a:** Prefetch abort on missing vector code

to:
- **Phase 7b:** deterministic re-entry into the same synchronous exception (UNDEF from `HVC #0`) with confirmed execution of the vector stub.

## Repeatability
The key markers are repeatable across runs 1–3:
- `VBAR_EL1 = 0x801000800` at `EL=1`
- exception vector target `EL1 PC = 0x801000a00`
- vector stub reaches `ERET` at `0x801000a24`

Evidence logs:
- `output/phase7/phase7b_run1.qemu.log`
- `output/phase7/phase7b_run2.qemu.log`
- `output/phase7/phase7b_run3.qemu.log`
