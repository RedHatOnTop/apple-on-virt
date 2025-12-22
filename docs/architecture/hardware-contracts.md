# Hardware Contracts (Phase 5 Seal)

This document canonically defines the hardware contract exposed by the emulator as of Phase 5, and permanently seals what is in-scope for “hardware emulation” versus out-of-scope OS behavior.

## What the emulator IS

- A single, fixed machine model with a locked memory and MMIO map.
- A contract-driven platform that provides only the minimal hardware surface required for kernel (OS) code execution.
- A QEMU-based, heavily modified, single-purpose emulator targeting an Apple-like arm64e platform.

## What the emulator IS NOT

- A general-purpose QEMU fork.
- A collection of experimental machines.
- A best-effort macOS emulator.
- A full Apple SoC model.

## Phase 5 hardware contract (LOCKED)

Phase 5 established the following *sufficient* hardware behaviors for kernel execution and observation:

- **DRAM mapping is valid** (guest RAM exists at the documented base) and unmapped accesses fail deterministically.
- **UART output exists** for observability.
- **Monotonic timer exists** (timebase progresses and is readable).
- **Interrupt controller exists** (presence and basic wiring are established).
- **CPU sysreg sanity**: required sysregs are safe (RAZ/WI where appropriate) and do not unexpectedly trap.
- **ADT delivery is valid** (guest receives a valid Apple Device Tree blob).
- **boot_args handoff is valid** (kernel receives a valid boot_args pointer/contents).
- **OS code execution is confirmed** (control reaches kernel payload code).

## Phase 5 immutability

Phase 5 is CLOSED. The above contract is permanent for this project baseline.

- Any change to devices, MMIO mappings, ADT, boot_args, CPU entry conditions, or sysreg handling is **not** a “Phase 5 fix”; it is a **new phase definition**.
- Hardware work is permitted only under an explicitly defined new phase with explicit scope and acceptance criteria.

See also:
- `docs/phase5/phase5g-verdict.md`
- `docs/phase5/phase5-final.md`
