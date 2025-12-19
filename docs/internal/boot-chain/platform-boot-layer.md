# Platform Boot Layer Specification

This document formally defines the Platform Boot Layer, the mandatory component that enables version-agnostic macOS compatibility through platform reconstruction.

## Definition

The Platform Boot Layer is the synthetic environment that establishes Apple Silicon platform state before any macOS code executes. It is not optional. It is not a convenience feature. It is the foundational requirement that makes unmodified boot chain execution possible.

### What It Is

The Platform Boot Layer reconstructs the hardware context that Apple Silicon provides at power-on. When iBoot begins execution, it queries the platform to understand what hardware it is running on. The Platform Boot Layer ensures that every query returns "Apple Silicon" with complete consistency.

### What It Is Not

- **Not a bootloader**: Does not load operating system components. iBoot is the bootloader.
- **Not firmware**: Does not provide runtime services or callbacks. Completes before boot chain starts.
- **Not BIOS/UEFI**: Apple Silicon does not use these interfaces. No compatibility layer exists.
- **Not a compatibility shim**: Does not translate between interfaces. Presents native Apple Silicon state.

## Mandatory Nature

The Platform Boot Layer is mandatory because:

1. **Boot Chain Assumptions**: iBoot, boot.efi, and kernelcache make implicit assumptions about the platform they are running on. These assumptions cannot be satisfied by generic hardware emulation or standard firmware interfaces.

2. **Platform Identity**: macOS checks platform identity through multiple mechanisms: device tree properties, system registers, secure boot state, hardware ID registers. All must report consistent Apple Silicon identity.

3. **Security Context**: The boot chain expects specific secure boot state indicating trusted execution. This cannot be synthesized at runtime; it must exist before boot components execute.

4. **Version Agnosticism**: Different macOS versions make the same platform assumptions because they target the same hardware. Satisfying platform assumptions rather than version-specific requirements enables version-agnostic compatibility.

## Explicit Rejection of BIOS/UEFI

### Why BIOS/UEFI Do Not Apply

Apple Silicon does not use BIOS. It does not use UEFI. These are x86 legacy (BIOS) and industry-standard (UEFI) firmware interfaces designed for different boot models and different assumptions about hardware discovery.

**BIOS Incompatibility:**
- BIOS is x86-specific legacy firmware.
- Provides INT-based services and real-mode execution.
- Has no relevance to ARM64 or Apple Silicon.
- Apple Silicon has never used BIOS.

**UEFI Incompatibility:**
- UEFI provides boot services and runtime services through standardized protocols.
- Apple's boot.efi is EFI format but not UEFI-compliant.
- Apple Silicon does not provide EFI_BOOT_SERVICES.
- macOS does not call EFI protocols.
- Device discovery uses device tree, not EFI protocols.

**Architectural Mismatch:**
- UEFI assumes discoverable hardware through standard protocols.
- Apple Silicon uses fixed device tree with pre-defined topology.
- UEFI assumes ACPI for hardware description.
- Apple Silicon uses device tree exclusively.
- UEFI Secure Boot is cryptographically distinct from Apple Secure Boot.

### Attempts to Use UEFI Would Require

1. **Translation Layer**: Convert between UEFI protocols and Apple device tree format.
2. **ACPI Generation**: Create ACPI tables that Apple Silicon never provides.
3. **Protocol Emulation**: Implement EFI protocols that macOS never calls.
4. **Boot Services**: Provide services that exist only during UEFI boot, not Apple boot.
5. **Version-Specific Adaptation**: Handle differences in how macOS interacts with non-existent UEFI layer.

All of this adds complexity, introduces failure modes, and requires version-specific maintenance. The Platform Boot Layer avoids this by presenting native Apple Silicon state.

## Platform State Components

### Memory Map

**Apple Silicon Convention:**
```
Region              | Address Range          | Type
--------------------|------------------------|------------------
Exception Vectors   | 0x0000_0000_0000_0000  | Executable
Reserved            | 0x0000_0000_0000_0800  | Reserved
DRAM                | 0x0000_0008_0000_0000  | Normal Memory
MMIO                | 0x0000_0010_0000_0000  | Device Memory
Secure/Reserved     | 0x0000_0020_0000_0000  | Reserved
```

**Characteristics:**
- Fixed region boundaries following Apple Silicon layout.
- Region types (Normal, Device, Reserved) matching hardware.
- No PCI address space.
- No standard ARM peripheral addresses.
- Apple-specific MMIO region organization.

**Not:**
- Not dynamically configured based on available RAM.
- Not using standard ARM Versatile Express layout.
- Not following SBSA conventions.
- Not compatible with Linux memory expectations.

### Device Tree

