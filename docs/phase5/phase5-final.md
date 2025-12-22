# Phase 5 Final: Contracts Sealed

Phase 5 is the hardware-contract phase. It defines the *minimum sufficient* hardware surface required to reach and observe kernel (OS) code execution.

## Phase 5 subphase summary (5a–5g)

- **Phase 5a — Memory contract**
  - Proven: DRAM mapping is valid and unmapped accesses fail deterministically.

- **Phase 5b — UART contract**
  - Proven: UART output exists and provides reliable guest-to-host observability.

- **Phase 5c — Monotonic timer contract**
  - Proven: a stable/monotonic time source exists and is readable by guest code.

- **Phase 5d — Interrupt controller existence**
  - Proven: an interrupt controller exists (at minimum: presence/wiring sufficient for bring-up assumptions).

- **Phase 5e — CPU sysreg sanity (RAZ/WI)**
  - Proven: required sysregs are safe to access (do not unexpectedly trap; RAZ/WI where appropriate).

- **Phase 5f — ADT + boot_args delivery / handoff**
  - Proven: a valid ADT is delivered and a valid boot_args buffer is handed to the kernel entry.
  - Proven: execution reaches OS code (kernel payload) after handoff.

- **Phase 5g — Final verification / responsibility exhaustion**
  - Proven: remaining failures are deterministic, occur inside OS code, and are not preceded by missing-hardware (MMIO/sysreg) accesses.
  - Verdict: "Hardware responsibility is exhausted at Phase 5."

## Phase 5 closure (CANONICAL)

Phase 5 is CLOSED.

- The Phase 5 hardware contract is now immutable.
- Reopening Phase 5 to add devices, adjust MMIO, change memory layout, or alter ADT/boot_args is explicitly forbidden without a new phase definition.

"Any future failure is, by definition, outside Phase 5 scope."

## Final Phase 5 declaration

"Phase 5 is complete.
The emulator now provides a complete hardware contract.
Further work transitions from hardware emulation to OS interaction."
