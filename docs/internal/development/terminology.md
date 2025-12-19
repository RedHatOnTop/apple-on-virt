# Terminology

This document defines canonical terminology used across the Apple-on-Virt project. Each term has exactly one meaning. No synonyms are allowed. Once a term is defined here, it must be used consistently in all documentation, code comments, and discussions.

## Core Architectural Terms

### Platform Boot Layer

**Definition:** The synthetic environment that establishes Apple Silicon platform state before macOS boot components execute.

**Usage:** Always "Platform Boot Layer", never "bootloader", "firmware", "bootstrap", or "pre-boot environment".

**Code comment example:**
```c
// Platform Boot Layer synthesizes secure boot context before iBoot entry
```

**Scope:** Includes memory map construction, device tree generation, secure boot context synthesis, and hardware identity initialization.

**Not:** Not a bootloader (does not load the OS), not firmware (does not provide runtime services), not a shim (does not translate interfaces).

### Machine Model

**Definition:** The fixed platform definition representing apple-silicon-bringup hardware configuration.

**Usage:** Always "Machine Model", never "board", "virtual machine", "platform model", or "hardware configuration".

**Code comment example:**
```c
// Machine Model instantiates Platform Boot Layer during initialization
```

**Scope:** Encompasses platform identity, memory layout definition, device topology, and coordination of initialization sequence.

**Not:** Not a board (no physical analogy), not a VM (not providing virtualization layer), not user-configurable.

### CPU Model

**Definition:** The apple-arm64e instruction execution implementation providing arm64e semantics.

**Usage:** Always "CPU Model", never "processor", "core", "vCPU", or "emulated CPU".

**Code comment example:**
```c
// CPU Model implements PAC instructions with semantic correctness
```

**Scope:** Includes instruction execution, exception level management, system register implementation, and PAC semantics.

**Not:** Not a generic ARM CPU, not a cycle-accurate simulator, not performance-equivalent to hardware.

### Device Layer

**Definition:** The collection of emulated devices exposing Apple-compatible interfaces to macOS.

**Usage:** Always "Device Layer", never "device model", "peripheral layer", or "hardware abstraction".

**Code comment example:**
```c
// Device Layer presents Apple-compatible storage interface
```

**Scope:** Encompasses all devices visible to macOS including storage, timers, interrupt controllers, and serial interfaces.

**Not:** Not a hardware abstraction layer (does not abstract generic hardware), not a device tree (that is a data structure).

## Boot Chain Terms

### iBoot

**Definition:** Apple's first-stage bootloader that executes after Platform Boot Layer synthesis.

**Usage:** Always "iBoot", never "bootloader", "stage-1", or "initial boot".

**Code comment example:**
```c
// Load iBoot binary at expected address without modification
```

**Scope:** The unmodified Apple bootloader binary responsible for loading boot.efi.

**Not:** Not part of the emulator, not modified, not replaced.

### boot.efi

**Definition:** Apple's EFI boot application that loads the kernelcache.

**Usage:** Always "boot.efi", never "bootloader", "EFI loader", or "stage-2".

**Code comment example:**
```c
// boot.efi inherits secure boot context from iBoot
```

**Scope:** The unmodified Apple boot application responsible for preparing kernel execution.

**Not:** Not a UEFI application (Apple proprietary), not part of the emulator, not modified.

### kernelcache

**Definition:** The macOS kernel binary with extensions pre-linked for boot.

**Usage:** Always "kernelcache", never "kernel", "XNU", "kernel image", or "prelinkedkernel".

**Code comment example:**
```c
// kernelcache expects arm64e CPU with PAC support
```

**Scope:** The complete kernel binary that boot.efi loads and transfers control to.

**Not:** Not the raw kernel (includes extensions), not modified by emulator.

### Boot Chain

**Definition:** The complete sequence from Platform Boot Layer through iBoot, boot.efi, to kernelcache execution.

**Usage:** Always "Boot Chain", never "boot sequence", "boot flow", or "boot process".

**Code comment example:**
```c
// Boot Chain integrity requires unmodified binaries
```

**Scope:** The entire trusted execution sequence that brings macOS from emulator start to kernel entry.

**Not:** Not just the bootloaders (includes platform synthesis), not a single stage.

## Security Terms

### Secure Boot Context

**Definition:** Platform state indicating successful boot chain verification and trusted execution.

**Usage:** Always "Secure Boot Context", never "secure state", "boot security", or "trust state".

**Code comment example:**
```c
// Secure Boot Context synthesized to indicate verified state
```

**Scope:** Registers, device tree properties, and platform state reflecting security status.

**Not:** Not UEFI Secure Boot (Apple proprietary), not a cryptographic proof, not a verification mechanism.

### Trust Synthesis

**Definition:** The process of creating platform state that indicates successful trust establishment.

**Usage:** Always "Trust Synthesis", never "trust bypass", "security bypass", or "verification skip".

**Code comment example:**
```c
// Trust Synthesis creates state expected after hardware verification
```

**Scope:** Setting security registers and platform state to reflect trusted execution path.

**Not:** Not bypassing security (security features remain active), not disabling verification, not a workaround.

