# Project Identity (Locked)

This document is the canonical identity statement for the project.

## What this project IS

Apple-on-Virt is **a QEMU-based, heavily modified, single-purpose emulator targeting an Apple-like arm64e platform**.

It exists to provide a fixed, contract-driven platform surface sufficient for the Apple-like boot chain and kernel code execution to run far enough for deterministic observation.

## What this project IS NOT

- A general-purpose QEMU fork.
- A collection of experimental machines.
- A best-effort macOS emulator.
- A “try everything until it boots” project.

## Phase 5 identity lock

Phase 5 establishes sufficient hardware for kernel execution.

The Phase 5 verdict is canonical:

"Hardware responsibility is exhausted at Phase 5."

From this point forward, any work that changes devices, MMIO, memory layout, ADT, boot_args, sysreg handling, or CPU entry conditions is not “continuing Phase 5”; it is a new phase with explicitly defined scope.