**Apple Silicon Convention:**

The device tree uses Apple format, not standard device tree format or FDT (Flattened Device Tree) used by Linux.

**Required Root Nodes:**
```
/
├── cpus
│   └── cpu@0 (and additional CPUs)
├── memory
├── chosen
│   ├── boot-args
│   ├── random-seed
│   └── security properties
├── platform
│   ├── platform-id
│   ├── board-id
│   └── chip-id
└── devices
    ├── interrupt-controller (AIC)
    ├── timer
    ├── serial
    └── storage
```

**Key Properties:**
- `compatible` strings must match Apple driver expectations.
- Register addresses must match Apple Silicon MMIO layout.
- Interrupt routing uses Apple Interrupt Controller (AIC) format.
- Security properties indicate secure boot state.
- Platform identity must be consistent across all sources.

**Not:**
- Not Linux device tree with standard bindings.
- Not FDT format used by U-Boot or ARM platforms.
- Not ACPI (Apple Silicon does not use ACPI).
- Not dynamically generated based on detected hardware.

### Secure Boot Context

**State Registers:**

The Platform Boot Layer synthesizes secure boot state that indicates:
- Boot mode: Normal (not recovery, not DFU).
- Security level: Production (not development).
- Verification status: Passed (trusted boot path).
- Boot stage: Completed (ready for iBoot).

**Implementation:**

These states are not cryptographically verified. They are synthesized to represent the outcome of successful verification. The Platform Boot Layer sets registers and device tree properties that indicate "verification has passed and execution should proceed normally."

**Critical Distinction:**

This is **not** security bypass. Security features remain active. The synthesis represents the post-verification state, not the absence of verification. On genuine hardware, these states would be set after cryptographic checks. In the emulator, they are set to represent the expected post-check state.

### Platform Identity

**Required Identifiers:**

- **Platform ID**: Identifies the Apple Silicon platform type.
- **Board ID**: Identifies the board configuration.
- **Chip ID**: Identifies the SoC model.

**Consistency Requirement:**

These identifiers must be:
- Consistent across all query mechanisms (registers, device tree, MMIO).
- Persistent across boot stages (iBoot → boot.efi → kernel).
- Plausible as Apple Silicon identifiers.
- Not changing between macOS versions.

**Values:**

The specific values do not need to match real Apple hardware. They must be internally consistent and recognizable as Apple Silicon format. macOS checks for valid Apple ID format, not specific known hardware.

### CPU State

**Initial State Requirements:**

Before iBoot execution:
- Exception Level: EL2 or EL1 (depending on iBoot variant).
- Program Counter: Set to iBoot entry point.
- Stack Pointer: Valid stack in DRAM region.
- PAC Keys: Initialized with consistent values.
- System Registers: Apple Silicon feature flags set correctly.
- MMU: Initially disabled (iBoot enables).
- Interrupts: Masked (iBoot unmasks after setup).

**Feature Registers:**

CPU feature registers (ID_AA64PFR0_EL1, ID_AA64MMFR0_EL1, etc.) must report:
- arm64e support (not generic ARMv8).
- PAC support present.
- Exception level support (EL0, EL1, EL2).
- Memory model features matching Apple Silicon.

## Initialization Sequence

### Phase 1: Pre-Boot Synthesis

**Before any guest code executes:**

1. **Memory Map Construction**
   - Define DRAM region.
   - Define MMIO region.
   - Define reserved regions.
   - Validate no overlaps.

2. **Device Tree Generation**
   - Create root node with platform properties.
   - Add CPU nodes with correct topology.
   - Add memory node with size.
   - Add chosen node with boot arguments.
   - Add device nodes for all emulated devices.
   - Add platform identity nodes.
   - Add secure boot state properties.

3. **Platform Identity Initialization**
   - Set platform ID register/property.
   - Set board ID register/property.
   - Set chip ID register/property.
   - Verify consistency across all sources.

4. **Secure Boot Context Synthesis**
   - Set boot mode registers.
   - Set security level registers.
   - Set verification status flags.
   - Update device tree secure boot properties.

5. **CPU State Preparation**
   - Initialize PAC key registers.
   - Set feature registers.
   - Configure exception level state.
   - Prepare for iBoot entry.

### Phase 2: Boot Handoff

**Transfer control to iBoot:**

1. Load iBoot binary into DRAM at correct address.
2. Place device tree at expected address.
3. Set CPU PC to iBoot entry point.
4. Set CPU SP to valid stack.
5. Set CPU to appropriate exception level.
6. Begin execution.

**Critical:** After handoff, Platform Boot Layer is complete. It does not provide runtime services or callbacks. All state is static from this point.

### Phase 3: Boot Chain Execution

