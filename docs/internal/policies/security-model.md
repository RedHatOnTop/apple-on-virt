# Security Model Adaptation

This document explains how macOS security assumptions are adapted for platform emulation, framing adaptations as assumption fulfillment rather than security bypass.

## Security Model Overview

### macOS Security Architecture

macOS on Apple Silicon implements multiple security layers:

- **Secure Boot**: Ensures only Apple-signed code executes during boot.
- **AMFI (Apple Mobile File Integrity)**: Enforces code signing for executables.
- **SSV (Signed System Volume)**: Cryptographically seals the system volume.
- **PAC (Pointer Authentication)**: Protects return addresses and function pointers.
- **Kernel Integrity**: Various runtime protections for kernel code and data.

### Emulator Security Constraints

The emulator cannot provide:

- Hardware root of trust (fused keys, secure enclave).
- Physical tamper resistance.
- Hardware-backed cryptographic verification.
- Side-channel isolation guarantees.

### Adaptation Philosophy

Rather than disabling security features, the emulator adapts the environment so that security features function within emulation constraints. Security semantics are preserved even when hardware guarantees cannot be provided.

## Preserved Security Semantics

### What "Preserved" Means

Security semantics are preserved when:

- The security feature executes its intended code paths.
- Policy decisions are made by the security feature, not bypassed.
- The feature's observable behavior matches genuine hardware.
- Security state is consistent throughout execution.

### PAC Semantics

**Preservation:**

PAC instructions execute with functional semantics:

- Signing operations mark pointers as authenticated.
- Verification operations check authentication context.
- Mismatches generate faults or poisoned pointers.
- Kernel code flow protection operates normally.

**What this means:**

- Return address protection is semantically active.
- Function pointer authentication is semantically active.
- Control flow integrity is maintained within emulation.

**Limitation:**

Cryptographic verification is replaced with semantic verification. This provides functional correctness but not security against active attacks.

### Exception Level Separation

**Preservation:**

Exception level enforcement is maintained:

- EL0 cannot access EL1 resources.
- EL1 cannot access EL2 resources (when applicable).
- Privilege transitions require explicit exceptions.
- System register access respects EL requirements.

**What this means:**

- Kernel/user separation is enforced.
- Privileged operations require appropriate EL.
- Security boundaries between ELs are maintained.

### Memory Protection

**Preservation:**

Memory protection attributes are enforced:

- Page permissions (read, write, execute) are checked.
- Execute-never regions cannot be executed.
- Read-only regions cannot be written.
- Kernel memory is protected from user access.

**What this means:**

- Code injection is prevented by execute permissions.
- Data integrity is protected by write permissions.
- Kernel isolation from userspace is maintained.

### Code Signing Semantics

**Preservation:**

Code signing enforcement operates through AMFI:

- Signed code is allowed to execute.
- Unsigned code is blocked (if enforcement active).
- Signature validation uses platform security state.

**What this means:**

- AMFI makes policy decisions based on platform state.
- Code signing is not bypassed; it operates normally.
- Security state determines enforcement level.

## Adapted Assumptions

### What "Adapted" Means

Security assumptions are adapted when:

- The original assumption requires hardware that cannot be emulated.
- The emulator provides equivalent state through software synthesis.
- The security feature operates correctly with synthesized state.
- Security behavior matches what would occur on trusted hardware.

### Hardware Root of Trust

**Original Assumption:**

Apple Silicon has hardware-fused keys that establish trust root:

- Boot ROM verifies iBoot using hardware keys.
- Each stage verifies the next using certificate chain.
- Trust extends from hardware to software.

**Adaptation:**

The Platform Boot Layer synthesizes the trust state:

- Secure boot context indicates verification passed.
- Platform state reflects successful trust establishment.
- Boot components see the state they expect after verification.

**Result:**

Boot components execute their normal code paths because platform state indicates trust. No verification is skipped; verification succeeds because state says it should.

### Secure Enclave

**Original Assumption:**

Secure Enclave provides isolated execution environment:

- Cryptographic key storage.
- Biometric data processing.
- Secure credential management.

**Adaptation:**

Secure Enclave functionality is not emulated:

- Features requiring Secure Enclave are unavailable.
- Platform does not claim Secure Enclave presence.
- Applications detect absence and adjust accordingly.

**Result:**

No security bypass occurs. Secure Enclave features are absent, not disabled. Applications that require Secure Enclave will fail gracefully.

### Boot Verification Chain

**Original Assumption:**

Each boot stage cryptographically verifies the next:

- iBoot verifies boot.efi.
- boot.efi verifies kernelcache.
- Verification failure prevents boot.

**Adaptation:**

Platform state indicates verification has occurred:

- Secure boot registers reflect verified state.
- Boot components see successful verification status.
- Normal boot proceeds based on platform state.

**Result:**

Boot proceeds because platform state says verification passed. Boot components execute their standard code paths, not bypass paths.

### SSV (Signed System Volume)

**Original Assumption:**

System volume has cryptographic seal:

- Volume integrity verified at mount.
- Modifications detected and blocked.
- Seal rooted in hardware trust.

**Adaptation:**

