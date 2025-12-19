---
title: Apple System Registers (ARM64e)
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/cpu/system-registers.md
project-relevance:
  Emulator must implement or stub these registers to allow guest kernels to boot without undefined instruction faults.
confidence: high
---

## Extracted Facts

### Register Groups

#### HID (Hardware Implementation Defined)
- Used for CPU configuration and "chicken bits" (feature disables/workarounds).
- Separate registers for P-cores (HID) and E-cores (EHID).
- **Core Registers**: `SYS_APL_HID0_EL1` to `SYS_APL_HID18_EL1`.
- **E-Core Registers**: `SYS_APL_EHID0_EL1` to `SYS_APL_EHID20_EL1`.
- **Key Fields**:
    - `HID0[20]`: Loop Buffer Disable.
    - `HID1[54]`: Trap SMC (also `EHID20[8]`).
    - `HID4[11]`: Disable DC MVA Ops.
    - `HID18[14]`: HVC Speculation Disable.
    - `HID11[15]`: Workaround for bug 55719865.

#### ACC/CYC (Core Complex & Power)
- `SYS_APL_ACC_OVRD_EL1`: Power down overrides, deep sleep enable [34].
- `SYS_APL_CYC_OVRD_EL1`: WFI behavior ([0] Disable WFI Return), FIQ/IRQ disable bits.
- `SYS_APL_ACC_CFG_EL1`: Branch predictor sleep state.

#### Performance Monitors (PMIs)
- Apple uses custom PMCs (Performance Monitor Counters).
- `SYS_APL_PMC0`..`PMC9`: 48-bit (M1) or 64-bit (M2) counters.
- `SYS_APL_PMCR0_EL1`: Main control.
    - [10:8] Interrupt mode (1=PMI, 2=AIC, 4=FIQ).
    - [19:12] Enable PMI for PMC #0-7.
- `SYS_APL_PMESR0_EL1` / `PMESR1_EL1`: Event selection.
- **Uncore PMCs**: `SYS_APL_UPMCx_EL1`, `SYS_APL_UPMCR0_EL1`.

#### Error Handling (LSU / L2C)
- `SYS_APL_LSU_ERR_STS_EL1`: Load/Store Unit error status.
- `SYS_APL_L2C_ERR_STS_EL1`: L2 Cache error status (Cluster level).
- `SYS_APL_L2C_ERR_ADR_EL1`: Fault address.
- `SYS_APL_L2C_ERR_INF_EL1`: Error info (reason).
- Guests check these on SError/FIQ.

#### Custom IPI (Inter-Processor Interrupt)
- Fast IPIs bypassing AIC.
- `SYS_APL_IPI_RR_LOCAL_EL1`: Target CPU [3:0].
- `SYS_APL_IPI_RR_GLOBAL_EL1`: Target CPU + Cluster [20:16].
- `SYS_APL_IPI_SR_EL1`: Status (Pending bit [0], write 1 to clear).

#### Timer Control (Virtualization)
- `SYS_APL_VM_TMR_LR_EL2`: Guest timer interrupt pending state.
- `SYS_APL_VM_TMR_FIQ_ENA_EL2`: Enable FIQ for CNTV/CNTP guest timers.
- `HACR_EL2[20]`: Mask guest CNTV timer (leaves FIQ pending in `VM_TMR_LR_EL2`).

#### ID Registers
- `MIDR_EL1`: PartNum identifies core type (e.g., Firestorm=0x23/35, Icestorm=0x22/34).
- `MPIDR_EL1`: Aff2 (0=E-core, 1=P-core), Aff1 (Cluster), Aff0 (CPU).

## Explicit Non-Facts / Unknowns
- Exact meaning of many "chicken bits" is unknown or just labeled "SpareBit".
- Some register encodings labeled `EL?`.

## Notes for Future Phases
- Core ID registers (`MIDR`, `MPIDR`) must match the emulated topology.
- Essential to implement `IPI_SR_EL1` and `IPI_RR_*` for SMP support if guest uses them (macOS does).
- Timer virtualization registers are critical for guest timekeeping stability.
