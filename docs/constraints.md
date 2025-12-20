# Project Constraints

This project is driven by boot-chain progress and reproducible failure analysis.

## Explicit goals

- **Boot-chain progress:** the unmodified Apple boot chain executes further with each satisfied contract.
- **Deterministic failure analysis:** failures are logged, reproducible, and attributable to a missing contract.

## Explicit non-goals

- **Secure Boot:** this project does not implement Apple Secure Boot.
- **SEP:** this project does not emulate or integrate the Secure Enclave Processor.
- **Exact Apple SoC emulation:** this project does not attempt to precisely emulate a specific Apple SoC.