SSV enforcement depends on platform security state:

- Platform state indicates boot environment.
- SSV makes enforcement decisions based on state.
- System volume can be prepared for expected state.

**Result:**

SSV operates according to platform state. The emulator does not disable SSV; SSV enforcement level matches platform security configuration.

### AMFI Enforcement

**Original Assumption:**

AMFI enforces code signing based on security state:

- Production devices require signed code.
- Development devices may allow unsigned code.
- Security state determines policy.

**Adaptation:**

AMFI queries platform security state:

- Secure boot context provides security level.
- AMFI enforces policy appropriate to that level.
- No AMFI bypass is implemented.

**Result:**

AMFI functions normally. Enforcement level matches the synthesized platform security state. Code signing is respected according to platform configuration.

## Explicit Non-Goals

### What Is Not Adapted

The following are not goals of security model adaptation:

**Security Research Bypass:**

The emulator is not designed to bypass security for research:

- Security features operate as designed.
- No "disable security" option exists.
- Research value comes from observing, not disabling.

**Piracy Enablement:**

The emulator does not enable software piracy:

- Code signing remains active.
- DRM mechanisms are not specifically bypassed.
- Commercial software protections function normally.

**Vulnerability Exploitation:**

The emulator does not facilitate vulnerability research against macOS:

- Security features are not weakened for analysis.
- Attack surface is not artificially expanded.
- Exploitation techniques are not specifically enabled.

**Hardware Security Equivalence:**

The emulator does not claim hardware-equivalent security:

- Cannot provide hardware root of trust.
- Cannot provide physical tamper resistance.
- Cannot provide side-channel isolation.

### Clear Boundaries

**What the emulator provides:**

- Platform state that security features expect.
- Functional execution of security code paths.
- Consistent security semantics within emulation constraints.

**What the emulator does not provide:**

- Hardware-backed security guarantees.
- Cryptographic verification of boot components.
- Protection against active attacks.
- Security certification or compliance.

## Security State Synthesis

### Secure Boot Context

The Platform Boot Layer synthesizes secure boot context:

```
Secure Boot State:
    - Boot mode: Normal (not recovery, not DFU)
    - Security level: Full Security
    - Verification status: Passed
    - Production status: Production device

Platform Identity:
    - Platform ID: Consistent synthetic value
    - Board ID: Consistent synthetic value  
    - Chip ID: Consistent synthetic value
    - Fused state: Production fused
```

### Security-Relevant Registers

System registers reflect synthesized security state:

```
Security Configuration:
    - Secure boot enabled: Yes
    - Boot chain verified: Yes
    - Production mode: Yes
    - Debug disabled: Yes (matches production)
```

### Device Tree Security Nodes

Device tree includes security-relevant information:

```
/chosen:
    - Security domain: Production
    - Boot mode: Normal
    - Verification chain: Complete

/secure-boot:
    - Status: Enabled
    - Level: Full
```

## Consistency Requirements

### Internal Consistency

All security state must be internally consistent:

- Secure boot context matches platform identity.
- CPU state matches security configuration.
- Device tree reflects same security level.
- No conflicting security indicators.

### Cross-Stage Consistency

Security state must remain consistent across boot stages:

- Platform Boot Layer establishes baseline.
- iBoot may query and trust that state.
- boot.efi inherits security context.
- Kernel sees consistent security environment.

### Version Consistency

Security state must work across macOS versions:

- Same synthesized state for all supported versions.
- No version-specific security configuration.
- Security semantics stable across releases.

## Documentation of Adaptations

### Adaptation Record

Each security adaptation should be documented:

**Adaptation Name:** [Name of adapted assumption]

**Original Assumption:** [What hardware provides]

**Emulator Adaptation:** [How emulator handles it]

**Security Semantic:** [What security behavior results]

**Limitation:** [What cannot be provided]

### Example Record

**Adaptation Name:** Boot Verification State

**Original Assumption:** Hardware verifies boot chain cryptographically and records result in secure registers.

**Emulator Adaptation:** Platform Boot Layer sets secure registers to indicate verification passed.

**Security Semantic:** Boot components see verified state and proceed normally. Security features enable based on this state.

**Limitation:** Actual cryptographic verification does not occur. Boot binaries must be trusted externally.

## Validation Criteria

### Security Feature Operation

Adaptation is successful when:

- Security features execute their code paths.
- Policy decisions occur within security code.
- No bypass or shortcut paths are taken.
- Observable behavior matches secure hardware.

### State Consistency

Adaptation is consistent when:

- All security state sources agree.
- No conflicting security indicators exist.
- State remains stable during boot.
- Security context propagates correctly.

### Semantic Preservation

Adaptation preserves semantics when:

- Security boundaries are maintained.
- Privilege levels are enforced.
- Memory protection is active.
- Code flow integrity operates.

## Summary

The emulator adapts macOS security assumptions by synthesizing the platform state that security features expect. This approach:

- Allows security features to function normally.
- Preserves security semantics within emulation.
- Does not bypass or disable security mechanisms.
- Acknowledges limitations of emulated environment.

Security features make their own decisions based on platform state. The emulator provides that state; the features enforce policy.