### Platform Identity

**Definition:** The set of identifiers (platform ID, board ID, chip ID) representing hardware identity.

**Usage:** Always "Platform Identity", never "hardware ID", "device ID", or "system identity".

**Code comment example:**
```c
// Platform Identity values remain consistent across boot stages
```

**Scope:** All identifiers that macOS uses to recognize the platform as Apple Silicon.

**Not:** Not user-configurable, not dynamic, not related to MAC addresses or serial numbers.

### Security Semantics

**Definition:** The observable security behavior and policy enforcement that remains functional in emulation.

**Usage:** Always "Security Semantics", never "security behavior", "security features", or "protection mechanisms".

**Code comment example:**
```c
// Security Semantics preserved through PAC instruction implementation
```

**Scope:** The functional aspects of security features including PAC, memory protection, and privilege separation.

**Not:** Not hardware guarantees, not cryptographic verification, not complete security equivalence.

## CPU and Memory Terms

### arm64e

**Definition:** Apple's ARM64 extension with pointer authentication and additional ABI features.

**Usage:** Always "arm64e", never "ARM64E", "ARMv8.3", "ARM64", or "AArch64".

**Code comment example:**
```c
// arm64e instructions require PAC key register initialization
```

**Scope:** The specific instruction set architecture and ABI used by macOS on Apple Silicon.

**Not:** Not generic ARMv8 (Apple-specific extensions), not backward compatible with plain ARM64.

### PAC (Pointer Authentication Code)

**Definition:** Cryptographic signatures on pointers for control flow integrity.

**Usage:** Always "PAC", never "pointer auth", "pointer authentication", or "PAC codes" as plural.

**Code comment example:**
```c
// PAC operations execute with semantic correctness during boot
```

**Scope:** The pointer authentication instructions and their semantic behavior in the CPU Model.

**Not:** Not full cryptographic implementation (semantic during boot), not a single instruction.

### Exception Level (EL)

**Definition:** ARM privilege level determining accessible resources and operations.

**Usage:** Always "Exception Level" or "EL" with number, never "privilege level", "ring", or "mode".

**Code comment example:**
```c
// Kernel executes at Exception Level 1 (EL1)
```

**Scope:** EL0 (user), EL1 (kernel), EL2 (hypervisor), EL3 (secure monitor).

**Not:** Not x86 rings (ARM-specific), not simple user/kernel separation (more levels).

### Memory Map

**Definition:** The physical address space layout defining DRAM, MMIO, and reserved regions.

**Usage:** Always "Memory Map", never "memory layout", "address space", or "memory configuration".

**Code comment example:**
```c
// Memory Map follows Apple Silicon conventions for region types
```

**Scope:** The complete address space organization visible to the CPU Model and devices.

**Not:** Not virtual memory (that is translation tables), not page tables, not dynamic.

### Device Tree

**Definition:** The hierarchical data structure describing platform hardware to macOS.

**Usage:** Always "Device Tree", never "DT", "DTB", "device tree blob", or "FDT".

**Code comment example:**
```c
// Device Tree generation occurs after platform state initialization
```

**Scope:** The complete Apple-format tree with all nodes, properties, and values.

**Not:** Not Linux device tree format (Apple-specific), not configuration file, not modifiable by guest.

## Implementation Terms

### Semantic Correctness

**Definition:** Instruction behavior produces correct observable results without precise hardware equivalence.

**Usage:** Always "Semantic Correctness", never "functional correctness", "behavioral accuracy", or "logical equivalence".

**Code comment example:**
```c
// Semantic Correctness achieved through PAC context validation
```

**Scope:** The principle that operations must produce right results even if implementation differs from silicon.

**Not:** Not performance correctness, not cycle accuracy, not hardware simulation.

### Platform Fidelity

**Definition:** Accuracy of platform state reconstruction relative to genuine Apple Silicon.

**Usage:** Always "Platform Fidelity", never "accuracy", "precision", or "hardware equivalence".

**Code comment example:**
```c
// Platform Fidelity improvements eliminate need for kernel accommodations
```

**Scope:** The degree to which synthesized platform state matches genuine hardware expectations.

**Not:** Not complete hardware duplication, not performance parity, not silicon-level simulation.

### Kernel Accommodation

**Definition:** Minimal runtime intervention at specific kernel bring-up failure points.

**Usage:** Always "Kernel Accommodation", never "kernel patch", "kernel modification", or "kernel workaround".

**Code comment example:**
```c
// Kernel Accommodation provides platform state at documented failure point
```

**Scope:** Temporary, documented interventions that fulfill unmet platform assumptions during early boot.

**Not:** Not kernel patches (no code modification), not permanent, not security bypass.

### Version-Agnostic

**Definition:** Functioning across multiple macOS versions without version-specific code paths.

**Usage:** Always "Version-Agnostic", never "version independent", "universal", or "multi-version".

**Code comment example:**
```c
// Version-Agnostic design avoids macOS version detection
```

**Scope:** The principle that platform state and behavior work uniformly across Monterey, Ventura, Sonoma, and future releases.

**Not:** Not supporting multiple versions through branching, not maintaining version-specific patches.

