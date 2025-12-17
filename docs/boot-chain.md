# Boot Chain Documentation

This document describes the complete boot flow from emulator start to macOS kernel entry, detailing what macOS expects at each stage and how the emulator satisfies those expectations.

## Boot Architecture Overview

### Apple Silicon Boot Model

Apple Silicon systems use a proprietary boot architecture that does not involve BIOS or UEFI. The boot flow proceeds through a chain of components, each validating and loading the next. On genuine hardware, this chain establishes trust through cryptographic verification rooted in hardware-fused keys.

### Emulator Boot Model

The emulator cannot provide hardware-rooted trust. Instead, the Platform Boot Layer synthesizes the platform state that would exist after successful trust establishment. This allows unmodified boot components to execute their native code paths without verification failures.

## Explicit Rejections

### No BIOS

BIOS is an x86 legacy firmware interface. It has no relevance to ARM64 systems and especially not to Apple Silicon. The emulator does not implement any BIOS functionality.

### No UEFI

UEFI (Unified Extensible Firmware Interface) is the industry standard for modern firmware. Apple Silicon does not use UEFI. The emulator does not implement:

- UEFI Boot Services
- UEFI Runtime Services
- UEFI variables or configuration tables
- UEFI Secure Boot (which differs from Apple's Secure Boot)
- Any EFI protocols or interfaces

Apple's boot.efi is an EFI application in format only; it runs on Apple's proprietary firmware environment, not a UEFI-compliant implementation.

## Boot Stages

### Stage 0: Platform Boot Layer Synthesis

**What happens:**

The emulator initializes and the Platform Boot Layer constructs the synthetic hardware environment.

**Timeline:**

```
Emulator Process Start
        |
        v
Machine Model Initialization
        |
        +---> Memory Map Construction
        |         - DRAM region definition
        |         - MMIO region definition
        |         - Reserved region definition
        |
        +---> Device Tree Generation
        |         - Platform identity nodes
        |         - CPU topology description
        |         - Memory node
        |         - Chosen node with boot arguments
        |
        +---> Secure Boot Context Synthesis
        |         - Boot stage flags: trusted
        |         - Security state: production
        |         - Verification status: passed
        |
        +---> CPU State Initialization
        |         - Exception level: EL2 or EL1
        |         - PAC keys: initialized
        |         - System registers: Apple-expected values
        |
        v
Platform Ready for Boot Handoff
```

**What macOS expects:**

At this point, macOS boot components expect to find:

- A coherent memory map with expected region types.
- A valid device tree at a known location describing the platform.
- CPU state indicating successful platform initialization.
- Secure boot context indicating trusted execution.

**How the emulator satisfies this:**

The Platform Boot Layer explicitly constructs each of these elements:

- Memory map follows Apple Silicon conventions for region layout.
- Device tree uses Apple's format with required properties.
- CPU registers are set to values the boot chain expects.
- Secure boot state registers indicate successful verification.

### Stage 1: iBoot Execution

**What happens:**

The first Apple boot component executes. iBoot is Apple's bootloader that initializes hardware and loads the next boot stage.

**Prerequisites from Platform Boot Layer:**

```
+------------------------------------------+
|            iBoot Requirements            |
+------------------------------------------+
| - Valid device tree at expected address  |
| - Memory map with accessible regions     |
| - CPU in expected exception level        |
| - Platform identity registers set        |
| - Secure boot context indicating trust   |
+------------------------------------------+
```

**iBoot execution flow:**

```
iBoot Entry
    |
    v
Platform Discovery
    |
    +---> Read device tree
    +---> Identify memory regions
    +---> Query platform identity
    |
    v
Hardware Initialization (stubbed in emulator)
    |
    +---> Display init (not required for headless)
    +---> Storage init (emulator provides interface)
    +---> Other peripherals
    |
    v
boot.efi Location
    |
    +---> Find boot volume
    +---> Locate boot.efi
    |
    v
boot.efi Loading
    |
    +---> Load into memory
    +---> Prepare handoff context
    |
    v
Transfer to boot.efi
```

**What macOS expects:**

- Device tree accessible and parseable.
- Platform identity consistent with Apple Silicon.
- Secure boot state allowing continued execution.
- Storage device accessible for boot.efi loading.

**How the emulator satisfies this:**

- Device tree placed at conventional address with correct format.
- Platform ID, board ID, chip ID set to consistent values.
- Secure boot context synthesized to indicate trusted state.
- Storage device emulated with Apple-compatible interface.

**Trust assumption:**

iBoot normally verifies boot.efi cryptographically. The emulator's synthesized secure boot context indicates that verification has already occurred (or is not required in this boot mode). iBoot proceeds without performing verification because the platform state indicates trust.

### Stage 2: boot.efi Execution

**What happens:**

boot.efi prepares the environment for kernel execution and loads the kernelcache.

**Prerequisites from iBoot:**

```
+------------------------------------------+
|          boot.efi Requirements           |
+------------------------------------------+
| - Updated device tree from iBoot         |
| - Memory regions for kernel loading      |
| - Boot arguments configured              |
| - Secure boot chain continuation         |
| - Storage access for kernelcache         |
+------------------------------------------+
```

**boot.efi execution flow:**

```
boot.efi Entry
    |
    v
Environment Setup
    |
    +---> Parse boot arguments
    +---> Configure memory for kernel
    +---> Set up kernel boot context
    |
    v
kernelcache Location
    |
    +---> Find kernelcache on boot volume
    +---> Determine kernel variant (if applicable)
    |
    v
kernelcache Loading
    |
    +---> Load kernelcache into memory
    +---> Decompress if necessary
    +---> Prepare kernel header information
    |
    v
Kernel Environment Preparation
    |
    +---> Set up memory map for kernel
    +---> Configure device tree for kernel
    +---> Prepare boot arguments structure
    |
    v
Transfer to Kernel
```

**What macOS expects:**

- Valid execution context from iBoot.
- Storage device accessible for kernelcache.
- Memory available for kernel image.
- Device tree continuity from previous stage.

**How the emulator satisfies this:**

- iBoot executes natively and passes valid context.
- Storage device remains accessible.
- Memory map provides adequate space.
- Device tree persists across stages.

**Trust assumption:**

boot.efi normally verifies the kernelcache. The trust context inherited from iBoot indicates that verification should succeed or is not required. boot.efi proceeds with kernel loading.

### Stage 3: Kernel Entry

**What happens:**

The macOS kernel begins execution and initializes the operating system.

**Prerequisites from boot.efi:**

```
+------------------------------------------+
|           Kernel Requirements            |
+------------------------------------------+
| - Valid arm64e execution environment     |
| - Device tree with platform description  |
| - Memory map with kernel expectations    |
| - Boot arguments structure               |
| - Secure boot context for AMFI/SSV       |
| - CPU state suitable for kernel init     |
+------------------------------------------+
```

**Kernel early initialization:**

```
Kernel Entry Point
    |
    v
Early Platform Setup
    |
    +---> Parse device tree
    +---> Identify CPU capabilities
    +---> Set up initial page tables
    +---> Configure exception vectors
    |
    v
Security Subsystem Init
    |
    +---> Query secure boot state
    +---> Initialize AMFI context
    +---> Set up SSV state
    |
    v
Memory Subsystem Init
    |
    +---> Parse memory map
    +---> Initialize zones
    +---> Set up kernel heap
    |
    v
Platform Subsystem Init
    |
    +---> Initialize timers
    +---> Set up interrupt controller
    +---> Register platform devices
    |
    v
Continue to Userspace
```

**What macOS expects:**

- arm64e CPU with PAC support and correct semantics.
- Device tree describing available hardware.
- Memory organized according to Apple conventions.
- Secure boot context indicating system integrity.
- Platform devices accessible at expected addresses.

**How the emulator satisfies this:**

- apple-arm64e CPU provides expected instruction semantics.
- Device tree generated with required platform nodes.
- Memory map follows Apple Silicon layout conventions.
- Secure boot context synthesized as trusted/production.
- Emulated devices respond at correct addresses.

**Trust assumption:**

The kernel queries secure boot state to determine whether to enforce AMFI (Apple Mobile File Integrity) and SSV (Signed System Volume). The emulator's secure boot context indicates that these should be active, preserving security semantics without requiring cryptographic proof.

## Trust Assumptions Summary

### Stage Transitions and Trust

```
+-------------+     Trust Context      +-------------+
|  Platform   | ------------------->   |   iBoot     |
|  Boot Layer |  "Platform is Apple    |             |
|             |   Silicon, secure      |             |
|             |   boot passed"         |             |
+-------------+                        +-------------+
                                             |
                                             | Trust Context
                                             | "iBoot verified,
                                             |  continue chain"
                                             v
                                       +-------------+
                                       |  boot.efi   |
                                       |             |
                                       +-------------+
                                             |
                                             | Trust Context
                                             | "Boot chain valid,
                                             |  kernel trusted"
                                             v
                                       +-------------+
                                       | kernelcache |
                                       |             |
                                       +-------------+
```

### What Trust Means at Each Stage

**Platform Boot Layer to iBoot:**

- Platform identity is genuine Apple Silicon (synthesized).
- Secure boot has completed successfully (synthesized).
- Previous boot stages verified current stage (synthesized).

**iBoot to boot.efi:**

- iBoot has verified boot.efi signature (assumed by trust context).
- Platform state is consistent with secure boot.
- Hardware initialization completed successfully.

**boot.efi to Kernel:**

- boot.efi has verified kernelcache (assumed by trust context).
- Boot environment is correctly configured.
- Security policies should be enforced.

### Trust Synthesis vs. Trust Bypass

The emulator does not bypass security checks. It synthesizes the state that would exist after successful security checks. This distinction is important:

**Bypass approach (not used):**

- Patch boot components to skip verification.
- Disable security checks in kernel.
- Modify binaries to remove trust requirements.

**Synthesis approach (used):**

- Set platform registers to indicate verified state.
- Configure secure boot context as production/trusted.
- Let boot components execute their normal code paths.
- Security features remain active based on platform state.

## Boot Arguments

### Boot Argument Flow

```
Platform Boot Layer
    |
    +---> Initial boot arguments in device tree /chosen
              |
              v
         iBoot
              |
              +---> May modify boot arguments
              |
              v
         boot.efi
              |
              +---> Final boot arguments to kernel
              |
              v
         Kernel parses boot arguments
```

### Essential Boot Arguments

The emulator configures boot arguments to support headless bring-up:

- Serial console configuration for debug output.
- Memory configuration parameters.
- Boot mode indicators.

### Boot Argument Consistency

Boot arguments must remain consistent across macOS versions. Version-specific boot arguments are avoided to maintain the version-agnostic design principle.

## Memory Layout at Each Stage

### Platform Boot Layer Memory Map

```
0x0000_0000_0000_0000 +---------------------------+
                      |                           |
                      |     Exception Vectors     |
                      |                           |
0x0000_0000_0000_0800 +---------------------------+
                      |                           |
                      |     Reserved/Unused       |
                      |                           |
0x0000_0008_0000_0000 +---------------------------+
                      |                           |
                      |     DRAM Region           |
                      |     (System Memory)       |
                      |                           |
                      |  - Device Tree            |
                      |  - iBoot Load Address     |
                      |  - Kernel Load Address    |
                      |                           |
0x0000_0010_0000_0000 +---------------------------+
                      |                           |
                      |     MMIO Region           |
                      |     (Device Registers)    |
                      |                           |
0x0000_0020_0000_0000 +---------------------------+
                      |                           |
                      |     Reserved              |
                      |                           |
                      +---------------------------+
```

### Memory Handoff

Each stage inherits and may extend the memory configuration:

- Platform Boot Layer defines initial layout.
- iBoot may allocate within available regions.
- boot.efi configures kernel memory requirements.
- Kernel takes ownership of memory management.

## Validation Points

### Stage 0 Validation

- Device tree is well-formed and contains required nodes.
- Memory map has no overlapping regions.
- CPU state registers have valid values.
- Secure boot context is internally consistent.

### Stage 1 Validation

- iBoot loads and begins execution.
- Device tree is successfully parsed.
- boot.efi is located and loaded.
- Control transfers to boot.efi.

### Stage 2 Validation

- boot.efi receives valid context.
- kernelcache is located and loaded.
- Kernel environment is prepared.
- Control transfers to kernel.

### Stage 3 Validation

- Kernel begins execution without immediate panic.
- Device tree parsing succeeds.
- Early initialization completes.
- System progresses toward userspace.

## Failure Modes

### Platform Boot Layer Failures

- Invalid device tree format: iBoot fails to parse platform.
- Incorrect memory map: Memory access faults during boot.
- Wrong secure boot state: Security checks fail unexpectedly.
- Bad CPU state: Exceptions during early iBoot execution.

### Boot Chain Failures

- Missing boot.efi: iBoot cannot proceed.
- Missing kernelcache: boot.efi cannot proceed.
- Incompatible kernel: Kernel fails early initialization.
- Device access failure: Boot component cannot access storage.

### Kernel Failures

- Device tree mismatch: Kernel cannot identify platform.
- Missing devices: Required hardware not found.
- Security state mismatch: AMFI/SSV enforcement issues.
- Memory configuration error: Kernel memory init fails.
