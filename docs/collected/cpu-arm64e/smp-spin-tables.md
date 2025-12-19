---
title: SMP Spin-Up Protocol
derived-from:
  - docs/external/Asahi Linux Docs/docs/hw/cpu/smp.md
project-relevance:
  Required to boot secondary cores (SMP) in the emulator.
confidence: high
---

## Extracted Facts

### Hardware Components
- controlled via **ADT** nodes:
    - `/arm-io/pmgr[reg]`: Power Manager registers.
    - `/cpus/cpu<n>[cpu-impl-reg]`: CPU implementation registers (RVBAR).
    - `/cpus/cpu<n>[reg]`: CPU ID info (Core, Cluster, Die).

### PMGR Offsets
- **M1/M1 Pro/Max**: `0x54000` / `0x28000`? (Ambiguous in text, lists M2 Pro/Max separately).
- **M1 Series**: `0x54000`.
- **M2/M3**: `0x34000`.
- **Structure**:
    - `offset + 0x4`: System-wide CPU startup bitmask.
    - `offset + 0x8`: Cluster 0 (E-core) startup bitmask.
    - `offset + 0xc`: Cluster 1 (P-core) startup bitmask (offsets jump by 4 per cluster).

### Spin-Up Sequence
1.  **Set RVBAR**: Write start address to `cpu-impl-reg + 0x00` (RVBAR).
    - CPU0 RVBAR is locked by iBoot.
2.  **System Enable**: Set `(1 << cpu)` in `pmgr[offset + 0x4]`.
    - Enables "core alive" signal (needed for AIC).
3.  **Core Enable**: Set `(1 << core_index_in_cluster)` in `pmgr[(offset + 0x8) + 4*cluster_id]`.
    - Starts the core execution at RVBAR.

### Topology Info
- A11 quirk: ECPUs are 0-3, PCPUs are 4-5, all considered Cluster 0 (?).
- Modern chips usually separate clusters (Aff1 in MPIDR).

## Explicit Non-Facts / Unknowns
- Exact precise address of "cpu-impl-reg" is device dependent (must use ADT).

## Notes for Future Phases
- Emulator must map PMGR and handle writes to these offsets to trigger new threads/cores.
- Emulator must respect the RVBAR set at this stage.
