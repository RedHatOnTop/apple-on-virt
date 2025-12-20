# Architecture Overview

Apple-on-Virt is an emulator project focused on bringing up the unmodified Apple boot chain (iBoot → boot.efi → kernelcache) in a controlled, observable environment.

This is an Apple-like platform defined by boot-chain contracts.

## What this project is

- A single, fixed machine model that exposes just enough platform surface for boot-chain progress.
- A contract-driven implementation: components exist because the boot chain touches them.
- A bring-up environment designed for reproducible failure analysis.

## What this project is not

- Not a full Apple SoC model.
- Not a cycle-accurate simulator.
- Not a generic ARM VM platform.

## Core contracts (current)

- **Phase 4 (ADT)**: The guest receives an Apple Device Tree (ADT) binary blob and parsing progresses past format validation.
- **Phase 5a (Memory)**: DRAM exists at the documented base and unmapped accesses fail deterministically.
- **Phase 5b (UART)**: UART0 MMIO exists and accepts writes for observability.

All further progress is obtained by extending contracts only when the boot chain demands it.