**Platform Boot Layer role ends:**

- iBoot executes using synthesized platform state.
- boot.efi inherits state from iBoot.
- kernelcache inherits state from boot.efi.
- Platform Boot Layer does not intervene after handoff.

## Version Agnosticism Through Platform Fidelity

### Why This Enables Multi-Version Compatibility

**Observation:** macOS versions target Apple Silicon platform, not each other.

- Monterey expects Apple Silicon platform.
- Ventura expects Apple Silicon platform.
- Sonoma expects Apple Silicon platform.
- Future versions expect Apple Silicon platform.

The platform assumptions are stable because:
1. Apple controls both hardware and software.
2. Backward compatibility is a design requirement.
3. Boot chain structure remains consistent.
4. Device tree format is stable across versions.

**Strategy:**

By reconstructing Apple Silicon platform accurately:
- All versions see the same platform.
- Platform meets all versions' assumptions.
- No version-specific code required.
- New versions work without emulator changes (assuming platform is sufficiently accurate).

**Contrast with Version-Specific Approach:**

```
// Version-specific (WRONG):
if (macos_version == MONTEREY) {
    set_monterey_platform_state();
} else if (macos_version == VENTURA) {
    set_ventura_platform_state();
}

// Platform fidelity (RIGHT):
set_apple_silicon_platform_state();
// Works for all versions because it's accurate to hardware
```

### When Platform Evolution Occurs

Occasionally, Apple Silicon platform evolves (new features, new registers, new device tree properties). When this happens:

1. Identify the new platform feature.
2. Implement the feature in Platform Boot Layer.
3. Verify all supported macOS versions still work.
4. Document the addition.

This is additive enhancement, not version-specific branching. The platform becomes more complete, benefiting all versions.

## Validation Criteria

### Platform Boot Layer Success

The Platform Boot Layer is successful when:

1. **iBoot Recognizes Platform**
   - iBoot parses device tree without errors.
   - iBoot identifies platform as Apple Silicon.
   - iBoot proceeds to hardware initialization.

2. **State Consistency Maintained**
   - Platform ID is consistent across all query methods.
   - Secure boot state is internally consistent.
   - Device tree matches register state.

3. **Boot Chain Proceeds**
   - iBoot completes and loads boot.efi.
   - boot.efi receives valid platform state.
   - kernelcache begins execution.

4. **Version Agnostic Operation**
   - Same Platform Boot Layer works for multiple macOS versions.
   - No version detection required.
   - No version-specific configuration.

### Failure Indicators

Platform Boot Layer has failed if:

1. iBoot does not recognize platform.
2. Device tree parsing errors occur.
3. Platform identity inconsistencies detected.
4. Secure boot state invalid or inconsistent.
5. Version-specific behavior required.

## Implementation Boundaries

### What Platform Boot Layer Implements

- Memory map definition.
- Device tree generation.
- Secure boot context synthesis.
- Platform identity initialization.
- CPU state preparation.
- iBoot binary loading.

### What Platform Boot Layer Does NOT Implement

- Boot component execution (iBoot does this).
- Runtime firmware services (none exist on Apple Silicon).
- Device functionality (Device Layer does this).
- Kernel accommodation (Kernel Interface does this, if needed).
- Dynamic platform adjustment (platform is fixed).

## Relationship to Other Components

### Platform Boot Layer → Machine Model

Machine Model invokes Platform Boot Layer during initialization. Machine Model owns the initialization sequence; Platform Boot Layer provides platform state synthesis.

### Platform Boot Layer → CPU Model

Platform Boot Layer prepares initial CPU state. CPU Model executes instructions based on that state. Platform Boot Layer does not execute instructions.

### Platform Boot Layer → Device Layer

Platform Boot Layer generates device tree nodes describing devices. Device Layer implements device functionality. Platform Boot Layer does not implement devices.

### Platform Boot Layer → Boot Chain

Platform Boot Layer provides environment for boot chain. Boot chain executes using that environment. Platform Boot Layer does not execute boot chain components.

## Summary

The Platform Boot Layer is the mandatory foundation that enables Apple-on-Virt's core architectural principle: platform reconstruction over generic emulation.

Without this layer:
- Generic ARM64 emulation would require extensive compatibility layers.
- UEFI/BIOS adaptation would introduce version-specific complexity.
- Boot chain modification would be necessary.
- Version-agnostic operation would be impossible.

With this layer:
- Platform state matches Apple Silicon from boot start.
- Boot chain executes unmodified.
- Version compatibility emerges from platform accuracy.
- Architecture remains clean and maintainable.

The Platform Boot Layer answers the fundamental question: "What platform is this?" The answer is always "Apple Silicon," in every detail that macOS can observe.