## Device Terms

### Device Identity

**Definition:** How a device presents itself to macOS through device tree and register interface.

**Usage:** Always "Device Identity", never "device type", "device class", or "device signature".

**Code comment example:**
```c
// Device Identity must match Apple-compatible interface
```

**Scope:** The complete presentation of device including compatible string, registers, and properties.

**Not:** Not internal implementation, not transport mechanism, not device name alone.

### Transport Layer

**Definition:** Internal emulator mechanisms for device functionality implementation.

**Usage:** Always "Transport Layer", never "backend", "implementation layer", or "device driver".

**Code comment example:**
```c
// Transport Layer handles host file access for storage device
```

**Scope:** All internal implementation details hidden from macOS view.

**Not:** Not visible to guest, not part of device identity, not Apple-specific.

### MMIO (Memory-Mapped I/O)

**Definition:** Device registers accessible through physical memory addresses.

**Usage:** Always "MMIO", never "memory-mapped registers", "device memory", or "register space".

**Code comment example:**
```c
// Device registers appear in MMIO region of Memory Map
```

**Scope:** The address ranges where device register access occurs.

**Not:** Not DMA (that is device-initiated), not port I/O (ARM uses MMIO), not configuration space.

## Process Terms

### Bring-up

**Definition:** The process of achieving functional macOS boot from emulator start to userspace.

**Usage:** Always "Bring-up", never "boot", "initialization", or "startup".

**Code comment example:**
```c
// Bring-up phase focuses on kernel entry without panic
```

**Scope:** The development phase where basic boot chain execution is established.

**Not:** Not production operation, not optimization phase, not complete system functionality.

### Headless Boot

**Definition:** macOS boot without display or GUI support.

**Usage:** Always "Headless Boot", never "console boot", "no-display boot", or "text mode".

**Code comment example:**
```c
// Headless Boot achieved through serial console output
```

**Scope:** Boot progression to kernel and userspace without graphics initialization.

**Not:** Not a boot mode flag, not a macOS configuration, not permanent limitation.

### Platform Assumption

**Definition:** An expectation macOS has about the underlying hardware or platform state.

**Usage:** Always "Platform Assumption", never "hardware assumption", "system requirement", or "precondition".

**Code comment example:**
```c
// Platform Assumption about secure boot state satisfied by synthesis
```

**Scope:** Any expectation that must be fulfilled for macOS to execute correctly.

**Not:** Not a software requirement (macOS version), not optional, not user-configurable.

## Prohibited Terms

The following terms are ambiguous or overloaded and must NOT be used:

- **"Virtual Machine"** - Use "emulator" or specific component name
- **"Board"** - Use "Machine Model"
- **"Firmware"** - Use "Platform Boot Layer" or specific boot component
- **"Bypass"** when describing security - Use "Trust Synthesis" or "adaptation"
- **"Patch"** when describing kernel accommodation - Use "Kernel Accommodation"
- **"ARMv8"** alone - Use "arm64e" or "Apple Silicon"
- **"Generic ARM"** - Use "standard ARM" if comparison needed
- **"Hypervisor"** - System runs at EL1/EL0, not virtualizing
- **"vCPU"** - Use "CPU Model"
- **"Guest"** - Use "macOS" or "kernel"
- **"Host"** - Use "emulator" or "host system" only when necessary

## Usage Consistency Rules

1. **Capitalization**: Follow the exact capitalization shown in definitions.
2. **Abbreviations**: Only use defined abbreviations (PAC, MMIO, EL).
3. **Pluralization**: Add 's' for plurals (e.g., "Platform Assumptions"), do not modify the base term.
4. **Hyphenation**: Maintain hyphenation as defined (e.g., "Version-Agnostic", not "Version Agnostic").
5. **Code comments**: Use exact terminology with no synonyms.
6. **Documentation**: Link to this document when introducing terms.

## Term Relationships

### Hierarchical Relationships

```
Apple-on-Virt Emulator
├── Platform Boot Layer
│   ├── Memory Map
│   ├── Device Tree
│   ├── Secure Boot Context
│   └── Platform Identity
├── Machine Model
│   └── Coordinates initialization
├── CPU Model
│   ├── arm64e execution
│   ├── PAC semantics
│   └── Exception Level management
└── Device Layer
    └── Device Identity per device
```

### Process Relationships

```
Bring-up Phase
├── Platform Boot Layer synthesis
├── Boot Chain execution
│   ├── iBoot
│   ├── boot.efi
│   └── kernelcache
├── Kernel Accommodation (if needed)
└── Headless Boot achievement
```

### Concept Relationships

```
Platform Fidelity
├── Enables Version-Agnostic design
├── Reduces Kernel Accommodation needs
└── Based on Platform Assumption fulfillment

Security Semantics
├── Preserved through implementation
├── Trust Synthesis establishes context
└── Secure Boot Context indicates state
```

## Terminology Verification

When writing documentation or code:

1. Search this document for the concept you want to express.
2. Use the exact term defined here.
3. If the concept is not defined, propose a new term following existing patterns.
4. Never use prohibited terms or synonyms.
5. Maintain consistency across all project artifacts.
