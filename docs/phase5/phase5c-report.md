# Phase 5c Report: Timer / Timebase Contract

## Scope
Implement the minimal concept of time required for Apple boot-chain progress: timer/timebase system registers must be readable and must not unexpectedly trap.

This phase does not implement interrupts or scheduling.

## Test payload
- Payload: `output/phase5c_timebase_smoketest.bin`
- Source: `scripts/phase5/phase5c_timebase_smoketest.s`

## Registers accessed (observed)
The Phase 5c smoke test explicitly reads:
- `CNTFRQ_EL0`
- `CNTVCT_EL0` (read twice)

## Returned values (observed)
Captured from `output/phase5c_timebase_qemu_log.txt` (`-d cpu,guest_errors`):

- `CNTFRQ_EL0` returned `0x0000000003b9aca0` (62,500,000)
- `CNTVCT_EL0` first read returned `0x000000000009c27d`
- `CNTVCT_EL0` second read returned `0x00000000000af4e8`

These values are monotonic across successive reads.

## Evidence (log excerpt)
The following register snapshot shows the sysreg reads succeeded (no trap) and values were captured:

```
PC=000000080010001c ... X01=0000000003b9aca0 X02=000000000009c27d
PC=0000000800100020 ... X03=00000000000af4e8
```

## Why the current failure is no longer timer-related
After the sysreg reads, execution reaches the existing controlled failure:

- `Invalid read at addr 0x900000000, size 8, region '(null)', reason: rejected`

This is a memory-map/unmapped-access failure and is reproducible. Timer-related reads are succeeding.

## Quality gates
- Gate 1 (timer-related reads succeed): ✓
- Gate 2 (no new crashes): ✓
- Gate 3 (failure point moved forward): N/A for this phase because the observed failure is not time-related; the timer contract is satisfied and execution proceeds to the existing unmapped-access failure.
- Gate 4 (reproducible): ✓
