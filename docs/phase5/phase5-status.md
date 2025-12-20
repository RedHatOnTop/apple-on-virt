# Phase 5 Status

Phase 5 is the contract phase: it establishes minimal hardware behaviors required for the Apple boot chain to make forward progress.

**Philosophy:** Hardware contracts, not fidelity.

## Status

- **Phase 5a — Memory contract:** ✓ COMPLETE
  - DRAM is mapped at the documented base.
  - Unmapped accesses are rejected and logged deterministically.

- **Phase 5b — UART / console contract:** ✓ COMPLETE
  - UART0 MMIO exists at the locked base address.
  - Writes are accepted and emit bytes for host-side observability.

- **Phase 5c — Timer / timebase contract:** ✓ COMPLETE
  - Architectural timer sysregs are readable and do not unexpectedly trap.
  - Values are stable/monotonic (see `phase5c-report.md`).
